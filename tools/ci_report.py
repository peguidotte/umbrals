"""Publish executed checks and actionable failures to the GitHub job summary."""
import argparse
import json
import os
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--status', choices=['success', 'failure', 'cancelled'], default='success')
    parser.add_argument('--build-manifest', type=Path, default=Path('builds/manifest.json'))
    args = parser.parse_args()
    report, failure = {}, None
    try:
        report = json.loads(args.report.read_text())
    except (OSError, ValueError) as error:
        failure = f'No readable iteration result: {error}'

    rows = [
        ('Assets', report.get('assets', {}), 'source_assets'),
        ('Rules', report.get('rules', {}), 'checks'),
        ('UI / input', report.get('ui', {}), 'checks'),
        ('Browser', report.get('browser', {}), 'checks'),
    ]
    mutations = report.get('mutations', {})
    browser = report.get('browser', {})
    complete = all(data.get(count, 0) > 0 and data.get('failed') == 0 for _, data, count in rows)
    complete = complete and len(mutations.get('detected', [])) > 0 and mutations.get('failed') == 0
    complete = complete and browser.get('matrix_requested') and browser.get('matrix_executed')
    if not failure:
        failure = report.get('failure') or browser.get('failure')
    if not failure and (report.get('status') != 'passed' or not complete):
        failure = 'Validation did not complete every required suite and viewport; inspect the preserved evidence.'
    if not failure and args.status != 'success':
        failure = f'A workflow step failed outside the completed iteration (job status: {args.status}).'
    passed = failure is None

    lines = [f'# Umbral — {"✅ aprovado" if passed else "❌ falhou"}', '',
             '| Validação | Verificações executadas | Resultado |', '|---|---:|---|']
    for name, data, count in rows:
        total = data.get(count, 0)
        status = '✅' if total > 0 and data.get('failed') == 0 else ('❌' if data else 'Não executado')
        lines.append(f'| {name} | {total} | {status} |')
    detected = len(mutations.get('detected', []))
    mutation_status = '✅' if detected and mutations.get('failed') == 0 else 'Não concluído'
    lines.append(f'| Mutações detectadas | {detected} | {mutation_status} |')
    lines.extend(['', f'**Formatos de tela:** {len(browser.get("matrix", []))} · **Capturas:** {len(browser.get("captures", []))}', ''])
    if report.get('steps'):
        lines.extend(['| Etapa | Resultado | Segundos |', '|---|---|---:|'])
        for step in report['steps']:
            outcome = '✅' if step['exit_code'] == 0 else '❌'
            lines.append(f'| {step["name"]} | {outcome} | {step["seconds"]} |')
        lines.append('')
    if args.build_manifest.is_file():
        builds = json.loads(args.build_manifest.read_text())
        lines.extend(['## Builds', '', '| Arquivo | Bytes | SHA-256 |', '|---|---:|---|'])
        for name, data in builds.items():
            lines.append(f'| `{name}` | {data["bytes"]} | `{data["sha256"]}` |')
        lines.append('')
    if failure:
        lines.extend(['## Falha', '', '```text', failure.replace('```', "'''"), '```', ''])
        escaped = failure.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
        print(f'::error title=Umbral CI::{escaped}')
    lines.extend([f'**Evidências:** `{report.get("evidence_dir", "consulte umbral-evidence")}`', '',
                  'Baixe os artifacts **umbral-evidence** e **umbral-builds** nesta execução. '
                  'O ZIP de revisão inclui o vídeo; o HTML portátil incorpora as imagens.', '',
                  'Os testes comprovam as validações executadas. Revisão visual, diversão, controle físico '
                  'e desempenho em hardware exigem avaliação própria.', ''])
    summary = '\n'.join(lines)
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with Path(os.environ['GITHUB_STEP_SUMMARY']).open('a') as output:
            output.write(summary)
    print(summary)
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
