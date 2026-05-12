import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

from cpemanager.cli import main


if __name__ == "__main__":
    raise SystemExit(main(["lock", *sys.argv[1:]]))
