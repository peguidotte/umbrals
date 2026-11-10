from refuge_browser_review import depart
from harness_lib.browser_runtime import chromium_executable
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
        self.failure_captured = False
        self.starter_choice_seen = False
        self.viewport = list(map(int, args.viewport.split('x'))) if args.viewport else None
        self.started = time.monotonic()
        self.server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=str(args.build_dir.resolve())))
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.base_url = f'http://127.0.0.1:{self.server.server_port}/index.html'
        self.playwright = sync_playwright().start()
        native_gl = getattr(args, 'native_gl', False)
        graphics = ['--no-sandbox', '--use-angle=gl', '--use-gl=angle', '--ignore-gpu-blocklist', '--disable-gpu-sandbox', '--window-position=0,0'] if native_gl else ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader']
        self.browser = self.playwright.chromium.launch(executable_path=chromium_executable(),
            headless=not native_gl, args=graphics,
            ignore_default_args=['--mute-audio'] if getattr(args, 'capture_audio', False) else [])
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
        # Retain the first available state of this session, before PNG latency.
        if self.failure_captured:
            return
        self.failure_captured = True
        try:
            (self.output / 'failure-state.json').write_text(json.dumps(self.state(), indent=2, ensure_ascii=False))
        except Exception:
            pass
        try:
            self.page.screenshot(path=str(self.output / 'failure.png'))
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
            try:
                print(json.dumps({'event': 'browser_wait_failed', 'condition': expression,
                                  'timeout_ms': timeout, 'seconds': round(time.monotonic() - self.started, 3)}), flush=True)
            except Exception:
                pass
            self.failure()
            raise

    def settled(self):
        self.wait('!window.umbralState.busy', timeout=60000)
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
            if 'activation_point' in control:
                # Card transforms animate after focus/selection. Use the real
                # exposed plaque after it settles, including pointer hover.
                self.wait('!window.umbralState.controls[' + json.dumps(identity) + '].moving')
                control = self.state()['controls'][identity]
                point = control['activation_point']
                self.page.mouse.move(canvas['x'] + point[0] / logical[0] * canvas['width'], canvas['y'] + point[1] / logical[1] * canvas['height'])
                self.page.evaluate('() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))')
                self.wait('!window.umbralState.controls[' + json.dumps(identity) + '].moving')
                control = self.state()['controls'][identity]
            point = control.get('activation_point', [control['cx'], control['cy']])
            self.page.mouse.click(canvas['x'] + point[0] / logical[0] * canvas['width'], canvas['y'] + point[1] / logical[1] * canvas['height'])
            self.wait(f"window.umbralState.interaction_serial > {state['interaction_serial']} && window.umbralState.last_interaction === '{identity}'")

    def shot(self, name):
        settled, state, page, OUT, captures, started = self.settled, self.state, self.page, self.output, self.captures, self.started
        settled()
        original_name = name
        suffix = 2
        while (OUT / (name + '.png')).exists():
            name = original_name + '-' + str(suffix)
            suffix += 1
        page.screenshot(path=str(OUT / (name + '.png')))
        (OUT / (name + '.state.json')).write_text(json.dumps(state(), indent=2, ensure_ascii=False))
        captures.append({'name':name, 'file':name + '.png', 'screen':state()['screen'], 'viewport':page.viewport_size,'seconds':round(time.monotonic()-started,3)})

    def geometry(self, description, scrollable=False):
        state, check = self.state, self.check
        s = state()
        width, height = s['logical_size']
        active = {k:c for k,c in s['controls'].items() if c['visible'] and c['active'] and (not scrollable or 0 <= c['cy'] <= height)}
        check(bool(active), description + ': actionable controls exist')
        for identity, c in active.items():
            check(0 <= c['cx'] <= width and 0 <= c['cy'] <= height and c['w'] > 0 and c['h'] > 0,
                  description + ': target remains on screen — ' + identity)
            if identity.startswith('hand.'):
                check(c['title_fits'], description + ': power title fits — ' + identity)
            if 'foreground' in c:
                check(contrast(c['foreground'], c['background']) >= 4.5,
                      description + ': solid button text has ≥4.5 contrast — ' + identity)
        if s['screen'] == 'map':
            check(s['stack'] == ['map'] and not any(c['visible'] for k,c in s['controls'].items() if k.startswith('hand.')),
                  description + ': route room owns the root and hides battle cards')
        elif s['screen'] not in ['menu','battle','refuge']:
            check(s['overlay_z'] > s['card_max_z'], description + ': modal stays above elevated cards')
        check(s['focused'] in active, description + ': visible focus stays in the active screen')
        return {'screen':s['screen'], 'active_controls':len(active), 'logical_size':s['logical_size'], 'focused':s['focused']}

    def clear_selection(self):
        for index in list(self.state()['selected']):
            if index < 6: self.key(str(index + 1))
            else: self.click('hand.' + str(index))

    def start(self, species='ember'):
        click, wait, geometry, shot, settled = self.click, self.wait, self.geometry, self.shot, self.settled
        click('menu.play')
        depart(self.page, wait)
        wait("window.umbralState.screen === 'journey'")
        click('journey.practice')
        wait("window.umbralState.screen === 'starter'")
        geometry('Starter choice')
        if not self.starter_choice_seen:
            shot('04b-starter-choice')
            self.starter_choice_seen = True
        click('starter.' + species)
        wait("window.umbralState.screen === 'battle' && window.umbralState.hand.length === 6")
        settled()

    def large_text(self):
        if self.args.large_text and not self.state()['preferences']['large_text']:
            self.click('hud.pause'); self.click('pause.settings'); self.click('settings.large_text')
            self.back('pause'); self.back('battle')

    def finish(self, failure=None):
        if failure is None:
            try:
                self.check(not self.errors, 'Browser reports no uncaught JavaScript errors')
                engine_errors = [entry for entry in self.logs if 'SCRIPT ERROR:' in entry['text'] or entry['text'].startswith('ERROR:')]
                for entry in engine_errors:
                    print('Godot runtime diagnostic: ' + entry['text'], flush=True)
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
