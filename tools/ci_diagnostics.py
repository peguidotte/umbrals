"""Extract bounded machine-readable failure diagnostics without copying build or media data."""
import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, default=Path('test-results/ci-run.json'))
    parser.add_argument('--output', type=Path, default=Path('test-results/ci-diagnostics.json'))
    args = parser.parse_args()
    try:
        report_path = args.report
        if not report_path.is_file():
            latest = json.loads(Path('test-results/harness/latest-run.json').read_text())
            report_path = Path(latest['report'])
        report = json.loads(report_path.read_text())
        keys = ('status', 'scope', 'source_hash', 'final_source_hash', 'source_unchanged', 'coverage', 'failure', 'tools', 'directory')
        result = {key: report[key] for key in keys if key in report}
        fields = ('status', 'error', 'seconds', 'process_seconds', 'lock_wait_seconds', 'fingerprint', 'source_hash', 'origin', 'origin_source_hash', 'command', 'log_excerpt')
        result['tasks'] = {name: {key: task[key] for key in fields if key in task} for name, task in report.get('tasks', {}).items()}
    except (OSError, ValueError, KeyError) as error:
        result = {'status': 'unavailable', 'failure': str(error)}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False))
    print(f'Diagnostics: {args.output}')


if __name__ == '__main__':
    main()
