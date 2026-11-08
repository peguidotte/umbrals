from harness_lib.browser_runtime import chromium_executable
from refuge_browser_review import depart, point_walk, touch_depart
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
    if not control.get('center_visible', True):
        for _ in range(len(s['controls'])+1):
            key('Tab'); s = state(); control = s['controls'][identity]
            if s['focused'] == identity:
                wait("window.umbralState.controls["+json.dumps(identity)+"].center_visible === true")
                s=state(); control=s['controls'][identity]
                break
        check(control.get('center_visible', True), 'Keyboard reveals scrolled control: '+identity)
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
    with sync_playwright() as engine:
        browser = engine.chromium.launch(executable_path=chromium_executable(), headless=True,
            args=['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader'])
        options = {'viewport': {'width':1600,'height':900}, 'device_scale_factor':1, 'has_touch':True}
        if args.video: options.update(record_video_dir=str(OUT/'wide-video'),record_video_size={'width':1600,'height':900})
        context = browser.new_context(**options)
        page = context.new_page(); attach_errors(page); video = page.video
        load(base)
        check(state()['focused']=='menu.play','Missing save focuses New')
        check(state()['controls']['menu.continue']['disabled'],'Continue is visible and disabled without save')
        check('menu.quit' not in state()['controls'],'Web omits Quit')
        check(len(state()['title_effect']['card_poses'])==4,'Four independent actors are present')
        check(active_home()-{k for k in active_home() if k.startswith('menu.actor.')}=={'menu.play','menu.settings'},'Only New and Options are enabled primary actions without save')
        def storage(): return page.evaluate('JSON.stringify(Object.fromEntries(Object.entries(localStorage).sort()))')
        unchanged=storage()
        shot('wide-live.png')
        for species in ('ember','moss','dew','volt'):
            click('menu.actor.'+species)
            page.wait_for_timeout(350)
            check(state()['screen']=='menu','Actor reaction stays on title: '+species)
        check(storage()==unchanged,'Decorative interactions preserve every storage byte')
        click('menu.play'); wait("window.umbralState.screen === 'starter'")
        check(storage()==unchanged,'Opening New does not create a run')
        key('Escape'); wait("window.umbralState.screen === 'menu'")
        check(storage()==unchanged,'Cancel starter preserves every storage byte')
        click('menu.play'); click('starter.ember'); wait("window.umbralState.screen === 'map'")
        original=state()['expedition']
        key('Escape'); click('pause.menu'); click('confirm.yes'); wait("window.umbralState.screen === 'menu'")
        check(not state()['controls']['menu.continue']['disabled'],'Committed expedition enables Continue')
        saved=storage()
        click('menu.play'); wait("window.umbralState.screen === 'confirm_new'")
        check(state()['focused']=='new.cancel','Replacement confirmation focuses safe cancellation')
        click('new.cancel'); check(storage()==saved,'Cancel replacement preserves every checkpoint byte')
        click('menu.play'); click('new.confirm'); wait("window.umbralState.screen === 'starter'")
        key('Escape'); wait("window.umbralState.screen === 'menu'")
        check(storage()==saved,'Back from confirmed starter selection preserves every checkpoint byte')
        click('menu.continue'); wait("window.umbralState.screen === 'map'")
        check(state()['expedition']==original,'Continue restores the exact public expedition')
        key('Escape'); click('pause.menu'); click('confirm.yes'); wait("window.umbralState.screen === 'menu'")
        click('menu.settings')
        for screen in ('codex','help','credits'):
            click('settings.'+screen); wait("window.umbralState.screen === '"+screen+"'")
            key('Escape'); wait("window.umbralState.screen === 'settings'")
            check(state()['focused']=='settings.'+screen,'Secondary Back restores '+screen+' opener')
        key('Escape'); wait("window.umbralState.screen === 'menu'")
        check(state()['focused']=='menu.settings','Options returns focus to title opener')
        page.wait_for_timeout(2000)
        if args.video:
            # Keep genuine live playback long enough to review complete idle/reaction cycles.
            page.wait_for_timeout(max(0,22000-int((time.monotonic()-started)*1000)))
        load(base+'&visual=1')
        check(state()['focused']=='menu.continue','Reload with valid checkpoint focuses Continue')
        click('menu.settings'); key('Escape')
        for width,height in [(390,844),(1600,900),(320,568),(1600,900)]:
            page.set_viewport_size({'width':width,'height':height})
            profile = 'wide' if width/height >= 1.55 else 'portrait'
            wait("window.umbralState.title_effect.profile === '"+profile+"'")
            wait("window.umbralState.focused === 'menu.settings'")
            check(state()['controls']['menu.settings']['center_visible'],
                  'Options retains visible keyboard focus across reflow '+str((width,height)))
        load(base+'&visual=1')
        profiles=[(1280,720),(1440,900),(1600,900),(1920,1080),(1024,768),(2560,1080),(800,600),(800,1280),(390,844),(320,568),(3840,2160),(5120,1440)]
        for width,height in profiles:
            page.set_viewport_size({'width':width,'height':height});page.wait_for_timeout(250)
            observed=state(); logical=observed['logical_size']; canvas=page.locator('#canvas').bounding_box()
            for identity in ('menu.continue','menu.play','menu.settings'):
                c=observed['controls'][identity]
                check(0<=c['x'] and c['x']+c['w']<=logical[0]+1 and 0<=c['y'] and c['y']+c['h']<=logical[1]+1,'Primary bounds '+identity+' '+str((width,height)))
                check(c['h']/logical[1]*canvas['height']>=43.5,'Primary touch height '+identity+' '+str((width,height)))
            check(len(observed['title_effect']['card_poses'])==4,'All actors retained '+str((width,height)))
            shot(f'menu-{width}x{height}.png')
            # The representative profiles also cover live Options and reduced motion.
            if (width,height) in ((1600,900),(1024,768),(390,844),(320,568)):
                click('menu.settings');shot(f'options-{width}x{height}.png')
                click('settings.reduced_motion');key('Escape');wait("window.umbralState.screen === 'menu'")
                shot(f'reduced-{width}x{height}.png')
                check(state()['title_effect']['reduced_motion'],'Reduced motion applies '+str((width,height)))
                click('menu.settings');click('settings.reduced_motion');key('Escape');wait("window.umbralState.screen === 'menu'")
        click('menu.settings')
        focused_before_resize=state()['focused']
        page.set_viewport_size({'width':390,'height':844});page.wait_for_timeout(300)
        check(state()['focused']==focused_before_resize,'Resize keeps the current setting focused')
        click('settings.codex');key('Escape');wait("window.umbralState.screen === 'settings'")
        check(state()['focused']=='settings.codex','Resized scroll region restores the focused secondary link')
        key('Escape');wait("window.umbralState.screen === 'menu'")
        context.close()
        if video: videos.append(video.path())
        # Independent clean storage covers the empty-save composition at every size.
        empty=browser.new_context(viewport={'width':1600,'height':900},device_scale_factor=1)
        page=empty.new_page();attach_errors(page);load(base+'&visual=1')
        for width,height in profiles:
            page.set_viewport_size({'width':width,'height':height});page.wait_for_timeout(250)
            check(state()['controls']['menu.continue']['disabled'],'Clean storage disables Continue '+str((width,height)))
            shot(f'menu-empty-{width}x{height}.png')
        empty.close()
        options={'viewport':{'width':800,'height':1280},'has_touch':True,'device_scale_factor':1}
        if args.video: options.update(record_video_dir=str(OUT/'portrait-video'),record_video_size={'width':800,'height':1280})
        context=browser.new_context(**options);page=context.new_page();attach_errors(page);video=page.video
        portrait_start=time.monotonic();load(base)
        for species in ('ember','moss','dew','volt'):
            click('menu.actor.'+species,touch=True);page.wait_for_timeout(450)
        click('menu.settings',touch=True);click('settings.large_text',touch=True)
        shot('portrait-options-large.png');key('Escape');wait("window.umbralState.screen === 'menu'")
        shot('portrait-large-live.png')
        check(state()['preferences']['large_text'],'Portrait large text applies through real touch input')
        if args.video: page.wait_for_timeout(max(0,22000-int((time.monotonic()-portrait_start)*1000)))
        click('menu.settings');click('settings.reduced_motion');key('Escape');wait("window.umbralState.screen === 'menu'")
        page.mouse.move(0,0);page.wait_for_timeout(200);shot('reduced-motion-1.png');page.wait_for_timeout(350);shot('reduced-motion-2.png')
        check((OUT/'reduced-motion-1.png').read_bytes()==(OUT/'reduced-motion-2.png').read_bytes(),'Reduced-motion frames stay identical')
        context.close()
        if video: videos.append(video.path())
        check(not errors,'Browser console and pages have no errors')
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
