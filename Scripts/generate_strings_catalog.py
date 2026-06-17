#!/usr/bin/env python3
"""Generate Localizable.xcstrings from Flutter-style ARB JSON files."""
""" python3 Scripts/generate_strings_catalog.py """

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

PLACEHOLDER_PATTERN = re.compile(r"\{[^}]+\}")


def convert_placeholders(value: str) -> str:
    return PLACEHOLDER_PATTERN.sub("%@", value)


def load_arb(path: Path) -> dict[str, str]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    return {key: value for key, value in data.items() if isinstance(value, str)}


def build_catalog(en: dict[str, str], fr: dict[str, str]) -> dict:
    keys = sorted(set(en) | set(fr))
    strings: dict[str, dict] = {}

    for key in keys:
        localizations: dict[str, dict] = {}

        if key in en:
            localizations["en"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": convert_placeholders(en[key]),
                }
            }

        if key in fr:
            localizations["fr"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": convert_placeholders(fr[key]),
                }
            }

        strings[key] = {"localizations": localizations}

    return {
        "sourceLanguage": "en",
        "strings": strings,
        "version": "1.0",
    }


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    en_path = root / "LeVestiaire/Resources/Localization/en.arb.json"
    fr_path = root / "LeVestiaire/Resources/Localization/fr.arb.json"
    out_path = root / "LeVestiaire/Resources/Localizable.xcstrings"

    if not en_path.exists() or not fr_path.exists():
        print("Missing ARB files:", en_path, fr_path, file=sys.stderr)
        return 1

    catalog = build_catalog(load_arb(en_path), load_arb(fr_path))
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with out_path.open("w", encoding="utf-8") as handle:
        json.dump(catalog, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    print(f"Generated {out_path} with {len(catalog['strings'])} keys")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
