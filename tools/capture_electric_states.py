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


def export_review(output):
    with tempfile.TemporaryDirectory(prefix='electric-state-review-', dir=output) as folder:
        project = Path(folder)
        for name in ['scripts', 'assets', 'content', 'scenes']:
            shutil.copytree(ROOT / name, project / name, copy_function=shutil.copy2,
                            ignore=shutil.ignore_patterns('review'))
        # Reuse imported texture bytes only; editor state and source files stay private.
        if (ROOT / '.godot/imported').is_dir():
            shutil.copytree(ROOT / '.godot/imported', project / '.godot/imported', copy_function=os.link)
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
    return build


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--build-dir', type=Path)
    parser.add_argument('--native-gl', action='store_true')
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    build = args.build_dir.resolve() if args.build_dir else export_review(output)
    class Quiet(SimpleHTTPRequestHandler):
        def log_message(self, *_):
            pass
    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Quiet, directory=str(build)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    errors = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=not args.native_gl, args=['--no-sandbox', '--use-angle=gl', '--use-gl=angle', '--ignore-gpu-blocklist', '--disable-gpu-sandbox', '--window-position=0,0'] if args.native_gl else ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
            viewport = {'width': 1280, 'height': 720} if args.native_gl else {'width': 1600, 'height': 900}
            page = browser.new_page(viewport=viewport)
            page.on('pageerror', lambda e: errors.append(str(e)))
            page.on('console', lambda m: errors.append(m.text) if 'SCRIPT ERROR:' in m.text else None)
            page.goto(f'http://127.0.0.1:{server.server_port}/index.html')
            page.wait_for_function('window.electricPreviewPhase === 0', timeout=90000)
            if args.native_gl:
                region = page.evaluate('''() => {const r=document.querySelector('canvas').getBoundingClientRect();return {x:Math.round(window.screenX+r.left),y:Math.round(window.screenY+window.outerHeight-window.innerHeight+r.top)}}''')
                capture_log=(output/'x11-capture.log').open('w')
                display=os.environ['DISPLAY'].split('.')[0]+'.0+'+str(region['x'])+','+str(region['y'])
                recorder=subprocess.Popen(['ffmpeg','-v','error','-y','-f','x11grab','-framerate','30','-video_size','1280x720','-i',display,'-c:v','libx264','-preset','ultrafast','-crf','20','-pix_fmt','yuv420p',str(output/'states.mp4')],stdin=subprocess.PIPE,stdout=capture_log,stderr=capture_log)
            else:
                page.evaluate('''() => {
                const stream=document.querySelector('canvas').captureStream(30);
                const recorder=new MediaRecorder(stream,{mimeType:'video/webm;codecs=vp8',videoBitsPerSecond:4500000});
                const chunks=[];recorder.ondataavailable=e=>{if(e.data.size)chunks.push(e.data)};
                window.recording={recorder,chunks};recorder.start(200);
            }''')
            names = ['idle', 'walk', 'hurt', 'charge', 'ko', 'revived', 'reduced-ko']
            cadence = []
            for phase, name in enumerate(names):
                if phase:
                    page.keyboard.press('Space')
                    page.wait_for_function(f'window.electricPreviewPhase === {phase}')
                page.wait_for_timeout(130 if name == 'hurt' else 900)
                page.screenshot(path=str(output / (name + '.png')))
                page.wait_for_function(f'window.electricCadence && window.electricCadence.phase === {phase}', timeout=15000)
                cadence.append(page.evaluate('window.electricCadence'))
                page.wait_for_timeout(400)
            if args.native_gl:
                recorder.communicate(b'q\n',timeout=30)
                capture_log.close()
            else:
                raw = page.evaluate('''async () => {
                    const {recorder,chunks}=window.recording;
                    await new Promise(resolve=>{recorder.onstop=resolve;recorder.stop()});
                    const bytes=await new Blob(chunks,{type:recorder.mimeType}).arrayBuffer();
                    let s='';for(const b of new Uint8Array(bytes))s+=String.fromCharCode(b);
                    return btoa(s);
                }''')
                (output / 'states.webm').write_bytes(base64.b64decode(raw))
            browser.close()
        if not args.native_gl: run(['ffmpeg', '-v', 'error', '-y', '-i', str(output / 'states.webm'), '-c:v', 'libx264', '-crf', '19', '-pix_fmt', 'yuv420p', '-fps_mode', 'passthrough', '-movflags', '+faststart', str(output / 'states.mp4')])
        if errors:
            raise RuntimeError(errors)
        probe = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries',
            'stream=avg_frame_rate,nb_frames,width,height:format=duration', '-of', 'json', str(output/'states.mp4')],
            capture_output=True, text=True, check=True)
        report = {'kind': 'Actual Godot actor review; no combat simulation', 'viewport': list(viewport.values()),
            'capture_backend': 'X11 / ANGLE OpenGL' if args.native_gl else 'canvas MediaRecorder / SwiftShader',
            'forms': ['volt', 'tempestral'], 'sides': ['ally', 'enemy'], 'states': names,
            'cadence': cadence, 'video_probe': json.loads(probe.stdout), 'errors': errors}
        report['sufficient_review_cadence'] = min(entry['fps'] for entry in cadence) >= 24
        (output / 'report.json').write_text(json.dumps(report, indent=2))
        if not report['sufficient_review_cadence']:
            raise RuntimeError('Review cadence below 24 FPS; evidence retained but not accepted as cadence proof')
        print(output / 'states.mp4')
    finally:
        server.shutdown()


if __name__ == '__main__':
    main()
