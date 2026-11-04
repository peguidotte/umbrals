"""Bake the illustrated VFX into transparent, fixed-pivot prototype flipbooks."""
import base64
import json
import threading
import hashlib
import subprocess
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[2]
MODULE = ROOT / 'assets/attacks/woodland-elements/versions/1.0.0'
NAMES = ['fire-comet', 'fire-crescent', 'ember-flower', 'fire-impact',
         'thorn-whip', 'root-spire', 'thorn-dart', 'bark-impact',
         'water-bolt', 'water-ribbon', 'crest-wave', 'water-impact',
         'lightning-lance', 'electric-turbine', 'lightning-wing', 'electric-impact']


def main():
    subprocess.run(['git', 'rev-parse', '--verify', 'origin/main'], cwd=ROOT,
                   check=True, stdout=subprocess.DEVNULL)
    published = subprocess.run(['git', 'cat-file', '-e',
        'origin/main:' + str((MODULE / 'manifest.json').relative_to(ROOT))],
        cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if published.returncode == 0:
        raise RuntimeError('This version is immutable on origin/main; author a new module version first.')
    class Handler(SimpleHTTPRequestHandler):
        def log_message(self, *_args):
            pass

    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(
        Handler, directory=str(ROOT / 'builds/attack-studies-v4')))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    manifest_path = MODULE / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    manifest['animations'] = {}
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium', args=['--no-sandbox'])
        page = browser.new_page()
        page.goto(f'http://127.0.0.1:{server.server_port}/galeria.html')
        page.wait_for_function('window.loaded')
        page.evaluate('window.exportMode=true')
        for n, name in enumerate(NAMES):
            encoded = page.evaluate('''n => {
                const canvas=document.createElement('canvas');canvas.width=768;canvas.height=576;
                const c=canvas.getContext('2d');
                const aspect=[2,.86,1,1,1.9,.87,1.8,1,2.3,1.9,1.3,1.4,1.9,1,1.25,1][n];
                const width=aspect>=1?150:150*aspect,height=aspect>=1?150/aspect:150;
                for(let f=0;f<12;f++){
                    const phase=f/12,impact=n%4===3;
                    const scale=impact?.35+.65*Math.sin(Math.min(1,phase*2)*Math.PI/2):1;
                    const alpha=impact?Math.pow(1-phase,1.3):1;
                    ElementArt.draw(c,n,(f%4)*192+96,Math.floor(f/4)*192+96,
                        width*scale,height*scale,0,alpha,phase);
                }
                return canvas.toDataURL('image/png').split(',')[1];
            }''', n)
            path = MODULE / f'{name}.png'
            path.write_bytes(base64.b64decode(encoded))
            manifest['files'][name] = {
                'kind': 'texture', 'path': path.name, 'bytes': path.stat().st_size,
                'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'technical': {'filtering': 'nearest'},
                'provenance': {'kind': 'Procedural animation of original image_gen atlas',
                               'source_sha256': hashlib.sha256((MODULE / 'source-atlas.png').read_bytes()).hexdigest(),
                               'renderer_sha256': hashlib.sha256((ROOT / 'tools/asset_authoring/attack_studies_v4.js').read_bytes()).hexdigest(),
                               'notes': '12 deterministic deformation frames; fixed transparent cell and pivot.'}}
            manifest['animations'][name] = {
                'file': name, 'columns': 4, 'frames': 12, 'frame_size': [192, 192],
                'display_size': [192, 192], 'pivot': [96, 96], 'fps': 24,
                'loop': n % 4 != 3}
        browser.close()
    server.shutdown()
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    print('Exported 16 transparent VFX clips, 12 frames each, fixed 96/96 pivot.')


if __name__ == '__main__':
    main()
