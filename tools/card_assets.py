"""Validate/report the real card-art demand; production never accepts placeholders."""
import argparse
import json

from asset_pipeline import ROOT, AssetError, load_releases, read_json, write_json
from card_asset_pipeline import BINDING, snapshot, validate_presentation
from harness_io import results_dir


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['validate', 'matrix'], nargs='?', default='validate')
    parser.add_argument('--release', help='Exact unpublished candidate; otherwise validate the runtime pin or development draft')
    parser.add_argument('--mode', choices=['development', 'production'], default='development')
    parser.add_argument('--output')
    args = parser.parse_args()
    try:
        demand = snapshot()
        if args.command == 'matrix':
            report = demand
        else:
            pin = read_json(ROOT / 'assets/runtime-lock.json')['bindings'].get(BINDING)
            release = tuple(args.release.split('@')) if args.release else (pin['id'], pin['version']) if pin else (BINDING, '0.1.0')
            mode = 'production' if pin and not args.release else args.mode
            report = validate_presentation(ROOT, release, demand, mode)
            report.update({'suite': 'card_assets', 'checks': len(demand['entries']), 'runtime_enabled': bool(pin)})
        path = results_dir() / (args.output or 'card-asset-report.json')
        write_json(path, report)
        print(json.dumps(report if args.command == 'matrix' else {key: report[key] for key in ['suite', 'checks', 'failed', 'required', 'covered', 'approved', 'runtime_enabled']}))
        return 1 if report.get('failed', 0) else 0
    except (AssetError, ValueError) as error:
        print('Card asset validation failed: ' + str(error))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
