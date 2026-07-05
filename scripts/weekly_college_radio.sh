#!/usr/bin/env bash
# Weekly College Radio Recommends refresh for Mix-Me.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VENV_PYTHON="$REPO_ROOT/.venv/bin/python"
if [ ! -x "$VENV_PYTHON" ]; then
  VENV_PYTHON="python3"
fi

DATE="$(date +%F)"
CACHE_DIR="hermes-cache"
CACHE_FILE="$CACHE_DIR/radio-$DATE.json"
DRAFT_FILE="$CACHE_DIR/college-radio-draft-$DATE.json"
PLAYLIST_NAME="College Radio Recommends"

echo "==> Refreshing radio cache ($DATE)"
"$VENV_PYTHON" hermes/scripts/refresh_radio_cache.py --config "$REPO_ROOT/hermes.yaml" --output "$CACHE_FILE"

echo "==> Generating draft"
"$VENV_PYTHON" -m hermes.cli --config "$REPO_ROOT/hermes.yaml" run college-radio --radio-cache "$CACHE_FILE" --output "$DRAFT_FILE"

echo "==> Finalizing (download + M3U8)"
"$VENV_PYTHON" -m hermes.cli --config "$REPO_ROOT/hermes.yaml" finalize --draft "$DRAFT_FILE"

echo "==> Weekly refresh complete: $PLAYLIST_NAME"
