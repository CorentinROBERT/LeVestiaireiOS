#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${SCHEME:-LeVestiaire}"
PROJECT="${PROJECT:-LeVestiaire.xcodeproj}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"

echo "==> Build iOS (${CONFIGURATION})"
echo "    Scheme: ${SCHEME}"
echo "    Destination: ${DESTINATION}"

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "${DESTINATION}" \
  CODE_SIGNING_ALLOWED=NO \
  build
