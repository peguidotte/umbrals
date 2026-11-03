"""Compatibility entry: UI/domain suites are selected from the one task registry."""
import sys
from harness import main
from harness_lib.registry import NATIVE

if __name__ == '__main__':
    arguments = sys.argv[1:]
    if '--suite' not in arguments:
        arguments = ['--suite', ','.join(name for name in NATIVE if name != 'rules'), *arguments]
    raise SystemExit(main(['check', *arguments]))
