"""Create a draft package, validate content, register a completed species or open its gallery."""
import argparse
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def identifier(value):
    if not re.fullmatch(r'[a-z][a-z0-9_]*', value):
        raise argparse.ArgumentTypeError('Use a stable lowercase ID: letters, digits and underscores.')
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    new = commands.add_parser('new', help='Create an unregistered draft; never overwrites files or invents artwork.')
    new.add_argument('species_id', type=identifier)
    new.add_argument('--forms', nargs='+', required=True, type=identifier)
    new.add_argument('--name', default='Novo Umbral')
    commands.add_parser('validate', help='Validate registered packages and report drafts.')
    register = commands.add_parser('register', help='Validate a finished package and append it without reordering the catalog.')
    register.add_argument('species_id', type=identifier)
    commands.add_parser('gallery', help='Open the interactive form/direction/action preview in native Godot.')
    args = parser.parse_args()
    command = ['godot', '--path', str(ROOT)]
    if args.command == 'gallery':
        command += ['res://scenes/creature_gallery.tscn']
    else:
        command += ['--headless', '--script', 'res://tools/content_checks.gd' if args.command == 'validate' else 'res://tools/author_umbral.gd']
        if args.command in ('new', 'register'):
            command += ['--', '--operation', args.command, '--id', args.species_id]
        if args.command == 'new':
            if len(set(args.forms)) != len(args.forms): parser.error('Form IDs must be unique.')
            command += ['--forms', ','.join(args.forms), '--name', args.name]
    return subprocess.run(['bash', '-c', 'set -euo pipefail; source tools/environment.sh; exec "$@"', 'umbrals', *command], cwd=ROOT).returncode


if __name__ == '__main__':
    raise SystemExit(main())
