"""Build, play and preserve reviewable evidence for one Umbral iteration. No quality score."""
import argparse
import base64
from datetime import datetime, timezone
import hashlib
import html
import importlib.metadata
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import zipfile

from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT
IGNORED = {'.godot', 'builds', 'test-results', 'artifacts', '__pycache__', '.git'}


def source_manifest():
    files = [p for p in ROOT.rglob('*') if p.is_file() and not IGNORED.intersection(p.relative_to(ROOT).parts)
             and not p.name.endswith(('.import', '.uid'))]
    records = {str(p.relative_to(REPO)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
    digest = hashlib.sha256(json.dumps(records, sort_keys=True).encode()).hexdigest()
    return {'sha256': digest, 'files': records}


def run_command(command, log):
    # Arguments remain argv entries. The shell only sources the writable tool environment.
    result = subprocess.run(['bash', '-c', 'set -euo pipefail; source tools/environment.sh; exec "$@"',
                             'umbral-iteration', *command], cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                            timeout=900)
    return result.returncode


def canonical(name):
    if name.startswith('matrix-'):
        return name
    for key in ['replacement', 'victory', 'evolution', 'capture', 'boss', 'battle', 'guide', 'menu']:
        if key in name:
            return key
    return name


def compare_images(current, baseline, out):
    comparisons = []
    if not baseline:
        return comparisons
    baseline = baseline / 'browser' if (baseline / 'browser').is_dir() else baseline
    index = {canonical(p.stem): p for p in sorted(baseline.glob('*.png')) if p.name != 'failure.png'}
    destination = out / 'baseline'
    destination.mkdir()
    for capture in current.get('captures', []):
        source = index.get(canonical(capture['name']))
        if not source:
            continue
        copied = destination / source.name
        if not copied.exists():
            shutil.copy2(source, copied)
        record = {'name': capture['name'], 'before': 'baseline/' + source.name,
                  'after': 'browser/' + capture['file'], 'pixel_diff': None}
        with Image.open(source) as old, Image.open(out / record['after']) as new:
            record['before_size'], record['after_size'] = list(old.size), list(new.size)
            # A pixel difference is a change diagnostic, never evidence of improvement.
            if old.size == new.size:
                delta = ImageChops.difference(old.convert('RGB'), new.convert('RGB'))
                path = 'diff-' + capture['name'] + '.png'
                delta.save(out / path)
                record['pixel_diff'] = path
                record['mean_channel_change'] = round(sum(ImageStat.Stat(delta).mean) / 3, 2)
            else:
                record['note'] = 'Different reference sizes; direct pixel comparison skipped.'
        comparisons.append(record)
    return comparisons


def write_review(out, report):
    browser = report.get('browser', {})
    pairs = {item['name']: item for item in report['comparisons']}
    rules = report.get('rules', {})
    ui = report.get('ui', {})
    contract = out / 'ux-contracts.json'
    if not contract.exists(): contract = ROOT / 'docs/ux-contracts.json'
    rubric = json.loads(contract.read_text())['review_questions']
    questions = ''.join(f'<label>{html.escape(q)}<textarea data-review="{i}" placeholder="Observação concreta, captura e decisão"></textarea></label>' for i,q in enumerate(rubric))
    embedded = {}

    def data_uri(relative, mime):
        if relative not in embedded:
            path = (out / relative).resolve()
            if not path.is_relative_to(out.resolve()):
                raise ValueError('Review assets must stay inside their evidence directory.')
            embedded[relative] = f'data:{mime};base64,' + base64.b64encode(path.read_bytes()).decode('ascii')
        return embedded[relative]

    def picture(relative, caption, portable):
        source = data_uri(relative, 'image/png') if portable else html.escape(relative, quote=True)
        name = html.escape(caption, quote=True)
        filename = html.escape(Path(relative).name, quote=True)
        return (f'<button type="button" class="zoom" aria-label="Ampliar {name}" data-filename="{filename}">'
                f'<img src="{source}" alt="{name}"></button>')

    for portable, filename in [(True, 'review.html'), (False, 'review-full.html')]:
        cards = []
        for item in browser.get('captures', []):
            name = html.escape(item['name'])
            pair = pairs.get(item['name'])
            before = ('<figure><figcaption>Anterior</figcaption>' + picture(pair['before'], item['name'] + ' Anterior', portable) + '</figure>') if pair else ''
            diagnostic = ('<details><summary>Diferença de pixels (não mede qualidade)</summary>' + picture(pair['pixel_diff'], item['name'] + ' Diferença', portable) + '</details>') if pair and pair.get('pixel_diff') else ''
            cards.append(f'<article><h2>{name}</h2><div class="pair">{before}<figure><figcaption>Atual</figcaption>'
                         + picture('browser/' + item['file'], item['name'] + ' Atual', portable) + f'</figure></div>{diagnostic}</article>')
        video = ''
        if (out / 'browser/gameplay.webm').exists():
            video = ('<p>O vídeo está no pacote completo de evidências. Extraia o ZIP e abra <code>index.html</code> para assisti-lo.</p>'
                     if portable else '<video controls preload="metadata" src="browser/gameplay.webm"></video>')
        run_href = data_uri('run.json', 'application/json') if portable else 'run.json'
        source_href = data_uri('source-manifest.json', 'application/json') if portable else 'source-manifest.json'
        portability = '<p>As imagens e os relatórios estão incorporados neste arquivo. Clique nas capturas para ampliar.</p>' if portable else '<p>Clique nas capturas para ampliar. Mantenha as pastas deste pacote ao lado de index.html.</p>'
        page = f'''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Umbral — revisão {html.escape(report['label'])}</title>
<style>body{{margin:0 auto;padding:32px;max-width:1500px;background:#101c23;color:#f3e6c5;font:18px/1.5 system-ui}}h1,h2{{font-family:Georgia,serif}}a{{color:#dec88d}}article{{margin:40px 0;padding-top:16px;border-top:1px solid #bac6b6}}.pair{{display:flex;gap:20px}}figure{{margin:0;flex:1;min-width:0}}img,video{{width:100%;height:auto}}video{{max-height:75vh}}figcaption{{margin:8px 0}}label{{display:block;margin:24px 0}}textarea{{display:block;box-sizing:border-box;width:100%;min-height:90px;background:#1a2933;color:#f3e6c5;font:inherit;padding:12px}}button{{padding:12px;font:inherit}}.zoom{{display:block;width:100%;padding:0;border:0;background:transparent;cursor:zoom-in}}button:focus-visible,a:focus-visible{{outline:3px solid #dec88d;outline-offset:4px}}dialog{{width:min(1600px,94vw);max-width:calc(100vw - 32px);max-height:calc(100vh - 32px);box-sizing:border-box;background:#101c23;color:#f3e6c5;border:1px solid #dec88d}}dialog::backdrop{{background:#000c}}.viewer-actions{{display:flex;gap:24px;align-items:center;margin-bottom:16px}}pre{{white-space:pre-wrap}}@media(max-width:800px){{.pair{{display:block}}}}</style>
<h1>Umbral {report['version']} — {html.escape(report['label'])}</h1>
<p>{html.escape(report['goal'])}</p><p>Resultado automático: <strong>{report['status']}</strong>.
Regras: {rules.get('checks','não executado')} verificações; UI: {ui.get('checks','não executado')}; navegador: {browser.get('checks','não executado')}.
<a href="{run_href}" download="run.json">Baixar relatório e limites</a> · <a href="{source_href}" download="source-manifest.json">Baixar hash das fontes</a></p>
{portability}
<p>Capturas atuais são renders do jogo. Diferenças de pixels mostram mudança, não beleza. Revise o vídeo e os estados abaixo antes de aceitar a direção.</p>
{video}{''.join(cards)}<article><h2>Revisão da experiência</h2>{questions}
<button id="save">Baixar notas desta revisão</button><p>As notas são suas; nenhum envio externo.</p></article>
<dialog id="image-viewer" aria-label="Captura ampliada"><div class="viewer-actions"><button id="close-image" autofocus>Fechar</button><a id="download-image">Baixar imagem original</a></div><div id="image-content"></div></dialog>
<script>const viewer=document.querySelector('#image-viewer');document.querySelectorAll('.zoom').forEach(button=>button.onclick=()=>{{const original=button.querySelector('img');document.querySelector('#image-content').replaceChildren(original.cloneNode());const download=document.querySelector('#download-image');download.href=original.src;download.download=button.dataset.filename;viewer.showModal()}});document.querySelector('#close-image').onclick=()=>viewer.close();viewer.addEventListener('close',()=>document.querySelector('#image-content').replaceChildren());
document.querySelector('#save').onclick=()=>{{const notes={{source_hash:{json.dumps(report['source_hash'])},iteration:{json.dumps(report['label'])},observations:{{}}}};document.querySelectorAll('textarea').forEach(t=>notes.observations[t.dataset.review]=t.value);const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([JSON.stringify(notes,null,2)],{{type:'application/json'}}));a.download='review-notes.json';a.click();URL.revokeObjectURL(a.href)}};</script></html>'''
        (out / filename).write_text(page, encoding='utf-8')
    shutil.copy2(out / 'review.html', out / 'review-standalone.html')

    # Keep a compact folder-based companion for the full video and original evidence.
    # The standalone HTML is intentionally excluded from this ZIP to avoid duplicating screenshots.
    archive = out / 'review-bundle.zip'
    excluded = {'review.html', 'review-standalone.html', 'review-full.html', 'review-legacy.html', 'review-page.png', 'review-form-check.json', 'review-delivery.json'}
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as bundle:
        bundle.write(out / 'review-full.html', 'index.html')
        for file in sorted(out.rglob('*')):
            relative = file.relative_to(out)
            if not file.is_file() or file.name in excluded or file.suffix == '.zip' or relative.parts[:2] == ('browser', 'video'):
                continue
            bundle.write(file, relative)
    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None: raise RuntimeError('Review ZIP failed CRC validation.')
    delivery = {'format_version':2,'source_hash':report['source_hash'],'evidence_rerun':False,
                'standalone':'review-standalone.html','bundle':archive.name,'embedded_images':len([x for x in embedded if x.endswith('.png')]),
                'standalone_bytes':(out / 'review.html').stat().st_size,'bundle_bytes':archive.stat().st_size,
                'bundle_sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}
    (out / 'review-delivery.json').write_text(json.dumps(delivery,indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--label', help='Short iteration name; a unique timestamp is appended.')
    parser.add_argument('--review-only', type=Path, help='Rebuild portable HTML/ZIP from an existing run; does not rerun the game.')
    parser.add_argument('--goal', default='Melhorar a experiência preservando os contratos de jogo e navegação.')
    parser.add_argument('--baseline', type=Path, help='Earlier iteration directory or archived screenshots.')
    parser.add_argument('--video', action='store_true')
    args = parser.parse_args()
    if args.review_only:
        out = args.review_only.resolve()
        if not (out / 'run.json').is_file(): parser.error('Review directory must contain run.json.')
        previous = out / 'review.html'
        if previous.exists() and not (out / 'review-legacy.html').exists():
            shutil.copy2(previous, out / 'review-legacy.html')
        write_review(out, json.loads((out / 'run.json').read_text()))
        print(json.dumps({'review':str(out / 'review-standalone.html'),'bundle':str(out / 'review-bundle.zip'),'evidence_rerun':False}))
        return 0
    if not args.label: parser.error('--label is required for a new iteration.')
    if not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9._-]{0,60}', args.label):
        parser.error('Use a short label containing letters, digits, dot, underscore or hyphen.')
    baseline = args.baseline.resolve() if args.baseline else None
    if baseline and not baseline.is_dir():
        parser.error('The baseline directory must exist.')
    artifact_root = ROOT / 'artifacts'
    artifact_root.mkdir(exist_ok=True)
    (artifact_root / '.gdignore').touch()
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    out = artifact_root / f'{args.label}-{stamp}'
    out.mkdir()  # Never overwrite an earlier attempt, even a failed one.
    (out / 'logs').mkdir()
    version = re.search(r'config/version="([^"]+)"', (ROOT / 'project.godot').read_text()).group(1)
    sources = source_manifest()
    (out / 'source-manifest.json').write_text(json.dumps(sources, indent=2))
    shutil.copy2(ROOT / 'skills-lock.json', out / 'skills-lock.json')
    for file in ['ux-contracts.json','art-direction-v0.3.md']:
        shutil.copy2(ROOT / 'docs' / file, out / file)
    started = time.monotonic()
    engine = subprocess.run(['bash','-c','source tools/environment.sh; godot --version'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip()
    report = {'label':args.label,'version':version,'goal':args.goal,'started_utc':stamp,
              'source_hash':sources['sha256'],'baseline':str(baseline) if baseline else None,
              'status':'running','steps':[],'comparisons':[],
              'tools':{'godot':engine,'python':sys.version.split()[0], 'playwright':importlib.metadata.version('playwright'), 'pillow':importlib.metadata.version('Pillow')},
              'visual_review':'pending; fill review notes after inspecting actual captures and video',
              'limits':['Software WebGL, not hardware performance measurements.', 'Synthetic gamepad events, not physical controller validation.',
                        'No automatic beauty/fun score. No full accessibility certification.', 'Local execution; no claim of a remote CI pass.']}
    command = [sys.executable,'tools/browser_smoke.py','--output',str(out / 'browser')]
    if args.video:
        command.append('--video')
    steps = [('rules-and-ui',['bash','tools/check.sh']),('web-export',['bash','tools/build.sh','Web']),('browser-experience',command)]
    failed = False
    try:
        for name, argv in steps:
            print(f'[{args.label}] {name}', flush=True)
            with (out / 'logs' / (name + '.log')).open('w') as log:
                step_start = time.monotonic()
                status = run_command(argv, log)
            report['steps'].append({'name':name,'exit_code':status,'seconds':round(time.monotonic()-step_start,2),'command':argv})
            if name == 'rules-and-ui':
                for filename in ['asset-report.json','asset-unit-report.json','asset_catalog_test.log','rules.log','mutation-report.json','ui-report.json','ui_state_test.log','ui_flow_test.log','startup_smoke.log','import.log']:
                    if (ROOT / 'test-results' / filename).exists():
                        shutil.copy2(ROOT / 'test-results' / filename, out / 'logs' / filename)
            if name == 'web-export' and status == 0:
                export = ROOT / 'builds/web/index.pck'
                report['web_pck_sha256'] = hashlib.sha256(export.read_bytes()).hexdigest()
            if status != 0:
                failed = True
                print(f'Failed: {out / "logs" / (name + ".log")}', flush=True)
                break
        if source_manifest()['sha256'] != sources['sha256']:
            raise RuntimeError('Sources changed during this iteration; evidence cannot describe one source revision.')
    except Exception as exception:
        failed = True
        report['failure'] = str(exception)
    finally:
        for key, path in [('assets',out / 'logs/asset-report.json'),('ui',out / 'logs/ui-report.json'),('mutations',out / 'logs/mutation-report.json'),('browser',out / 'browser/browser-report.json')]:
            if path.exists():
                report[key] = json.loads(path.read_text())
        if (out / 'logs/rules.log').exists():
            for line in (out / 'logs/rules.log').read_text().splitlines():
                if line.startswith('{'):
                    item = json.loads(line)
                    if item.get('suite') == 'umbral_rules':
                        report['rules'] = item
        report['status'] = 'failed' if failed else 'passed'
        report['seconds'] = round(time.monotonic()-started,2)
        report['comparisons'] = compare_images(report.get('browser',{}),baseline,out)
        (out / 'run.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
        write_review(out,report)
        print(json.dumps({'status':report['status'],'report':str(out / 'review.html'),'seconds':report['seconds']},ensure_ascii=False))
    return int(failed)


if __name__ == '__main__':
    raise SystemExit(main())
