"""Scoped real-input review for V04-UX-05C. No battles or full regression matrix."""
import argparse
import functools
import hashlib
import http.server
import json
from pathlib import Path
import threading
import time
import traceback
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'test-results/V04-UX-05C-menu')
parser.add_argument('--web-root', type=Path, default=ROOT / 'builds/web')
parser.add_argument('--video', action='store_true')
args = parser.parse_args()
OUT = args.output.resolve()
OUT.mkdir(parents=True, exist_ok=True)
checks, errors, captures, videos = [], [], [], []
started = time.monotonic()
pack_path = args.web_root.resolve() / 'index.pck'
pack_hash = hashlib.sha256(pack_path.read_bytes()).hexdigest() if pack_path.exists() else None
failure = None
page = None

class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_): pass
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0),
    functools.partial(Quiet, directory=str(args.web_root.resolve())))
threading.Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}/index.html?test=1'

def check(value, message):
    if not value: raise AssertionError(message)
    checks.append(message)

def state(): return page.evaluate('window.umbralState')
def wait(expr, timeout=20000): page.wait_for_function('window.umbralState && (' + expr + ')', timeout=timeout)
def settle(): page.wait_for_timeout(330)
def shot(name):
    settle()
    page.screenshot(path=str(OUT / (name + '.png')))
    captures.append(name + '.png')
def point(x, y, logical):
    c = page.locator('#canvas').bounding_box()
    return c['x'] + x / logical[0] * c['width'], c['y'] + y / logical[1] * c['height']
def click(identity, touch=False):
    s = state(); c = s['controls'][identity]
    check(c['visible'] and c['active'] and not c['disabled'], 'Reachable ' + identity)
    x, y = point(c['cx'], c['cy'], s['logical_size'])
    (page.touchscreen.tap if touch else page.mouse.click)(x, y)
    wait(f"window.umbralState.interaction_serial > {s['interaction_serial']} && window.umbralState.last_interaction === '{identity}'")
    settle()
def key(value):
    s = state()['input_serial']; page.keyboard.press(value)
    wait(f'window.umbralState.input_serial > {s}')
    settle()
def storage(): return page.evaluate('JSON.stringify(Object.fromEntries(Object.entries(localStorage).filter(([k]) => k.includes("run"))))')
def all_storage(): return page.evaluate('JSON.stringify(Object.fromEntries(Object.entries(localStorage)))')
def home_bounds(touch=False):
    s = state(); c = page.locator('#canvas').bounding_box()
    rects = []
    for identity in ('menu.play', 'menu.codex', 'menu.settings', 'menu.help'):
        control = s['controls'][identity]
        check(control['active'] and control['visible'], 'Visible at viewport ' + str(page.viewport_size) + ': ' + identity)
        check(control['x'] >= 0 and control['y'] >= 0 and control['x'] + control['w'] <= s['logical_size'][0] + 1 and control['y'] + control['h'] <= s['logical_size'][1] + 1,
              'Hit target within viewport: ' + identity)
        if touch:
            check(control['h'] / s['logical_size'][1] * c['height'] >= 43.9, '44px touch target: ' + identity)
        rects.append(control)
    for a, b in zip(rects, rects[1:]): check(a['y'] + a['h'] <= b['y'] + 0.5, 'Menu touch targets do not overlap')
def attach():
    page.on('pageerror', lambda error: errors.append(str(error)))
    page.on('console', lambda msg: errors.append(msg.text) if msg.type == 'error' or 'SCRIPT ERROR:' in msg.text or msg.text.startswith('ERROR:') else None)
def load():
    page.goto(base)
    wait("window.umbralState.screen === 'menu'", 90000)
    page.mouse.move(1660, 930)
    settle()

try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
            args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
        opts = dict(viewport={'width':1672,'height':941}, device_scale_factor=1)
        context = browser.new_context(**opts)
        page = context.new_page(); video = page.video; attach(); load()
        home_bounds()
        check(state()['focused'] == 'menu.play', 'Initial Play focus')
        shot('menu-desktop')
        before = state()['title_effect']['card_poses']
        key('ArrowDown')
        check(state()['focused'] == 'menu.codex', 'Keyboard enters Codex focus')
        shot('menu-keyboard-focus')
        check(before != state()['title_effect']['card_poses'], 'Independent card transforms advance with live time')
        key('Enter'); wait("window.umbralState.screen === 'codex'")
        shot('codex-themed')
        key('Escape'); wait("window.umbralState.screen === 'menu'")
        check(state()['focused'] == 'menu.codex', 'Back restores Codex focus')
        c = state()['controls']['menu.settings']; page.mouse.move(*point(c['cx'],c['cy'],state()['logical_size'])); shot('menu-hover')
        page.mouse.down(); shot('menu-pressed'); page.mouse.up(); wait("window.umbralState.screen === 'settings'")
        key('Escape'); wait("window.umbralState.screen === 'menu'")
        saved = all_storage(); game_before = state()
        effect_before = game_before['title_effect']['awakenings']
        logical = state()['logical_size']; factor = min(logical[0]/1672, logical[1]/941)
        x=(logical[0]-1672*factor)/2+1150*factor; y=(logical[1]-941*factor)/2+500*factor
        page.mouse.click(*point(x,y,logical)); wait(f'window.umbralState.title_effect.awakenings > {effect_before}')
        page.screenshot(path=str(OUT/'card-reaction.png')); captures.append('card-reaction.png')
        check(saved == all_storage(), 'Card reaction does not write storage')
        check(all(game_before[k] == state()[k] for k in ('phase','party','deck','hand','discard','selected','actions','round_number','expedition','stats')), 'Card reaction leaves game state intact')
        check(state()['title_audio']['awakening_count'] > 0 and state()['title_audio']['navigation_count'] > 0, 'Navigation and card sounds dispatched')
        page.wait_for_timeout(6000)
        click('menu.play'); wait("window.umbralState.screen === 'journey'"); shot('journey-empty')
        check(state()['controls']['journey.continue']['disabled'], 'Continue disabled without a save')
        click('journey.new'); click('starter.ember'); wait("window.umbralState.screen === 'map'")
        original_map = state()['expedition']; shot('new-expedition-map')
        checkpoint = storage()
        click('map.pause'); click('pause.menu'); click('confirm.yes'); wait("window.umbralState.screen === 'menu'")
        click('menu.play'); shot('journey-saved')
        check(state()['journey_summary'] == 'Bosque · Próxima parada: Clareira', 'Saved card identifies the actual next point')
        check([[i[k] for k in ('uid','species','form_id','hp','max_hp','slot')] for i in state()['journey_party']] == [[i[k] for k in ('uid','species','form_id','hp','max_hp','slot')] for i in original_map['party']], 'Saved party is the same public party')
        click('journey.new'); wait("window.umbralState.screen === 'confirm_new'"); click('new.cancel')
        check(storage() == checkpoint, 'Cancel New preserves exact localStorage checkpoint')
        click('journey.continue'); wait("window.umbralState.screen === 'map'")
        check(state()['expedition'] == original_map, 'Continue restores the same map and roster')
        click('map.pause'); click('pause.menu'); click('confirm.yes')
        # Same session at different ratios: no repeat WASM startup or combat routes.
        for name, width, height in [('menu-ultrawide',2560,1080),('menu-portrait',390,844),('menu-small-portrait',360,640),('menu-tablet',1024,768)]:
            page.set_viewport_size({'width':width,'height':height}); settle(); key('Shift')
            home_bounds(); shot(name)
        page.set_viewport_size({'width':1672,'height':941}); settle(); key('Shift')
        click('menu.settings'); click('settings.large_text'); key('Escape'); home_bounds(); shot('menu-large-text')
        click('menu.play'); shot('journey-large-text'); click('journey.back')
        click('menu.settings'); click('settings.reduced_motion'); key('Escape')
        page.mouse.move(1660,930); settle(); key('Shift')
        before = state()['title_effect']; shot('reduced-motion-1'); page.wait_for_timeout(350); key('Shift'); shot('reduced-motion-2')
        check(before['clock'] == 0 and state()['title_effect']['card_poses'] == before['card_poses'], 'Reduced motion freezes all card transforms')
        check((OUT/'reduced-motion-1.png').read_bytes() == (OUT/'reduced-motion-2.png').read_bytes(), 'Reduced-motion menu is pixel-stable')
        context.close()
        if video: videos.append(video.path())
        context = browser.new_context(viewport={'width':844,'height':390}, device_scale_factor=1, has_touch=True, is_mobile=True)
        page = context.new_page(); attach(); load(); key('Shift'); home_bounds(touch=True); shot('menu-touch')
        click('menu.play',True); wait("window.umbralState.screen === 'journey'"); shot('journey-touch')
        click('journey.back',True); check(state()['screen'] == 'menu', 'Touch back returns to menu')
        page.set_viewport_size({'width':390,'height':844}); settle(); key('Shift'); home_bounds(touch=True); shot('menu-touch-portrait')
        click('menu.play',True); shot('journey-touch-portrait'); click('journey.back',True)
        check(not errors, 'No browser or engine errors')
        context.close()
        if args.video:
            # Record only the motion segment. Recording every navigation/resize dominated
            # the first exploratory run and adds no verification to those checks.
            context = browser.new_context(viewport={'width':1672,'height':941}, device_scale_factor=1,
                record_video_dir=str(OUT / 'video'), record_video_size={'width':1280,'height':720})
            page = context.new_page(); video = page.video; attach(); load()
            page.wait_for_timeout(1800)
            page.mouse.click(*point(1150, 500, (1672,941)))
            wait('window.umbralState.title_effect.awakenings === 1')
            page.wait_for_timeout(4500)
            context.close(); videos.append(video.path())
        browser.close()
except Exception:
    failure = traceback.format_exc()
    if page:
        try:
            page.screenshot(path=str(OUT/'failure.png'))
            (OUT/'failure-state.json').write_text(json.dumps(state(),indent=2,ensure_ascii=False))
        except Exception: pass
finally:
    server.shutdown()
    if pack_hash and hashlib.sha256(pack_path.read_bytes()).hexdigest() != pack_hash:
        failure = (failure or '') + '\nThe exported pack changed during review; this is not immutable-package evidence.'
    report={'suite':'title_polish_browser_scoped','checks':len(checks),'passed':checks,'failed':int(failure is not None),'failure':failure,'errors':errors,'captures':captures,'videos':videos,'seconds':round(time.monotonic()-started,2),'limits':['Chromium software WebGL; emulated touch, no physical phone or subjective audio listening.','No combat regression suite per user instruction.']}
    report['web_pck_sha256'] = pack_hash
    (OUT/'report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
    print(json.dumps({k:report[k] for k in ('suite','checks','failed','seconds','errors')}))
if failure: raise SystemExit(failure)
