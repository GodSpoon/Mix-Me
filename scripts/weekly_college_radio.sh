#!/usr/bin/env bash
# Weekly College Radio Recommends refresh for Mix-Me.
# Run from the Mix-Me repo root.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PYTHON="./hermes/.venv/bin/python"
if [ ! -x "$PYTHON" ]; then
  PYTHON="python3"
fi

DATE="$(date +%F)"
CACHE_DIR="hermes-cache"
CACHE_FILE="$CACHE_DIR/radio-$DATE.json"
DRAFT_FILE="$CACHE_DIR/college-radio-draft-$DATE.json"
PLAYLIST_NAME="College Radio Recommends"

echo "==> Refreshing radio cache ($DATE)"
"$PYTHON" hermes/scripts/refresh_radio_cache.py --output "$CACHE_FILE"

echo "==> Generating draft"
"$PYTHON" -m hermes.cli run college-radio --radio-cache "$CACHE_FILE" --output "$DRAFT_FILE"

echo "==> Finalizing (download + M3U8)"
"$PYTHON" -m hermes.cli finalize --draft "$DRAFT_FILE"

echo "==> Weekly refresh complete: $PLAYLIST_NAME"
