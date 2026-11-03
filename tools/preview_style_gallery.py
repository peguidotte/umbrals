"""Export an isolated style-gallery copy, then capture actual Web rendering and a text-size click."""
import argparse
import json
from harness_lib.manifest import source_manifest
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=ROOT / 'test-results/style-gallery')
args = parser.parse_args()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
source = source_manifest()
original_project = (ROOT / "project.godot").read_bytes()


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


with tempfile.TemporaryDirectory(prefix='umbral-style-preview-') as temporary:
    folder = Path(temporary)
    for name in ['scripts', 'content', 'assets', 'scenes']:
        shutil.copytree(ROOT / name, folder / name, ignore=shutil.ignore_patterns('*.import', '*.uid'))
    shutil.copy2(ROOT / 'export_presets.cfg', folder)
    project = (ROOT / 'project.godot').read_text().replace('run/main_scene="res://scenes/main.tscn"', 'run/main_scene="res://scenes/style_gallery.tscn"')
    assert 'run/main_scene="res://scenes/style_gallery.tscn"' in project
    (folder / 'project.godot').write_text(project)
    build = folder / 'web'
    build.mkdir()
    for command in [['godot', '--headless', '--path', str(folder), '--editor', '--import', '--quit'],
                    ['godot', '--headless', '--path', str(folder), '--export-release', 'Web', str(build / 'index.html')]]:
        result = subprocess.run(command, capture_output=True, text=True, timeout=120)
        if result.returncode or 'SCRIPT ERROR:' in result.stdout + result.stderr or '\nERROR:' in result.stderr:
            raise RuntimeError(result.stdout + result.stderr)
    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=str(build)))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(executable_path='/usr/bin/chromium' if Path('/usr/bin/chromium').exists() else None,
                headless=True, args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
            page = browser.new_page(viewport={'width': 1600, 'height': 900})
            errors = []
            page.on('pageerror', lambda error: errors.append(str(error)))
            page.on('console', lambda message: errors.append(message.text) if 'SCRIPT ERROR:' in message.text or message.text.startswith('ERROR:') else None)
            page.goto(f'http://127.0.0.1:{server.server_port}/index.html')
            page.wait_for_function("!document.getElementById('status')", timeout=90000)
            page.wait_for_timeout(800)
            page.screenshot(path=str(output / 'style-default.png'))
            page.mouse.click(1385, 195)
            page.wait_for_timeout(800)
            page.screenshot(path=str(output / 'style-large.png'))
            if errors:
                raise RuntimeError('\n'.join(errors))
            browser.close()
    finally:
        server.shutdown()
        server.server_close()
assert (ROOT / 'project.godot').read_bytes() == original_project
assert source_manifest()['sha256'] == source['sha256']
(output / 'gallery-report.json').write_text(json.dumps({'suite': 'style_gallery', 'checks': 2, 'failed': 0, 'source_hash': source['sha256'], 'scene': 'scenes/style_gallery.tscn', 'captures': ['style-default.png', 'style-large.png'], 'interaction': 'real mouse click switches text scale', 'limits': ['software WebGL', 'visual review required']}, indent=2))
print(output)
