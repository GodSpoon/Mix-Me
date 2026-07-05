#!/usr/bin/env bash
# Mix-Me installer: sets up submodules, installs Hermes tooling, and copies example config.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Initializing submodules"
git submodule update --init --recursive

echo "==> Installing Hermes tooling"
cd "$REPO_ROOT/hermes"
if [ -d ".venv" ]; then
  VENV_PYTHON=".venv/bin/python"
else
  VENV_PYTHON="python3"
fi
"$VENV_PYTHON" -m pip install -e .

cd "$REPO_ROOT"

if [ ! -f "hermes.yaml" ]; then
  echo "==> Copying example config to hermes.yaml"
  cp config/hermes.yaml.example hermes.yaml
  echo "    Edit hermes.yaml with your own paths before running Mix-Me."
fi

echo "==> Mix-Me setup complete"
echo "    - Hermes tooling installed from hermes/"
echo "    - Config template copied to hermes.yaml"
echo "    - Install the skill with: hermes skills install $REPO_ROOT/skills/mix-me"
