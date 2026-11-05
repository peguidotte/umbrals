"""Export a disposable actor review and capture its actual canvas to MP4.

This is an actor state review, separate from committed combat recordings.
The production main scene, fixtures and browser bridge remain unchanged.
"""
import argparse
import base64
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]


def run(command):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=180)
    if result.returncode or 'SCRIPT ERROR:' in result.stdout + result.stderr:
        raise RuntimeError((result.stdout + result.stderr)[-12000:])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='electric-state-review-', dir=output) as folder:
        project = Path(folder)
        for name in ['scripts', 'assets', 'content', 'scenes']:
            shutil.copytree(ROOT / name, project / name, copy_function=os.link,
                            ignore=shutil.ignore_patterns('*.import', '*.uid', 'review'))
        (project / 'tests').mkdir()
        for name in ['electric_states_preview.gd', 'electric_states_preview.tscn']:
            shutil.copy2(ROOT / 'tests' / name, project / 'tests' / name)
        configuration = (ROOT / 'project.godot').read_text().replace(
            'res://scenes/main.tscn', 'res://tests/electric_states_preview.tscn')
        configuration += '\n[editor]\nimport/use_multiple_threads=false\n'
        (project / 'project.godot').write_text(configuration)
        (project / 'export_presets.cfg').write_text((ROOT / 'export_presets.cfg').read_text().replace('tests/*,', ''))
        build = output / 'build'
        build.mkdir(exist_ok=True)
        run(['godot', '--headless', '--path', str(project), '--editor', '--import', '--quit'])
        run(['godot', '--headless', '--path', str(project), '--export-release', 'Web', str(build / 'index.html')])
    class Quiet(SimpleHTTPRequestHandler):
        def log_message(self, *_):
            pass
    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Quiet, directory=str(build)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    errors = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(executable_path='/usr/bin/chromium', args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
            page = browser.new_page(viewport={'width': 1600, 'height': 900})
            page.on('pageerror', lambda e: errors.append(str(e)))
            page.on('console', lambda m: errors.append(m.text) if 'SCRIPT ERROR:' in m.text else None)
            page.goto(f'http://127.0.0.1:{server.server_port}/index.html')
            page.wait_for_function('window.electricPreviewPhase === 0', timeout=90000)
            page.evaluate('''() => {
                const stream=document.querySelector('canvas').captureStream(30);
                const recorder=new MediaRecorder(stream,{mimeType:'video/webm;codecs=vp9',videoBitsPerSecond:4500000});
                const chunks=[];recorder.ondataavailable=e=>{if(e.data.size)chunks.push(e.data)};
                window.recording={recorder,chunks};recorder.start(200);
            }''')
            names = ['idle', 'walk', 'hurt', 'charge', 'ko', 'revived', 'reduced-ko']
            for phase, name in enumerate(names):
                if phase:
                    page.keyboard.press('Space')
                    page.wait_for_function(f'window.electricPreviewPhase === {phase}')
                page.wait_for_timeout(130 if name == 'hurt' else 900)
                page.screenshot(path=str(output / (name + '.png')))
                page.wait_for_timeout(1500)
            raw = page.evaluate('''async () => {
                const {recorder,chunks}=window.recording;
                await new Promise(resolve=>{recorder.onstop=resolve;recorder.stop()});
                const bytes=await new Blob(chunks,{type:recorder.mimeType}).arrayBuffer();
                let s='';for(const b of new Uint8Array(bytes))s+=String.fromCharCode(b);
                return btoa(s);
            }''')
            (output / 'states.webm').write_bytes(base64.b64decode(raw))
            browser.close()
        run(['ffmpeg', '-v', 'error', '-y', '-i', str(output / 'states.webm'), '-c:v', 'libx264', '-crf', '19', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(output / 'states.mp4')])
        if errors:
            raise RuntimeError(errors)
        (output / 'report.json').write_text(json.dumps({'kind': 'Actual Godot actor review; no combat simulation', 'viewport': [1600, 900], 'forms': ['volt', 'tempestral'], 'sides': ['ally', 'enemy'], 'states': names, 'errors': errors}, indent=2))
        print(output / 'states.mp4')
    finally:
        server.shutdown()


if __name__ == '__main__':
    main()
