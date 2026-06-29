#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${SCHEME:-LeVestiaire}"
PROJECT="${PROJECT:-LeVestiaire.xcodeproj}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
RUN_UNIT_TESTS="${RUN_UNIT_TESTS:-1}"
RUN_UI_TESTS="${RUN_UI_TESTS:-1}"

if [[ "${RUN_UNIT_TESTS}" != "1" && "${RUN_UI_TESTS}" != "1" ]]; then
  echo "ERROR: Activez au moins RUN_UNIT_TESTS=1 ou RUN_UI_TESTS=1."
  exit 1
fi

echo "==> Test iOS (${CONFIGURATION})"
echo "    Scheme: ${SCHEME}"
echo "    Destination: ${DESTINATION}"
echo "    Unit tests: ${RUN_UNIT_TESTS}"
echo "    UI tests: ${RUN_UI_TESTS}"

XCBUILD_ARGS=(
  test
  -project "${PROJECT}"
  -scheme "${SCHEME}"
  -configuration "${CONFIGURATION}"
  -destination "${DESTINATION}"
)

if [[ "${RUN_UNIT_TESTS}" == "1" ]]; then
  XCBUILD_ARGS+=(-only-testing:LeVestiaireTests)
fi

if [[ "${RUN_UI_TESTS}" == "1" ]]; then
  XCBUILD_ARGS+=(-only-testing:LeVestiaireUITests)
fi

XCBUILD_ARGS+=(CODE_SIGNING_ALLOWED=NO)

xcodebuild "${XCBUILD_ARGS[@]}"
