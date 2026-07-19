#!/usr/bin/env bash
# Zip Mosyle Free Unlock for handout (folder load-unpacked ready).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$ROOT/dist/MosyleFreeUnlock-0.2.0.zip}"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
# Zip contents of this folder (not the parent path), exclude dist + junk
(
  cd "$ROOT"
  zip -r "$OUT" . \
    -x './dist/*' \
    -x '*.DS_Store' \
    -x './.git/*' \
    -x './package-for-techs.sh'
)
echo "Wrote $OUT"
echo "Techs: unzip → chrome://extensions → Load unpacked → that folder"
echo "Handout: README.md inside the zip"
