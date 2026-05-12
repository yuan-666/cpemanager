import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

from cpemanager.cli import main


if __name__ == "__main__":
    args = sys.argv[1:]
    action_flags = {"--net-mode", "--net-option", "--auto-mode"}
    if "-h" not in args and "--help" not in args and not any(flag in args for flag in action_flags):
        args = [*args, "--auto-mode"]
    raise SystemExit(main(["netmode", *args]))
