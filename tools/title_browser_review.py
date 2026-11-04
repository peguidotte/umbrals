from refuge_browser_review import depart, point_walk
"""Real browser input and captures for the title menu and its card effect."""
import argparse
import functools
import http.server
import json
from pathlib import Path
import threading
import time
import traceback

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'test-results/title-review')
parser.add_argument('--video', action='store_true')
parser.add_argument('--build-dir', type=Path, default=ROOT / 'builds/web')
args = parser.parse_args()
OUT = args.output.resolve()
OUT.mkdir(parents=True, exist_ok=True)
checks, errors, captures, videos = [], [], [], []
started = time.monotonic()
failure = None
page = None


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


server = http.server.ThreadingHTTPServer(
    ('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(args.build_dir.resolve())))
threading.Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}/index.html?test=1'


def check(condition, description):
    if not condition:
        raise AssertionError(description)
    checks.append(description)


def state():
    return page.evaluate('window.umbralState')


def wait(expression, timeout=15000):
    page.wait_for_function('window.umbralState && (' + expression + ')', timeout=timeout)


def load(url):
    page.goto(url)
    wait("window.umbralState.screen === 'menu'", 90000)
    page.wait_for_timeout(300)


def shot(name):
    page.screenshot(path=str(OUT / name))
    captures.append({'name': Path(name).stem, 'file': name, 'screen': state()['screen']})


def key(value):
    serial = state()['input_serial']
    page.keyboard.press(value)
    wait(f'window.umbralState.input_serial > {serial}')


def coords(x, y, logical):
    canvas = page.locator('#canvas').bounding_box()
    return (canvas['x'] + x / logical[0] * canvas['width'],
            canvas['y'] + y / logical[1] * canvas['height'])


def click(identity, touch=False):
    s = state()
    control = s['controls'][identity]
    check(control['visible'] and control['active'] and not control['disabled'],
          'Reachable control: ' + identity)
    x, y = coords(control['cx'], control['cy'], s['logical_size'])
    if touch:
        page.touchscreen.tap(x, y)
    else:
        page.mouse.click(x, y)
    wait(f"window.umbralState.interaction_serial > {s['interaction_serial']} && window.umbralState.last_interaction === '{identity}'")


def active_home():
    return {k for k, c in state()['controls'].items()
            if k.startswith('menu.') and c['visible'] and c['active'] and not c['disabled']}


def attach_errors(p):
    p.on('pageerror', lambda error: errors.append(str(error)))
    p.on('console', lambda message: errors.append(message.text) if message.type == 'error' else None)


try:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
            args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
        expected = {'menu.play', 'menu.codex', 'menu.settings', 'menu.help', 'menu.credits'}
        room_options = {'viewport': {'width': 1672, 'height': 941}, 'device_scale_factor': 1}
        if args.video:
            room_options.update(record_video_dir=str(OUT / 'video'), record_video_size={'width': 1672, 'height': 941})
        context = browser.new_context(**room_options)
        page = context.new_page()
        room_video = page.video
        attach_errors(page)
        load(base + '&visual=1')
        check(active_home() == expected, 'Gold Web home exposes five active choices')
        shot('menu-default.png')
        check(state()['focused'] == 'menu.play', 'Play receives initial focus')
        for focus, name in [('menu.codex', 'menu-focus-codex.png'),
                            ('menu.settings', 'menu-focus-settings.png'),
                            ('menu.help', 'menu-focus-help.png')]:
            key('ArrowDown')
            check(state()['focused'] == focus, 'Keyboard focuses ' + focus)
            shot(name)
        key('ArrowUp'); key('ArrowUp'); key('ArrowUp')
        check(state()['focused'] == 'menu.play', 'Keyboard returns to Play')
        key('Enter')
        wait("window.umbralState.screen === 'refuge'")
        from refuge_browser_review import review_room
        review_room(page, state, wait, key, click, shot, check)
        click('refuge.exit')
        wait("window.umbralState.screen === 'journey'", 20000)
        check(state()['screen'] == 'journey', 'Explicit mouse door activation works again after returning at its threshold')
        wait("window.umbralState.screen === 'journey'")
        shot('journey.png')
        key('Escape')
        wait("window.umbralState.screen === 'refuge'")
        key('Escape')
        wait("window.umbralState.screen === 'menu'")
        check(state()['focused'] == 'menu.play', 'Cancel journey restores Play focus')
        click('menu.play')
        depart(page, wait)
        click('journey.new')
        wait("window.umbralState.screen === 'starter'")
        shot('starter.png')
        key('Escape')
        wait("window.umbralState.screen === 'journey'")
        check(state()['focused'] == 'journey.new', 'Cancel starter restores New focus')
        click('journey.new')
        click('starter.ember')
        wait("window.umbralState.screen === 'map'")
        saved_expedition = state()['expedition']
        click('map.pause'); click('pause.menu'); click('confirm.yes')
        click('menu.play')
        depart(page, wait)
        wait("window.umbralState.screen === 'journey'")
        check(not state()['controls']['journey.continue']['disabled'], 'Lobby offers the saved expedition')
        shot('lobby-saved.png')
        click('journey.new')
        wait("window.umbralState.screen === 'confirm_new'")
        click('new.cancel')
        click('journey.continue')
        wait("window.umbralState.screen === 'map'")
        check(state()['expedition'] == saved_expedition, 'Lobby cancel and Continue preserve the public expedition exactly')
        click('map.pause'); click('pause.menu'); click('confirm.yes')
        click('menu.settings'); click('settings.large_text'); key('Escape')
        wait("window.umbralState.screen === 'menu'")
        click('menu.play')
        depart(page, wait)
        wait("window.umbralState.screen === 'journey'")
        shot('lobby-saved-large-text.png')
        check(state()['focused'] == 'journey.new', 'Lobby restores the previous New focus after returning from settings')
        key('ArrowUp')
        check(state()['focused'] == 'journey.continue', 'Keyboard reaches Continue from restored New focus')
        key('ArrowDown')
        check(state()['focused'] == 'journey.new', 'Keyboard moves from Continue to New in lobby')
        key('ArrowDown')
        check(state()['focused'] == 'journey.practice', 'Keyboard reaches practice in lobby')
        key('Enter')
        wait("window.umbralState.screen === 'starter'")
        key('Escape')
        wait("window.umbralState.screen === 'journey'")
        click('journey.continue')
        wait("window.umbralState.screen === 'map'")
        check(state()['expedition'] == saved_expedition, 'Canceling practice from lobby preserves saved expedition')

        context.close()
        if room_video: videos.append(room_video.path())

        context = browser.new_context(viewport={'width': 844, 'height': 390}, device_scale_factor=1,
                                      has_touch=True, is_mobile=True)
        page = context.new_page()
        attach_errors(page)
        load(base + '&visual=1')
        check(active_home() == expected, 'Touch viewport exposes five gold-home choices')
        shot('touch-menu.png')
        click('menu.play', touch=True)
        wait("window.umbralState.refuge.armed")
        point_walk(page, state, wait, 450, "window.umbralState.refuge.position[0] < 500", touch=True)
        check(state()['screen'] == 'refuge', 'Touch on floor walks without opening a panel')
        click('refuge.codex', touch=True)
        check(state()['screen'] == 'refuge', 'Touch on distant book cannot open it remotely')
        wait("window.umbralState.screen === 'codex'", 20000)
        check(state()['refuge']['nearby'] == 'codex', 'Real touch reaches and opens the codex without keyboard')
        click('codex.back', touch=True)
        wait("window.umbralState.screen === 'refuge'")
        click('refuge.exit', touch=True)
        wait("window.umbralState.screen === 'journey'", 20000)
        check(all(state()['controls'][k]['visible'] and state()['controls'][k]['active']
                  for k in ('journey.new', 'journey.continue', 'journey.practice', 'journey.back')),
              'Touch viewport displays all journey choices')
        shot('touch-journey.png')
        click('journey.back', touch=True)
        click('refuge.title', touch=True)
        wait("window.umbralState.screen === 'menu'")
        context.close()

        options = {'viewport': {'width': 1672, 'height': 941}, 'device_scale_factor': 1}
        if args.video:
            options.update(record_video_dir=str(OUT / 'video'), record_video_size={'width': 1672, 'height': 941})
        context = browser.new_context(**options)
        page = context.new_page()
        video = page.video
        attach_errors(page)
        load(base)
        page.wait_for_timeout(2000)
        before = state()
        # The bridge deliberately exposes public game state, not RNG or raw save data.
        fields = ('screen', 'phase', 'hand', 'deck', 'discard', 'party', 'enemies', 'selected',
                  'actions', 'round_number', 'stats', 'expedition', 'checkpoint_status')
        x, y = coords(1150, 500, (1672, 941))
        page.mouse.click(x, y)
        wait(f"window.umbralState.input_serial > {before['input_serial']}")
        after = state()
        check(all(before[k] == after[k] for k in fields), 'Gold artwork background click keeps public game and checkpoint state intact')
        check(after['screen'] == 'menu', 'Gold artwork background click stays on menu')
        check(after['title_effect']['background'] == 'ui/gold-menu-scene' and after['title_effect']['card_poses'] == [], 'Gold title exposes its approved static composition')
        shot('gold-background-click.png')
        page.wait_for_timeout(2000)
        click('menu.settings')
        click('settings.reduced_motion')
        check(state()['preferences']['reduced_motion'], 'Reduced motion enabled through real control')
        key('Escape')
        wait("window.umbralState.screen === 'menu'")
        # Moving outside the canvas avoids hover changes between captures.
        page.mouse.move(0, 0)
        page.wait_for_timeout(300)
        effect = state()['title_effect']
        check(effect['reduced_motion'] and effect['clock'] == 0 and effect['card_poses'] == [],
              'Reduced motion preserves the static gold title')
        shot('reduced-motion-1.png')
        page.wait_for_timeout(300)
        shot('reduced-motion-2.png')
        check((OUT / 'reduced-motion-1.png').read_bytes() == (OUT / 'reduced-motion-2.png').read_bytes(),
              'Reduced-motion screenshots remain identical after 300 ms')
        page.wait_for_timeout(3500)
        context.close()
        if video:
            videos.append(video.path())
        check(not errors, 'Browser console and page have no errors')
        browser.close()
except Exception:
    failure = traceback.format_exc()
    if page:
        try:
            page.screenshot(path=str(OUT / 'failure.png'))
            (OUT / 'failure-state.json').write_text(json.dumps(state(), indent=2, ensure_ascii=False))
            s = state()
            print('Title presentation at failure: ' + json.dumps({k: s.get(k) for k in ('screen', 'focused', 'refuge', 'input_serial')}), flush=True)
        except Exception:
            pass
finally:
    server.shutdown()
    report = {'suite': 'title_browser_review', 'checks': len(checks), 'passed': checks,
              'failed': int(failure is not None), 'failure': failure, 'errors': errors,
              'captures': captures, 'videos': videos, 'seconds': round(time.monotonic() - started, 2),
              'limits': ['Software WebGL; public bridge does not expose RNG or raw save contents.',
                         'Screenshots and video require visual review.']}
    (OUT / 'title-browser-report.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))

if failure:
    raise SystemExit(failure)
