"""Compatibility entry over the current registry; isolated results live in the run directory."""
import sys
from harness import main
from harness_lib.registry import TITLE
if __name__ == '__main__': raise SystemExit(main(['check', '--suite', ','.join(TITLE), *sys.argv[1:]]))
