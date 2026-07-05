#!/usr/bin/env bash
# Mix-Me installer: sets up submodules, installs Hermes tooling, and copies example config.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Initializing submodules"
git submodule update --init --recursive

VENV_DIR="$REPO_ROOT/.venv"
if [ ! -d "$VENV_DIR" ]; then
  echo "==> Creating Python virtual environment"
  # Prefer Python 3.13: hermes depends on libsql_experimental, whose wheel is
  # known to segfault on the Python 3.14 pre-release used by some Homebrew
  # `python3` defaults. Fall back to `python3` if 3.13 is unavailable.
  if command -v python3.13 >/dev/null 2>&1; then
    python3.13 -m venv "$VENV_DIR"
  else
    python3 -m venv "$VENV_DIR"
  fi
fi
VENV_PYTHON="$VENV_DIR/bin/python"

# Ensure the venv has an up-to-date pip to avoid externally-managed-environment
# errors and stale build backends on older pip versions.
echo "==> Upgrading pip in the virtual environment"
"$VENV_PYTHON" -m pip install --upgrade pip

echo "==> Installing Hermes tooling"
"$VENV_PYTHON" -m pip install -e "$REPO_ROOT/hermes"

# Expose the Mix-Me wrapper as a plain `mixme` command inside the venv.
MIXME_WRAPPER="$REPO_ROOT/skills/mix-me/scripts/mixme_client.py"
MIXME_BIN="$VENV_DIR/bin/mixme"
if [ -f "$MIXME_WRAPPER" ]; then
  echo "==> Installing mixme wrapper into the venv"
  rm -f "$MIXME_BIN"
  cat > "$MIXME_BIN" <<EOF
#!/bin/sh
exec "$VENV_PYTHON" "$MIXME_WRAPPER" "\$@"
EOF
  chmod +x "$MIXME_BIN" "$MIXME_WRAPPER"
fi

cd "$REPO_ROOT"

if [ ! -f "hermes.yaml" ]; then
  echo "==> Copying example config to hermes.yaml"
  cp config/hermes.yaml.example hermes.yaml
  echo "    Edit hermes.yaml with your own paths before running Mix-Me."
fi

echo "==> Mix-Me setup complete"
echo "    - Virtual environment: $VENV_DIR"
echo "    - Hermes tooling installed from hermes/"
echo "    - Config template copied to hermes.yaml (if missing)"
echo "    - Activate the environment with: source $VENV_DIR/bin/activate"
echo "    - Add the skill to Hermes Agent:"
echo "        hermes config set skills.external_dirs \"$REPO_ROOT/skills\""
echo "    - Or use the wrapper directly: $VENV_DIR/bin/mixme --help"
