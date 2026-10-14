"""Behavior + visual evidence for Umbral. All actions use real browser mouse/keyboard input."""
import argparse
import functools
import http.server
import json
import math
from pathlib import Path
import re
import subprocess
import threading
import time
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'test-results')
parser.add_argument('--video', action='store_true')
parser.add_argument('--no-matrix', action='store_true', help='Explicit quick run; the report marks the unrun matrix.')
args = parser.parse_args()
OUT = args.output.resolve()
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'browser-report.json').unlink(missing_ok=True)
version = re.search(r'config/version="([^"]+)"', (ROOT / 'project.godot').read_text()).group(1)
contracts = json.loads((ROOT / 'docs/ux-contracts.json').read_text())
subprocess.run(['bash', '-c', 'set -euo pipefail; source tools/environment.sh; godot --headless --path . --script tests/make_browser_plan.gd'], cwd=ROOT, check=True)
plans = json.loads((ROOT / 'test-results/browser-plan.json').read_text())
(OUT / 'browser-plan.json').write_text(json.dumps(plans, indent=2))
checks, logs, errors, captures, matrix = [], [], [], [], []
failure = None
started = time.monotonic()


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(ROOT / 'builds/web')))
threading.Thread(target=server.serve_forever, daemon=True).start()


def check(condition, description):
    if not condition:
        capture_failure()
        raise AssertionError(description)
    checks.append(description)


def luminance(rgb):
    channels = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    return sum(v * weight for v, weight in zip(channels, [.2126, .7152, .0722]))


def contrast(a, b):
    bright, dark = sorted([luminance(a), luminance(b)], reverse=True)
    return (bright + .05) / (dark + .05)


def capture_failure():
    try:
        page.screenshot(path=str(OUT / 'failure.png'))
        (OUT / 'failure-state.json').write_text(json.dumps(page.evaluate('window.umbralState'), indent=2, ensure_ascii=False))
    except Exception:
        pass


try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium' if Path('/usr/bin/chromium').exists() else None,
            headless=True, args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
        browser_version = browser.version
        options = {'viewport': {'width':1600, 'height':900}, 'device_scale_factor':1}
        if args.video:
            options.update(record_video_dir=str(OUT / 'video'), record_video_size={'width':1280, 'height':720})
        context = browser.new_context(**options)
        page = context.new_page()
        video = page.video
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.on('console', lambda message: logs.append({'type':message.type, 'text':message.text, 'seconds':round(time.monotonic()-started,3)}))
        url = f'http://127.0.0.1:{server.server_port}/index.html?test=1&visual=1'

        def state():
            return page.evaluate('window.umbralState')

        def wait(expression, timeout=15000):
            try:
                page.wait_for_function('window.umbralState && (' + expression + ')', timeout=timeout)
            except Exception:
                capture_failure()
                raise

        def settled():
            wait('!window.umbralState.busy')
            page.wait_for_timeout(200)

        def load():
            page.goto(url)
            wait(f"window.umbralState.version === '{version}' && window.umbralState.screen === 'menu'", timeout=90000)
            page.wait_for_timeout(200)

        def wait_saved(filename, expected):
            # Godot's userfs -> IndexedDB sync is asynchronous. Observe committed
            # bytes before unloading; never force a save or mutate browser state.
            page.wait_for_function('''async ({filename, expected}) => {
                for (const info of await indexedDB.databases()) {
                    if (!info.name) continue;
                    const db = await new Promise((resolve, reject) => {
                        const request = indexedDB.open(info.name);
                        request.onsuccess = () => resolve(request.result);
                        request.onerror = () => reject(request.error);
                        request.onupgradeneeded = () => request.transaction.abort();
                    });
                    try {
                        if (!db.objectStoreNames.contains('FILE_DATA')) continue;
                        const saved = await new Promise((resolve, reject) => {
                            const transaction = db.transaction('FILE_DATA', 'readonly');
                            const request = transaction.objectStore('FILE_DATA').openCursor();
                            request.onerror = () => reject(request.error);
                            request.onsuccess = () => {
                                const row = request.result;
                                if (!row) return resolve(false);
                                if (String(row.key).endsWith('/' + filename)) {
                                    try {
                                        const data = JSON.parse(new TextDecoder().decode(row.value.contents));
                                        return resolve(Object.entries(expected).every(([key,value]) => data[key] === value));
                                    } catch (_) { return resolve(false); }
                                }
                                row.continue();
                            };
                        });
                        if (saved) return true;
                    } finally { db.close(); }
                }
                return false;
            }''', arg={'filename': filename, 'expected': expected}, timeout=20000, polling=250)

        def key(value):
            serial = state()['input_serial']
            page.keyboard.press(value)
            wait(f'window.umbralState.input_serial > {serial}')

        def back(expected):
            key('Escape')
            wait("window.umbralState.screen === '" + expected + "'")

        def click(identity):
            s = state()
            control = s['controls'][identity]
            check(control['visible'] and control['active'] and not control['disabled'],
                  'Reachable control: ' + identity + ' (screen: ' + s['screen'] + ')')
            canvas = page.locator('#canvas').bounding_box()
            logical = s['logical_size']
            page.mouse.click(canvas['x'] + control['cx'] / logical[0] * canvas['width'],
                             canvas['y'] + control['cy'] / logical[1] * canvas['height'])
            wait(f"window.umbralState.interaction_serial > {s['interaction_serial']} && window.umbralState.last_interaction === '{identity}'")

        def shot(name):
            settled()
            page.screenshot(path=str(OUT / (name + '.png')))
            (OUT / (name + '.state.json')).write_text(json.dumps(state(), indent=2, ensure_ascii=False))
            captures.append({'name':name, 'file':name + '.png', 'screen':state()['screen'], 'viewport':page.viewport_size,'seconds':round(time.monotonic()-started,3)})

        def geometry(description):
            s = state()
            width, height = s['logical_size']
            active = {k:c for k,c in s['controls'].items() if c['visible'] and c['active']}
            check(bool(active), description + ': actionable controls exist')
            for identity, c in active.items():
                check(0 <= c['cx'] <= width and 0 <= c['cy'] <= height and c['w'] > 0 and c['h'] > 0,
                      description + ': target remains on screen — ' + identity)
                if identity.startswith('hand.'):
                    check(c['title_fits'], description + ': power title fits — ' + identity)
                if 'foreground' in c:
                    check(contrast(c['foreground'], c['background']) >= 4.5,
                          description + ': solid button text has ≥4.5 contrast — ' + identity)
            if s['screen'] not in ['menu','battle']:
                check(s['overlay_z'] > s['card_max_z'], description + ': modal stays above elevated cards')
            check(s['focused'] in active, description + ': visible focus stays in the active screen')
            return {'screen':s['screen'], 'active_controls':len(active), 'logical_size':s['logical_size'], 'focused':s['focused']}

        def clear_selection():
            for index in list(state()['selected']):
                key(str(index + 1))

        def start():
            click('menu.play')
            wait("window.umbralState.screen === 'battle' && window.umbralState.hand.length === 6")
            settled()

        load()
        check(state()['focused'] == 'menu.play', 'Title opens with clear initial focus')
        geometry('Title')
        shot('01-menu')
        key('ArrowDown')
        check(state()['focused'] == 'menu.codex', 'Arrow keys navigate the title menu')
        key('Enter')
        wait("window.umbralState.screen === 'codex'")
        shot('02-codex')
        back('menu')
        check(state()['focused'] == 'menu.codex', 'Back restores the previous title choice')
        click('menu.settings')
        wait("window.umbralState.screen === 'settings'")
        before_volume = state()['preferences']['music']
        key('ArrowRight')
        check(state()['preferences']['music'] > before_volume, 'Keyboard adjusts the Music bus slider')
        click('settings.reduced_motion')
        click('settings.large_text')
        check(state()['preferences']['reduced_motion'] and state()['preferences']['large_text'], 'Accessibility preferences respond to actual controls')
        geometry('Large-text options')
        shot('03-options-large')
        wait_saved('umbral_preferences_v1.json', state()['preferences'])
        load()
        check(state()['preferences']['reduced_motion'] and state()['preferences']['large_text'], 'Accessibility preferences persist after reload')
        check(math.isclose(state()['preferences']['music'], before_volume + .05, abs_tol=.001), 'Volume preference persists after reload')
        click('menu.settings')
        click('settings.reduced_motion')
        click('settings.large_text')
        back('menu')
        click('menu.help')
        wait("window.umbralState.screen === 'help'")
        shot('04-guide')
        back('menu')
        start()
        initial_party = state()['party']
        check(len(initial_party) == 2 and all('power' in c and 'rank' not in c for c in state()['hand']), 'Menu starts the owned-power game')
        shot('05-battle')
        before_id = state()['controls']['hand.0']['instance_id']
        for value in ['1','2','3','4']:
            key(value)
        check(len(state()['selected']) == 3, 'Three-power selection limit is enforced')
        check(state()['controls']['hand.0']['instance_id'] == before_id, 'Selection preserves card nodes and focus infrastructure')
        key('1')
        check(len(state()['selected']) == 2, 'Keyboard deselects a power')
        click('hud.pause')
        wait("window.umbralState.screen === 'pause'")
        snapshot = state()
        key('Space')
        check(state()['actions'] == snapshot['actions'], 'Pause blocks gameplay shortcuts')
        shot('06-pause')
        click('pause.settings')
        check(state()['stack'] == ['battle','pause','settings'], 'Options sit over pause without discarding combat')
        click('settings.reduced_motion')
        check(all(c.get('reduced_motion',False) for k,c in state()['controls'].items() if k.startswith('hand.')), 'Reduced motion updates existing cards immediately')
        geometry('Options above selected cards')
        shot('07-options-over-combat')
        back('pause')
        check(state()['screen'] == 'pause', 'Back from nested options returns to pause')
        back('battle')
        check(state()['screen'] == 'battle' and state()['selected'] == snapshot['selected'], 'Resume preserves selected powers')
        click('hud.inspect')
        check(state()['screen'] == 'inspect', 'A focused power can be inspected')
        shot('08-inspection')
        back('battle')
        before = state()
        click('hud.redraw')
        check(state()['discards'] == 1 and state()['hand'] != before['hand'], 'Exchange changes powers and spends a charge')
        check(state()['plays'] == before['plays'] and state()['intent'] == before['intent'], 'Exchange preserves the enemy intention')
        abandon_before = state()
        click('hud.pause')
        click('pause.menu')
        check(state()['screen'] == 'confirm_menu', 'Leaving an ongoing expedition requires an explicit confirmation')
        back('pause')
        check(state()['screen'] == 'pause' and all(state()[field] == abandon_before[field]
              for field in ['hand','party','actions','plays','discards','hp','selected','intent']),
              'Cancelling title return preserves the run')
        back('battle')
        # Return deliberately, then start the deterministic full playthrough with normal motion.
        click('hud.pause'); click('pause.menu'); click('confirm.yes')
        wait("window.umbralState.screen === 'menu'")
        click('menu.settings')
        click('settings.reduced_motion')
        back('menu')
        start()

        illegal_tested = False
        impact_tested = False
        signature_seen = False

        def execute(plan, primary=True):
            global illegal_tested, impact_tested, signature_seen
            for step in plan['plan']:
                if step['action'] == 'play':
                    settled()
                    check(state()['hand'] == step['hand'], 'Visible hand matches deterministic rule state')
                    if primary and step['illegal_indices'] and not illegal_tested:
                        for index in step['illegal_indices']:
                            key(str(index + 1))
                        check(not state()['preview']['valid'] and state()['preview']['energy'] > 3, 'Over-budget selection communicates its energy error')
                        shot('09-energy-error')
                        before = state()
                        key('Space')
                        check(state()['actions'] == before['actions'] and state()['hand'] == before['hand'], 'Rejected cast has no side effects')
                        clear_selection()
                        illegal_tested = True
                    for index in step['indices']:
                        click('hand.' + str(index))
                    check(state()['preview']['damage'] == step['damage'] and state()['preview']['energy'] == step['energy'], 'Cast preview matches damage and effective energy')
                    if primary and state()['encounter'] == 2:
                        if any(c['power'] == 'inferno' for c in state()['hand']) and not signature_seen:
                            shot('12-evolved-boss')
                            signature_seen = True
                    before = state()
                    page.keyboard.press('Space')
                    wait('window.umbralState.busy')
                    if primary and not impact_tested:
                        # A second real key press must not commit a second action.
                        page.keyboard.press('Space')
                        check(state()['actions'] == before['actions'] + 1, 'Impact feedback cannot double-cast')
                        page.wait_for_timeout(170)
                        page.screenshot(path=str(OUT / '10-cast-feedback.png'))
                        (OUT / '10-cast-feedback.state.json').write_text(json.dumps(state(),indent=2,ensure_ascii=False))
                        captures.append({'name':'10-cast-feedback','file':'10-cast-feedback.png','screen':state()['screen'],'viewport':page.viewport_size,'seconds':round(time.monotonic()-started,3)})
                        impact_tested = True
                    settled()
                    check(state()['hp'] == step['hp_after'] and state()['phase'] == step['phase_after'], 'Animated action resolves the same rules and outcome')
                    if primary:
                        check(state()['feedback']['particles'] <= 64 and state()['audio']['voice_pool'] == 4, 'Feedback uses bounded particle and audio pools')
                        check(state()['feedback']['hits'] > before['feedback']['hits'], 'Damage emits a discrete visual impact event')
                else:
                    wait("window.umbralState.screen === 'reward'")
                    check(state()['phase'] == 'reward', 'Clear opens capture/evolution')
                    if primary:
                        shot('11-capture' if step['offer']['kind']=='capture' else '11-evolution')
                    click('reward.' + str(step['index']))
                    if step['replace_uid'] >= 0:
                        wait("window.umbralState.screen === 'replacement'")
                        unchanged = state()['party']
                        shot('14-replacement')
                        back('reward')
                        check(state()['screen']=='reward' and state()['party']==unchanged, 'Cancelling replacement preserves the offered individual and team')
                        click('reward.' + str(step['index']))
                        index = next(i for i,u in enumerate(state()['party']) if u['uid']==step['replace_uid'])
                        click('replace.' + str(index))
                    wait("window.umbralState.screen === 'battle'")
                    settled()
                    check(state()['party']==step['party_after'], 'Reward preserves the offered identity and passive')
                    if step['offer']['kind']=='evolve':
                        all_cards=state()['hand']+state()['deck']+state()['discard']
                        check(sum(c['power']=='inferno' for c in all_cards)==2, 'Evolution unlocks two signature cards')
                        check(state()['party'][0]['passive']==initial_party[0]['passive'], 'Evolution preserves the individual passive')
                    if step['replace_uid']>=0:
                        all_cards=state()['hand']+state()['deck']+state()['discard']
                        check(all(c['owner']!=step['replace_uid'] for c in all_cards), 'Replacement removes powers from the released owner')

        execute(plans['primary'])
        check(illegal_tested and impact_tested and signature_seen, 'The run covers energy rejection, animated impact and evolved powers')
        check(state()['screen']=='victory' and state()['stats']['wins']==1 and state()['stats']['runs']==1, 'Complete animated victory records statistics exactly once')
        shot('13-victory')
        page.wait_for_timeout(650)
        check(state()['feedback']['trauma']==0, 'Shake returns to rest')
        wait_saved('umbral_stats_v1.json', state()['stats'])
        load()
        check(state()['stats']['wins']==1, 'Statistics persist through a browser reload')
        start()
        execute(plans['replacement'], primary=False)
        check(state()['screen']=='battle' and state()['encounter']==2, 'Alternative capture path resumes with a rebuilt team')
        click('hud.pause'); click('pause.menu'); click('confirm.yes')

        if not args.no_matrix:
            profiles = contracts['viewports']
            for width,height in profiles:
                page.set_viewport_size({'width':width,'height':height})
                page.wait_for_timeout(250)
                load()
                meta=geometry(f'Menu {width}×{height}')
                shot(f'matrix-menu-{width}x{height}')
                start()
                meta.update(geometry(f'Battle {width}×{height}'))
                key('1')
                shot(f'matrix-battle-{width}x{height}')
                click('hud.pause')
                geometry(f'Pause {width}×{height}')
                click('pause.settings')
                click('settings.large_text')
                geometry(f'Large options {width}×{height}')
                shot(f'matrix-options-{width}x{height}')
                back('pause'); back('battle')
                geometry(f'Large battle {width}×{height}')
                shot(f'matrix-large-battle-{width}x{height}')
                click('hud.pause'); click('pause.menu'); click('confirm.yes')
                click('menu.settings'); click('settings.large_text'); back('menu')
                matrix.append({'viewport':{'width':width,'height':height},'status':'passed','details':meta})

        check(not errors, 'Browser reports no uncaught JavaScript errors')
        engine_errors=[item for item in logs if 'SCRIPT ERROR:' in item['text'] or item['text'].startswith('ERROR:')]
        check(not engine_errors, 'Godot reports no runtime errors')
        context.close()
        if video:
            video.save_as(str(OUT / 'gameplay.webm'))
        browser.close()
except Exception as exception:
    failure = str(exception)
    try:
        page.screenshot(path=str(OUT / 'failure.png'))
        (OUT / 'failure-state.json').write_text(json.dumps(state(),indent=2,ensure_ascii=False))
    except Exception:
        pass
    raise
finally:
    server.shutdown()
    (OUT / 'browser-console.json').write_text(json.dumps(logs,indent=2,ensure_ascii=False))
    report={'suite':'umbral_ui_experience','version':version,'chromium':globals().get('browser_version'),'checks':len(checks),'failed':int(failure is not None),'failure':failure,'passed':checks,'outcome':'victory' if failure is None else 'failed','matrix':matrix,'matrix_requested':not args.no_matrix,'matrix_executed':len(matrix)==len(contracts['viewports']),'captures':captures,'seconds':round(time.monotonic()-started,2),'limits':['software WebGL rendering','synthetic Godot gamepad events are separate from physical controller testing','beauty, fun and full accessibility require review']}
    (OUT / 'browser-report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
    print(json.dumps({k:v for k,v in report.items() if k in ['suite','version','checks','failed','failure','outcome','seconds']},ensure_ascii=False))
