"""Replay native expedition plans through real Chromium canvas input and preserve evidence."""
import argparse
import functools
import http.server
import json
from pathlib import Path
import subprocess
import threading
import time
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'test-results/expedition-browser')
args = parser.parse_args()
OUT = args.output.resolve()
OUT.mkdir(parents=True, exist_ok=True)
subprocess.run(['bash', '-c', 'set -euo pipefail; source tools/environment.sh; godot --headless --path . --script tests/make_expedition_plan.gd'], cwd=ROOT, check=True)
plans = json.loads((ROOT / 'test-results/expedition-plan.json').read_text())
(OUT / 'expedition-plan.json').write_text(json.dumps(plans, indent=2, ensure_ascii=False))
checks, captures, logs, errors = [], [], [], []
start = time.monotonic()
failure = None

class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_): pass

server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(Quiet, directory=str(ROOT / 'builds/web')))
threading.Thread(target=server.serve_forever, daemon=True).start()
url = f'http://127.0.0.1:{server.server_port}/index.html?test=1&visual=1'

def check(condition, message):
    if not condition: raise AssertionError(message)
    checks.append(message)

try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium' if Path('/usr/bin/chromium').exists() else None,
                                    headless=True, args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
        browser_version = browser.version
        context = browser.new_context(viewport={'width':1600, 'height':900}, device_scale_factor=1, has_touch=True)
        page = context.new_page()
        page.on('pageerror', lambda e: errors.append(str(e)))
        page.on('console', lambda m: logs.append({'type':m.type, 'text':m.text}))
        def state(): return page.evaluate('window.umbralState')
        def wait(expression, timeout=30000):
            page.wait_for_function('window.umbralState && (' + expression + ')', timeout=timeout)
        def settled():
            wait('!window.umbralState.busy')
            page.wait_for_timeout(150)
        def load():
            page.goto(url)
            wait("window.umbralState.screen === 'menu'", 90000)
            page.wait_for_timeout(200)
        def click(identity, touch=False):
            s = state()
            c = s['controls'][identity]
            check(c['visible'] and c['active'] and not c['disabled'], f'{identity} is reachable on {s["screen"]}')
            canvas = page.locator('#canvas').bounding_box()
            x = canvas['x'] + c['cx'] / s['logical_size'][0] * canvas['width']
            y = canvas['y'] + c['cy'] / s['logical_size'][1] * canvas['height']
            if touch: page.touchscreen.tap(x, y)
            else: page.mouse.click(x, y)
            wait(f"window.umbralState.interaction_serial > {s['interaction_serial']} && window.umbralState.last_interaction === '{identity}'")
        def key(value):
            serial = state()['input_serial']
            page.keyboard.press(value)
            wait(f'window.umbralState.input_serial > {serial}')
        def shot(name):
            settled()
            original = name
            suffix = 2
            while (OUT / (name + '.png')).exists():
                name = original + '-' + str(suffix)
                suffix += 1
            page.screenshot(path=str(OUT / (name + '.png')))
            (OUT / (name + '.state.json')).write_text(json.dumps(state(), indent=2, ensure_ascii=False))
            captures.append({'name':name, 'file':name + '.png', 'screen':state()['screen'], 'viewport':page.viewport_size})
        def nodes(): return {n['id']:n for n in state()['expedition']['nodes']}
        def actors_match(observed, expected):
            fields = ['uid', 'species', 'passive', 'slot', 'hp', 'max_hp', 'stage', 'attack', 'defense', 'speed', 'block', 'statuses', 'can_act_round']
            return len(observed) == len(expected) and all(all(a.get(k) == b.get(k) for k in fields) for a,b in zip(observed, expected))
        def map_check():
            check(state()['screen'] == 'map' and state()['expedition']['phase'] == 'map', 'Map and controller agree on phase')
            for n in nodes().values():
                c = state()['controls']['map.node.' + n['id']]
                check(c['disabled'] == (not n['available']), n['id'] + ' availability matches visible button')
        def start_run():
            click('menu.play')
            if state()['screen'] == 'confirm_new': click('new.confirm')
            wait("window.umbralState.screen === 'starter'")
            click('starter.ember')
            wait("window.umbralState.screen === 'map'")
            map_check()
            check(state()['checkpoint_status'] == 'ok', 'Initial expedition checkpoint is saved')
        def replay(branch):
            start_run()
            check(nodes()['clearing']['available'] and nodes()['boss']['locked'], 'Only the first node is initially accessible')
            shot(branch + '-initial-map')
            reloaded = False
            capture_cancelled = False
            for step in plans[branch]['plan']:
                if step['action'] == 'node':
                    map_check()
                    n = step['id']
                    before = state()['expedition']
                    check(nodes()[n]['available'], n + ' is available before entry')
                    if n == 'clearing' and branch == 'thicket':
                        check(state()['focused'] == 'map.node.clearing', 'Initial map node has keyboard focus')
                        key('Enter')
                    else:
                        click('map.node.' + n, touch=(n == 'clearing' and branch == 'spring'))
                    check(state()['expedition'] == before, 'Inspecting a node does not mutate the run')
                    if n == 'spring':
                        def spring_selected():
                            return state()['controls']['map.node.spring']['text'].startswith('◆ ')
                        check(spring_selected(), 'Spring is visibly selected before pausing')
                        click('map.pause'); click('pause.resume')
                        check(spring_selected() and state()['expedition'] == before, 'Pause and resume preserve Spring and map state')
                        click('map.pause'); click('pause.settings'); click('settings.large_text')
                        click('settings.back'); click('pause.resume')
                        check(spring_selected() and state()['expedition'] == before, 'Text scale changes preserve Spring and map state')
                        shot('spring-selection-after-pause-settings')
                        click('map.pause'); click('pause.settings'); click('settings.large_text')
                        click('settings.back'); click('pause.resume')
                        check(spring_selected() and state()['expedition'] == before, 'Restoring text scale keeps the chosen route')
                    click('map.confirm')
                    settled()
                    if n == 'spring':
                        wait("window.umbralState.screen === 'map'")
                        check(state()['checkpoint_status'] == 'ok', 'Rest checkpoint is saved')
                        check(actors_match(state()['expedition']['party'], step['party_after']), 'Rest applies the native healing result')
                        check(nodes()['thicket']['locked'] and nodes()['spring']['completed'], 'Rest completes once and locks the alternate branch')
                        shot('spring-completed-map')
                    else:
                        wait("window.umbralState.screen === 'battle'")
                        check(state()['checkpoint_status'] == 'ok', 'Encounter entry checkpoint is saved')
                        check(actors_match(state()['party'], step['party_after']), 'Entering ' + n + ' preserves native roster and HP')
                        if n == 'boss': shot(branch + '-boss')
                elif step['action'] == 'play':
                    settled()
                    check(state()['hand'] == step['hand'], 'Visible hand equals seeded native plan')
                    for swap in step['swaps']:
                        reserves = sorted([u for u in state()['party'] if u['slot'] < 0 and u['hp'] > 0], key=lambda u:u['uid'])
                        index = next(i for i,u in enumerate(reserves) if u['uid'] == swap['in_uid'])
                        click('reserve.' + str(index)); click('swap.slot.' + str(swap['slot']))
                    for i in step['indices']: click('hand.' + str(i))
                    click('hud.redraw' if step['reroll'] else 'hud.cast')
                    settled()
                    check(actors_match(state()['party'], step['party_after']) and actors_match(state()['enemies'], step['enemies_after']), 'Resolved actors match the native simulation')
                    check(state()['phase'] == step['phase_after'], 'Battle outcome matches the native simulation')
                    if state()['expedition']['phase'] not in ['victory', 'defeat']:
                        check(state()['checkpoint_status'] == 'ok', 'Resolved turn checkpoint is saved')
                    if not reloaded and state()['screen'] == 'battle':
                        before = state()
                        saved = {k:before[k] for k in ['hand','party','enemies','round_number','phase']}
                        page.reload()
                        wait("window.umbralState.screen === 'menu'", 90000)
                        click('menu.continue')
                        wait("window.umbralState.screen === 'battle'")
                        settled()
                        check({k:state()[k] for k in saved} == saved, 'Continue restores exact committed hand, roster, enemies and round')
                        shot(branch + '-continue')
                        reloaded = True
                elif step['action'] == 'replacement':
                    wait("window.umbralState.screen === 'ko_replacement'")
                    for swap in step['swaps']:
                        reserves = sorted([u for u in state()['party'] if u['slot'] < 0 and u['hp'] > 0], key=lambda u:u['uid'])
                        index = next(i for i,u in enumerate(reserves) if u['uid'] == swap['in_uid'])
                        click('ko.' + str(swap['slot']) + '.' + str(index))
                    click('ko.finish'); settled()
                    check(actors_match(state()['party'], step['party_after']), 'KO replacement matches native roster')
                else:
                    wait("window.umbralState.screen === 'reward'")
                    before = state()['party']
                    click('reward.' + str(step['index']))
                    if step['offer']['kind'] == 'capture':
                        wait("window.umbralState.screen === 'capture_destination'")
                        shot(branch + '-capture-destination')
                        click('capture.reserve')
                        available_slot = next(i for i in range(3) if not state()['controls']['capture.slot.' + str(i)]['disabled'])
                        click('capture.slot.' + str(available_slot))
                        key('Escape')
                        wait("window.umbralState.screen === 'reward'")
                        check(state()['party'] == before, 'Field and Reserve inspection followed by cancel preserves roster')
                        capture_cancelled = True
                        click('reward.' + str(step['index']))
                        click('capture.reserve' if step['capture_slot'] < 0 else 'capture.slot.' + str(step['capture_slot']))
                        click('capture.confirm')
                    wait("window.umbralState.screen === 'map'")
                    map_check()
                    check(state()['checkpoint_status'] == 'ok', 'Reward checkpoint is saved')
                    check(actors_match(state()['expedition']['party'], step['party_after']), 'Reward returns to map with exact native roster and HP')
                    check(nodes()[state()['expedition']['current_node_id']]['completed'], 'Completed encounter cannot be entered twice')
                    if state()['expedition']['current_node_id'] == 'clearing': shot(branch + '-branch-choice')
                    if state()['expedition']['current_node_id'] == 'thicket':
                        check(nodes()['spring']['locked'] and nodes()['thicket']['completed'], 'Combat branch completes once and locks rest')
                        shot('thicket-completed-map')
            check(capture_cancelled and reloaded, branch + ' exercised capture cancellation and checkpoint reload')
            check(state()['expedition']['phase'] == plans[branch]['outcome'], branch + ' reaches native boss outcome')
            shot(branch + '-result')
            check(state()['checkpoint_status'] == 'cleared', 'Terminal checkpoint is retired after saving the result')
            stats_before = state()['stats']
            click('result.menu')
            wait("window.umbralState.screen === 'menu'")
            page.reload()
            wait("window.umbralState.screen === 'menu'", 90000)
            check(state()['controls']['menu.continue']['disabled'], 'Completed expedition cannot be resumed after reload')
            check(state()['stats'] == stats_before, 'Reload does not duplicate the terminal result')
        load()
        replay('thicket')
        replay('spring')
        for width, height in [(800, 600), (1600, 900)]:
            page.set_viewport_size({'width':width, 'height':height})
            click('menu.settings'); click('settings.large_text'); key('Escape')
            start_run()
            map_check()
            for identity in ['map.confirm', 'map.pause']:
                control = state()['controls'][identity]
                logical = state()['logical_size']
                check(control['visible'] and 0 <= control['cx'] <= logical[0] and 0 <= control['cy'] <= logical[1], f'{identity} remains visible at {width}×{height} with large text')
            shot(f'map-large-{width}x{height}')
            click('map.pause'); click('pause.menu'); click('confirm.yes')
            click('menu.settings'); click('settings.large_text'); key('Escape')
        check(not any('Could not persist run statistics' in x['text'] for x in logs), 'Terminal statistics persisted without a save warning')
        check(not errors, 'No uncaught browser errors')
        check(not [x for x in logs if 'SCRIPT ERROR:' in x['text'] or x['text'].startswith('ERROR:')], 'No Godot runtime errors')
        browser.close()
except Exception as exception:
    failure = str(exception)
    try:
        page.screenshot(path=str(OUT / 'failure.png'))
        (OUT / 'failure-state.json').write_text(json.dumps(state(), indent=2, ensure_ascii=False))
    except Exception: pass
    raise
finally:
    server.shutdown()
    (OUT / 'browser-console.json').write_text(json.dumps(logs, indent=2, ensure_ascii=False))
    report = {'suite':'umbral_expedition_browser', 'checks':len(checks), 'failed':int(failure is not None), 'failure':failure, 'passed':checks, 'captures':captures, 'chromium':globals().get('browser_version'), 'seconds':round(time.monotonic()-start, 2), 'limits':['Software WebGL; captures require visual review.', 'Synthetic touchscreen and keyboard; physical devices are not tested.']}
    (OUT / 'browser-report.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print(json.dumps({k:report[k] for k in ['suite','checks','failed','failure','seconds']}, ensure_ascii=False))
