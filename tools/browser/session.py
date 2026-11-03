"""Browser lifecycle, read-only diagnostics, real input, geometry and action timings."""
from contextlib import contextmanager
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
import threading
import time
from urllib.parse import urlencode
from playwright.sync_api import sync_playwright
from harness_lib.manifest import ROOT


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


def luminance(rgb):
    channels = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    return sum(v * weight for v, weight in zip(channels, [.2126, .7152, .0722]))


def contrast(a, b):
    bright, dark = sorted([luminance(a), luminance(b)], reverse=True)
    return (bright + .05) / (dark + .05)


class Session:
    def __init__(self, args):
        self.args, self.output = args, args.output.resolve()
        self.output.mkdir(parents=True, exist_ok=True)
        self.contracts = json.loads((ROOT / 'docs/ux-contracts.json').read_text())
        self.version = re.search(r'config/version="([^"]+)"', (ROOT / 'project.godot').read_text()).group(1)
        self.checks, self.logs, self.errors, self.captures, self.matrix, self.timings = [], [], [], [], [], []
        self.plans = {}
        self.viewport = list(map(int, args.viewport.split('x'))) if args.viewport else None
        self.started = time.monotonic()
        self.server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=str(args.build_dir.resolve())))
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.base_url = f'http://127.0.0.1:{self.server.server_port}/index.html'
        self.playwright = sync_playwright().start()
        self.browser = self.playwright.chromium.launch(executable_path='/usr/bin/chromium' if Path('/usr/bin/chromium').exists() else None,
            headless=True, args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
        self.browser_version = self.browser.version
        options = {'viewport': {'width': self.viewport[0], 'height': self.viewport[1]} if self.viewport else {'width': 1600, 'height': 900}, 'device_scale_factor': 1}
        if args.video: options.update(record_video_dir=str(self.output / 'video'), record_video_size={'width': 1280, 'height': 720})
        self.context = self.browser.new_context(**options)
        self.page = self.context.new_page()
        self.video = self.page.video
        self.page.on('pageerror', lambda error: self.errors.append(str(error)))
        self.page.on('console', lambda message: self.logs.append({'type': message.type, 'text': message.text, 'seconds': round(time.monotonic() - self.started, 3)}))

    @contextmanager
    def timing(self, action, detail=''):
        start = time.monotonic()
        try:
            yield
        finally:
            self.timings.append({'action': action, 'detail': detail, 'seconds': round(time.monotonic() - start, 4)})

    def state(self):
        return self.page.evaluate('window.umbralState')

    def failure(self):
        try:
            self.page.screenshot(path=str(self.output / 'failure.png'))
            (self.output / 'failure-state.json').write_text(json.dumps(self.state(), indent=2, ensure_ascii=False))
        except Exception:
            pass

    def check(self, condition, description):
        if not condition:
            self.failure()
            raise AssertionError(description)
        self.checks.append(description)

    def wait(self, expression, timeout=15000):
        try:
            self.page.wait_for_function('window.umbralState && (' + expression + ')', timeout=timeout)
        except Exception:
            self.failure()
            raise

    def settled(self):
        self.wait('!window.umbralState.busy')
        self.page.wait_for_timeout(200)

    def load(self):
        with self.timing('load', 'production menu'):
            self.page.goto(self.base_url + '?test=1&visual=1')
            self.wait(f"window.umbralState.version === '{self.version}' && window.umbralState.screen === 'menu'", timeout=90000)
            self.page.wait_for_timeout(200)

    def fixture(self, name):
        with self.timing('load', 'fixture:' + name):
            self.page.goto(self.base_url + '?' + urlencode({'test': '1', 'visual': '1', 'fixture': name, 'large_text': '1' if self.args.large_text else '0'}))
            self.wait(f"window.umbralState.fixture_ready && window.umbralState.fixture === {json.dumps(name)}", timeout=90000)
            self.settled()

    def key(self, value):
        with self.timing('key', value):
            serial = self.state()['input_serial']
            self.page.keyboard.press(value)
            self.wait(f'window.umbralState.input_serial > {serial}')

    def back(self, expected):
        self.key('Escape')
        self.wait("window.umbralState.screen === '" + expected + "'")

    def click(self, identity):
        with self.timing('click', identity):
            state = self.state()
            control = state['controls'][identity]
            self.check(control['visible'] and control['active'] and not control['disabled'], 'Reachable control: ' + identity + ' (screen: ' + state['screen'] + ')')
            canvas = self.page.locator('#canvas').bounding_box()
            logical = state['logical_size']
            self.page.mouse.click(canvas['x'] + control['cx'] / logical[0] * canvas['width'], canvas['y'] + control['cy'] / logical[1] * canvas['height'])
            self.wait(f"window.umbralState.interaction_serial > {state['interaction_serial']} && window.umbralState.last_interaction === '{identity}'")

    def shot(self, name):
        with self.timing('capture', name):
            self.settled()
            self.page.screenshot(path=str(self.output / (name + '.png')))
            (self.output / (name + '.state.json')).write_text(json.dumps(self.state(), indent=2, ensure_ascii=False))
            self.captures.append({'name': name, 'file': name + '.png', 'screen': self.state()['screen'], 'viewport': self.page.viewport_size, 'seconds': round(time.monotonic() - self.started, 3)})

    def geometry(self, description, scrollable=False):
        state = self.state()
        width, height = state['logical_size']
        active = {key: control for key, control in state['controls'].items() if control['visible'] and control['active'] and (not scrollable or control['fully_visible'] or control['focused'])}
        self.check(bool(active), description + ': actionable controls exist')
        for identity, control in active.items():
            self.check(0 <= control['cx'] <= width and 0 <= control['cy'] <= height and control['w'] > 0 and control['h'] > 0, description + ': target remains on screen — ' + identity)
            if identity.startswith('inventory.') and (not scrollable or control['focused']):
                self.check(control['fully_visible'], description + ': inventory target is fully visible — ' + identity)
            if identity.startswith('hand.'):
                self.check(control['title_fits'], description + ': power title fits — ' + identity)
            if 'foreground' in control:
                self.check(contrast(control['foreground'], control['background']) >= 4.5, description + ': solid button text has ≥4.5 contrast — ' + identity)
        if state['screen'] == 'battle':
            enemy = state['feedback']['enemy_name_bounds']
            for identity in ('hud.inventory', 'hud.help', 'hud.pause'):
                control = active[identity]
                overlap = control['x'] < enemy['x'] + enemy['w'] and control['x'] + control['w'] > enemy['x'] and control['y'] < enemy['y'] + enemy['h'] and control['y'] + control['h'] > enemy['y']
                self.check(not overlap, description + ': HUD does not overlap enemy name — ' + identity)
        if state['screen'] not in ['menu', 'battle']:
            self.check(state['overlay_z'] > state['card_max_z'], description + ': modal stays above elevated cards')
        self.check(state['focused'] in active, description + ': visible focus stays in the active screen')
        return {'screen': state['screen'], 'active_controls': len(active), 'logical_size': state['logical_size'], 'focused': state['focused']}

    def clear_selection(self):
        for index in list(self.state()['selected']):
            if index < 6: self.key(str(index + 1))
            else: self.click('hand.' + str(index))

    def start(self):
        self.click('menu.play')
        self.wait("window.umbralState.screen === 'battle' && window.umbralState.hand.length === 6")
        self.settled()

    def large_text(self):
        if self.args.large_text and not self.state()['preferences']['large_text']:
            self.click('hud.pause'); self.click('pause.settings'); self.click('settings.large_text')
            self.back('pause'); self.back('battle')

    def finish(self, failure=None):
        if failure is None:
            try:
                self.check(not self.errors, 'Browser reports no uncaught JavaScript errors')
                engine_errors = [entry for entry in self.logs if 'SCRIPT ERROR:' in entry['text'] or entry['text'].startswith('ERROR:')]
                self.check(not engine_errors, 'Godot reports no runtime errors')
            except Exception as error:
                failure = str(error)
        self.context.close()
        if self.video: self.video.save_as(str(self.output / 'gameplay.webm'))
        self.browser.close()
        self.playwright.stop()
        self.server.shutdown()
        self.server.server_close()
        (self.output / 'browser-console.json').write_text(json.dumps(self.logs, indent=2, ensure_ascii=False))
        (self.output / 'action-timings.json').write_text(json.dumps(self.timings, indent=2))
        report = {'suite': 'umbral_ui_experience', 'scenario': self.args.scenario, 'version': self.version, 'chromium': self.browser_version,
                  'checks': len(self.checks), 'failed': int(failure is not None), 'failure': failure, 'passed': self.checks,
                  'outcome': 'passed' if failure is None else 'failed', 'matrix': self.matrix,
                  'matrix_requested': self.args.scenario == 'layout',
                  'matrix_executed': len(self.matrix) == len(self.contracts['viewports']),
                  'captures': self.captures, 'seconds': round(time.monotonic() - self.started, 3),
                  'timings': self.timings, 'limits': ['software WebGL', 'focused scenario is not full acceptance', 'no physical controller or fun certification']}
        (self.output / 'browser-report.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))
        return report
