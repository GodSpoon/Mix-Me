#!/usr/bin/env python3
"""Thin wrapper that invokes the Hermes CLI from the Mix-Me skill context.

This script finds the Hermes submodule and dispatches commands to it, so the
skill never has to hard-code an absolute path.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def _hermes_root() -> Path:
    """Return the path to the hermes submodule root."""
    # When installed via `hermes skills install`, the skill lives under
    # ~/.hermes/skills/mix-me/ and the repo root is three levels up.
    skill_scripts = Path(__file__).resolve().parent
    skill_dir = skill_scripts.parent
    repo_root = skill_dir.parent.parent
    hermes_root = repo_root / "hermes"
    if hermes_root.exists():
        return hermes_root
    # Fallback: assume current working directory is the Mix-Me repo root.
    cwd = Path.cwd()
    if (cwd / "hermes").exists():
        return cwd / "hermes"
    raise FileNotFoundError(
        "Could not find the hermes submodule. "
        "Make sure Mix-Me was cloned recursively (git submodule update --init)."
    )


def main() -> int:
    hermes_root = _hermes_root()
    env = os.environ.copy()
    env["PYTHONPATH"] = str(hermes_root) + (f":{env['PYTHONPATH']}" if env.get("PYTHONPATH") else "")

    # Map `mixme <command>` to `python -m hermes.cli <command>`.
    argv = [sys.executable, "-m", "hermes.cli"] + sys.argv[1:]
    return subprocess.call(argv, cwd=hermes_root.parent, env=env)


if __name__ == "__main__":
    sys.exit(main())
