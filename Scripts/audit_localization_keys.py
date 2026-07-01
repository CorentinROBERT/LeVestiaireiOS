#!/usr/bin/env python3
"""Audit (and optionally prune) unused localization keys in ARB files.

Scans Swift sources for static L10n / String(localized:) references and compares
them with keys declared in en.arb.json and fr.arb.json.

Usage:
  python3 Scripts/audit_localization_keys.py
  python3 Scripts/audit_localization_keys.py --output Scripts/localization-unused-keys.txt
  python3 Scripts/audit_localization_keys.py --prune --regenerate-catalog

By default, keys starting with ``error`` or ``success`` are kept because many
API error messages are resolved dynamically via APIErrorLocalizer.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path

TEXT_OR_FORMAT_PATTERN = re.compile(
    r"(?:L10n\.)?(?:text|format)\(\s*\"([^\"]+)\""
)
STRING_LOCALIZED_PATTERN = re.compile(
    r"String\(\s*localized:\s*\"([^\"]+)\""
)
LOCALIZED_CALL_PATTERN = re.compile(
    r"localized\(\s*\"([^\"]+)\""
)

DEFAULT_KEEP_PREFIXES = ("error", "success")
SWIFT_SCAN_DIRS = ("LeVestiaire", "LeVestiaireTests", "LeVestiaireUITests")


def normalize_api_key(api_key: str) -> str:
    return api_key.replace(".", "").replace("_", "").lower()


def load_arb_ordered(path: Path) -> OrderedDict[str, str]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle, object_pairs_hook=OrderedDict)
    return OrderedDict(
        (key, value) for key, value in data.items() if isinstance(value, str)
    )


def write_arb(path: Path, entries: OrderedDict[str, str]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        json.dump(entries, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def collect_referenced_keys(root: Path, include_tests: bool) -> set[str]:
    referenced: set[str] = set()
    scan_dirs = SWIFT_SCAN_DIRS if include_tests else ("LeVestiaire",)

    for directory in scan_dirs:
        base = root / directory
        if not base.exists():
            continue
        for path in base.rglob("*.swift"):
            content = path.read_text(encoding="utf-8")
            for pattern in (TEXT_OR_FORMAT_PATTERN, STRING_LOCALIZED_PATTERN):
                for match in pattern.finditer(content):
                    referenced.add(match.group(1))

            for match in LOCALIZED_CALL_PATTERN.finditer(content):
                raw = match.group(1)
                referenced.add(raw)
                if raw.startswith("error.") or raw.startswith("success."):
                    referenced.add(normalize_api_key(raw))

    return referenced


def should_keep(key: str, referenced: set[str], keep_prefixes: tuple[str, ...]) -> bool:
    if key in referenced:
        return True
    return any(key.startswith(prefix) for prefix in keep_prefixes)


def audit_keys(
    en: OrderedDict[str, str],
    fr: OrderedDict[str, str],
    referenced: set[str],
    keep_prefixes: tuple[str, ...],
) -> tuple[list[str], list[str], list[str]]:
    all_keys = list(en.keys())
    unused: list[str] = []
    kept_by_prefix: list[str] = []
    missing_in_arb: list[str] = sorted(
        key for key in referenced if key not in en and key not in fr
    )

    for key in all_keys:
        if key in referenced:
            continue
        if any(key.startswith(prefix) for prefix in keep_prefixes):
            kept_by_prefix.append(key)
            continue
        unused.append(key)

    return unused, kept_by_prefix, missing_in_arb


def prune_arb(
    entries: OrderedDict[str, str],
    referenced: set[str],
    keep_prefixes: tuple[str, ...],
) -> tuple[OrderedDict[str, str], int]:
    kept = OrderedDict(
        (key, value)
        for key, value in entries.items()
        if should_keep(key, referenced, keep_prefixes)
    )
    removed = len(entries) - len(kept)
    return kept, removed


def regenerate_catalog(root: Path) -> int:
    script = root / "Scripts/generate_strings_catalog.py"
    result = subprocess.run(
        [sys.executable, str(script)],
        cwd=root,
        check=False,
    )
    return result.returncode


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        help="Write the list of unused keys to this file (one key per line).",
    )
    parser.add_argument(
        "--prune",
        action="store_true",
        help="Remove unused keys from en.arb.json and fr.arb.json.",
    )
    parser.add_argument(
        "--regenerate-catalog",
        action="store_true",
        help="Run Scripts/generate_strings_catalog.py after pruning.",
    )
    parser.add_argument(
        "--keep-prefix",
        action="append",
        default=list(DEFAULT_KEEP_PREFIXES),
        metavar="PREFIX",
        help=(
            "Keep unreferenced keys that start with this prefix "
            f"(default: {', '.join(DEFAULT_KEEP_PREFIXES)})."
        ),
    )
    parser.add_argument(
        "--include-tests",
        action="store_true",
        help="Also scan LeVestiaireTests and LeVestiaireUITests.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[1]
    en_path = root / "LeVestiaire/Resources/Localization/en.arb.json"
    fr_path = root / "LeVestiaire/Resources/Localization/fr.arb.json"
    keep_prefixes = tuple(args.keep_prefix)

    if not en_path.exists() or not fr_path.exists():
        print("Missing ARB files:", en_path, fr_path, file=sys.stderr)
        return 1

    en = load_arb_ordered(en_path)
    fr = load_arb_ordered(fr_path)
    referenced = collect_referenced_keys(root, include_tests=args.include_tests)
    unused, kept_by_prefix, missing_in_arb = audit_keys(en, fr, referenced, keep_prefixes)

    print(f"ARB keys (en): {len(en)}")
    print(f"Referenced in Swift: {len(referenced)}")
    print(f"Matched in ARB: {len(referenced & set(en))}")
    print(f"Unused (prune candidates): {len(unused)}")
    print(
        "Kept despite no static reference "
        f"(prefix {', '.join(keep_prefixes)}): {len(kept_by_prefix)}"
    )
    if missing_in_arb:
        print(f"Referenced in Swift but missing from ARB: {len(missing_in_arb)}")

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text("\n".join(unused) + ("\n" if unused else ""), encoding="utf-8")
        print(f"Wrote unused key list to {args.output}")

    if not args.prune:
        if unused:
            print("\nFirst 20 unused keys:")
            for key in unused[:20]:
                print(f"  - {key}")
            print("\nRun with --prune to remove them from the ARB files.")
        return 0

    pruned_en, removed_en = prune_arb(en, referenced, keep_prefixes)
    pruned_fr, removed_fr = prune_arb(fr, referenced, keep_prefixes)
    write_arb(en_path, pruned_en)
    write_arb(fr_path, pruned_fr)

    print(f"\nPruned {removed_en} keys from en.arb.json")
    print(f"Pruned {removed_fr} keys from fr.arb.json")

    if args.regenerate_catalog:
        code = regenerate_catalog(root)
        if code != 0:
            print("Failed to regenerate Localizable.xcstrings", file=sys.stderr)
            return code

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
