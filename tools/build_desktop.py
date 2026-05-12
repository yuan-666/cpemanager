"""Build a desktop executable with PyInstaller."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description="Build CPE Manager desktop app")
    parser.add_argument("--name", default="CPEManager", help="Application name")
    parser.add_argument("--onedir", action="store_true", help="Build an onedir app instead of onefile")
    args = parser.parse_args()

    config_dir = ROOT / ".pyinstaller"
    work_dir = ROOT / "build" / "pyinstaller"
    spec_dir = ROOT / "build" / "pyinstaller-spec"
    dist_dir = ROOT / "dist" / "desktop"
    for directory in (config_dir, work_dir, spec_dir, dist_dir):
        directory.mkdir(parents=True, exist_ok=True)

    command = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--name",
        args.name,
        "--windowed",
        "--noconfirm",
        "--clean",
        "--workpath",
        str(work_dir),
        "--specpath",
        str(spec_dir),
        "--distpath",
        str(dist_dir),
    ]
    if not args.onedir:
        command.append("--onefile")
    command.append(str(ROOT / "packaging" / "desktop_entry.py"))
    env = os.environ.copy()
    env["PYINSTALLER_CONFIG_DIR"] = str(config_dir)
    return subprocess.call(command, cwd=ROOT, env=env)


if __name__ == "__main__":
    raise SystemExit(main())
