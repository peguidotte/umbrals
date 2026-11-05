"""Focused real-input pose review. The production bridge is read-only."""
import argparse
import functools
import http.server
import json
from pathlib import Path
import threading
import time
import traceback

from playwright.sync_api import sync_playwright
from refuge_browser_review import walk_to, pause_stairs

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--build-dir', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
OUT = args.output.resolve()
OUT.mkdir(parents=True, exist_ok=True)
checks, captures, errors = [], [], []
failure = None
video_path = None
observations = []
started = time.monotonic()


class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


server = http.server.ThreadingHTTPServer(
    ('127.0.0.1', 0), functools.partial(Handler, directory=str(args.build_dir.resolve())))
threading.Thread(target=server.serve_forever, daemon=True).start()


def check(value, label):
    if not value:
        raise AssertionError(label)
    checks.append(label)


try:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
            args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
        context = browser.new_context(viewport={'width': 1600, 'height': 900}, device_scale_factor=1,
            record_video_dir=str(OUT / 'video'), record_video_size={'width': 1600, 'height': 900})
        page = context.new_page()
        video = page.video
        page.on('pageerror', lambda e: errors.append(str(e)))
        page.on('console', lambda m: errors.append(m.text) if m.type == 'error' else None)
        # Observe public snapshots only. This adds no Godot setters or test boot.
        page.add_init_script('''window.pietroPoseReview=[];
            function observePietro(){const s=window.umbralState;
              if(s&&s.screen==='refuge'&&s.refuge.actor_pose){
                const h=s.refuge,p=h.actor_pose,last=window.pietroPoseReview.at(-1);
                const signature=JSON.stringify([p.animation,p.frame,h.waking,h.on_stairs,h.stair_direction]);
                if(!last||last.signature!==signature)window.pietroPoseReview.push({
                  signature,t_ms:performance.now(),pose:p,waking:h.waking,
                  progress:h.stair_progress,position:h.position});}
              requestAnimationFrame(observePietro);}requestAnimationFrame(observePietro);''')
        page.goto(f'http://127.0.0.1:{server.server_port}/index.html?test=1&visual=1')

        def state():
            return page.evaluate('window.umbralState')

        def wait(expression, timeout=30000):
            page.wait_for_function('window.umbralState && (' + expression + ')', timeout=timeout)

        def key(value):
            serial = state()['input_serial']
            page.keyboard.press(value)
            wait(f'window.umbralState.input_serial>{serial}')

        def click(identity):
            s = state()
            c = s['controls'][identity]
            check(c['visible'] and c['active'] and not c['disabled'], 'Reachable control: ' + identity)
            box = page.locator('#canvas').bounding_box()
            page.mouse.click(box['x'] + c['cx'] / s['logical_size'][0] * box['width'],
                             box['y'] + c['cy'] / s['logical_size'][1] * box['height'])
            wait(f"window.umbralState.interaction_serial>{s['interaction_serial']}&&window.umbralState.last_interaction==='{identity}'")

        def shot(name):
            page.screenshot(path=str(OUT / (name + '.png')))
            captures.append({'file': name + '.png', 'state': state()['refuge']})

        wait("window.umbralState.screen==='menu'", 90000)
        before = state()
        key('Enter')
        wait("window.umbralState.screen==='refuge'&&!window.umbralState.refuge.waking&&window.umbralState.refuge.armed")
        seen = page.evaluate('window.pietroPoseReview')
        names = list(dict.fromkeys(x['pose']['pose'] for x in seen if x['waking']))
        check(names == ['lying', 'propped', 'knees_seated', 'edge_seated', 'rising', 'standing'],
              'Real wake visits six dedicated drawings in order without injected state')
        check(state()['refuge']['actor_pose']['animation'] == 'idle', 'Wake returns to the normal home idle')
        shot('wake-complete')
        walk_to(page, wait, 3010)
        click('refuge.stairs')
        wait("window.umbralState.refuge.on_stairs&&window.umbralState.refuge.stair_progress>.3")
        pause_stairs(page, wait)
        paused = state()['refuge']
        check(paused['actor_pose']['animation'] == 'ascent', 'Ascent uses its own texture/pose family')
        page.wait_for_timeout(400)
        check(state()['refuge']['position'] == paused['position'] and state()['refuge']['actor_pose'] == paused['actor_pose'],
              'Pausing stairs holds both the world position and exact ascent drawing')
        shot('ascent-paused')
        key('e')
        wait("window.umbralState.refuge.upper_floor&&!window.umbralState.refuge.on_stairs")
        check(state()['refuge']['actor_pose']['animation'] == 'idle', 'Upper landing settles into the original idle')
        shot('upper-landing')
        click('refuge.stairs')
        wait("window.umbralState.refuge.on_stairs&&window.umbralState.refuge.stair_progress<.75")
        pause_stairs(page, wait)
        paused = state()['refuge']
        check(paused['actor_pose']['animation'] == 'descent', 'Descent uses its own drawing rather than mirrored ascent/walking')
        shot('descent-paused')
        page.keyboard.down('ArrowUp')
        try:
            wait(f"window.umbralState.refuge.actor_pose.animation==='ascent'&&window.umbralState.refuge.stair_progress>{paused['stair_progress']+.005}")
        finally:
            page.keyboard.up('ArrowUp')
        pause_stairs(page, wait)
        check(state()['refuge']['on_stairs'], 'Manual reversal stays on the same stair path')
        shot('reversed-upward')
        key('e')
        wait("window.umbralState.refuge.upper_floor&&!window.umbralState.refuge.on_stairs")
        key('Escape')
        wait("window.umbralState.screen==='menu'")
        click('menu.settings')
        click('settings.reduced_motion')
        check(state()['preferences']['reduced_motion'], 'Reduced motion enabled using its actual control')
        key('Escape')
        wait("window.umbralState.screen==='menu'")
        click('menu.play')
        wait("window.umbralState.refuge.armed")
        click('refuge.stairs')
        wait("window.umbralState.refuge.on_stairs&&window.umbralState.refuge.stair_progress<.8")
        reduced = state()['refuge']
        page.wait_for_timeout(400)
        check(state()['refuge']['actor_pose']['animation'] == 'descent' and state()['refuge']['actor_pose']['frame'] == 0
              and state()['refuge']['stair_progress'] < reduced['stair_progress'],
              'Reduced motion holds the dedicated descent drawing while real traversal continues')
        shot('descent-reduced-motion')
        wait("!window.umbralState.refuge.on_stairs&&!window.umbralState.refuge.upper_floor")
        fields = ('hand', 'deck', 'discard', 'party', 'enemies', 'actions', 'stats', 'expedition', 'checkpoint_status')
        check(all(before[k] == state()[k] for k in fields), 'Wake, stairs, reversal and preferences preserve game/checkpoint fields')
        check(not errors, 'Browser page and console have no runtime errors')
        observations = page.evaluate('window.pietroPoseReview')
        context.close()
        video_path = video.path()
        browser.close()
except Exception:
    failure = traceback.format_exc()
    try:
        page.screenshot(path=str(OUT / 'failure.png'))
        (OUT / 'failure-state.json').write_text(json.dumps(state(), indent=2))
        observations = page.evaluate('window.pietroPoseReview')
        context.close()
        video_path = video.path()
    except Exception:
        pass
finally:
    server.shutdown()
    report = {'scope': 'focused real Web inputs; no full acceptance or hardware claim', 'checks': len(checks),
              'passed': checks, 'failed': int(failure is not None), 'failure': failure, 'errors': errors,
              'captures': captures, 'observations': observations, 'video': str(video_path) if video_path else None,
              'seconds': round(time.monotonic() - started, 2)}
    (OUT / 'report.json').write_text(json.dumps(report, indent=2))
    print(json.dumps({'checks': len(checks), 'failed': report['failed'], 'output': str(OUT), 'video': report['video']}))
if failure:
    raise SystemExit(failure)
