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
            original_name = name
            suffix = 2
            while (OUT / (name + '.png')).exists():
                name = original_name + '-' + str(suffix)
                suffix += 1
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

        def actors_match(observed, expected):
            fields = ['status_sources', 'resistances', 'uid', 'species', 'passive', 'name', 'art', 'slot', 'hp', 'max_hp', 'stage', 'attack', 'defense', 'speed', 'block', 'statuses', 'can_act_round']
            return len(observed) == len(expected) and all(
                all(a.get(field) == b.get(field) for field in fields)
                for a,b in zip(observed, expected))

        def clear_selection():
            for index in list(state()['selected']):
                key(str(index + 1))

        starter_choice_seen = False

        def start(species='ember'):
            global starter_choice_seen
            click('menu.practice')
            wait("window.umbralState.screen === 'starter'")
            geometry('Starter choice')
            if not starter_choice_seen:
                shot('04b-starter-choice')
                starter_choice_seen = True
            click('starter.' + species)
            wait("window.umbralState.screen === 'battle' && window.umbralState.hand.length === 6")
            settled()

        load()
        check(state()['focused'] == 'menu.play', 'Title opens with clear initial focus')
        geometry('Title')
        shot('01-menu')
        key('ArrowDown')
        check(state()['focused'] == 'menu.practice', 'Arrow keys navigate from expedition to practice')
        key('ArrowDown')
        check(state()['focused'] == 'menu.codex', 'Arrow keys continue to the codex')
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
        # Reload before screenshots or delays can hide an asynchronous save race.
        load()
        check(state()['preferences']['reduced_motion'] and state()['preferences']['large_text'], 'Accessibility preferences persist after reload')
        check(math.isclose(state()['preferences']['music'], before_volume + .05, abs_tol=.001), 'Volume preference persists after reload')
        click('menu.settings')
        shot('03-options-large')
        click('settings.reduced_motion')
        click('settings.large_text')
        load()
        check(not state()['preferences']['reduced_motion'] and not state()['preferences']['large_text'], 'Disabling accessibility preferences also survives a rapid reload')
        click('menu.settings')
        back('menu')
        click('menu.help')
        wait("window.umbralState.screen === 'help'")
        shot('04-guide')
        back('menu')
        start()
        initial_party = state()['party']
        check(len(initial_party) == 1 and initial_party[0]['slot'] == 1 and all('power' in c and 'rank' not in c for c in state()['hand']), 'Menu starts one active Umbral with its owned powers')
        shot('05-battle')
        before_id = state()['controls']['hand.0']['instance_id']
        for value in ['1','2','3','4']:
            key(value)
        check(len(state()['selected']) >= 3, 'Keyboard selects owned power instances')
        check(state()['controls']['hand.0']['instance_id'] == before_id, 'Selection preserves card nodes and focus infrastructure')
        key('1')
        check(0 not in state()['selected'], 'Keyboard deselects a power')
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
        click('settings.info.hidden')
        geometry('Options above selected cards')
        shot('07-options-over-combat')
        back('pause')
        check(state()['screen'] == 'pause', 'Back from nested options returns to pause')
        back('battle')
        check(state()['screen'] == 'battle' and state()['selected'] == snapshot['selected'], 'Resume preserves selected powers')
        key('c')
        check(state()['screen'] == 'inspect', 'A focused power can be inspected')
        shot('08-inspection')
        back('battle')
        commands_before = state()
        key('p')
        check(state()['screen'] == 'plan', 'Plan shortcut opens a player-only command editor')
        geometry('Player command editor')
        shot('08b-plan-editor')
        selected_index = commands_before['selected'][0]
        click('plan.remove.power.' + str(selected_index))
        check(selected_index not in state()['selected'] and state()['screen'] == 'plan', 'A single command can be removed without closing the editor')
        check(state()['hand'] == commands_before['hand'] and state()['actions'] == commands_before['actions'], 'Command editing preserves the hand and round')
        click('plan.clear')
        check(not state()['selected'] and not state()['queued_items'] and not state()['queued_swaps'], 'Clear plan removes every pending command')
        back('battle')
        click('hud.discard')
        geometry('Discard inspection')
        shot('08c-discard-inspection')
        back('battle')
        before = state()
        click('hud.redraw')
        settled()
        check(state()['actions'] == before['actions'] + 1 and state()['round_number'] == before['round_number'] + 1, 'Reroll consumes a complete round')
        check(state()['information_mode'] == 'hidden' and all(i['category'] == 'unknown' and 'damage' not in i and 'target_slot' not in i for i in state()['intents']),
              'Hidden information takes effect next round and exposes no damage or target')
        check(sum(e['hp'] for e in state()['enemies']) == sum(e['hp'] for e in before['enemies']), 'Reroll deals no damage to enemies')
        check(sum(u['hp'] for u in state()['party']) < sum(u['hp'] for u in before['party']), 'Reroll allows the normal announced enemy response')
        clear_selection()
        inventory_before = state()['inventory'].copy()
        party_before = state()['party']
        round_before = state()['round_number']
        click('hud.backpack')
        check(state()['inventory'] == inventory_before and state()['round_number'] == round_before,
              'Opening the backpack costs no items or round')
        shot('08a-backpack')
        click('pouch.potion.0')
        check(state()['party'] == party_before and state()['inventory'] == inventory_before,
              'Planning a potion does not heal or consume it before Conjurar')
        check(state()['preview']['actions'] == 1 and state()['queued_items'], 'A potion reserves one shared action')
        click('hud.plan')
        shot('08e-plan-item')
        click('plan.remove.item.0')
        check(not state()['queued_items'] and state()['inventory'] == inventory_before and state()['party'] == party_before,
              'Removing a planned item preserves stock and individual HP')
        back('battle')
        click('hud.backpack')
        click('pouch.potion.0')
        click('hud.cast')
        settled()
        check(state()['inventory']['potion'] == inventory_before['potion'] - 1 and state()['party'][0]['hp'] > party_before[0]['hp'],
              'Conjurar applies healing to the individual and spends one potion')
        abandon_before = state()
        click('hud.pause')
        click('pause.menu')
        check(state()['screen'] == 'confirm_menu', 'Leaving an ongoing expedition requires an explicit confirmation')
        back('pause')
        check(state()['screen'] == 'pause' and all(state()[field] == abandon_before[field]
              for field in ['hand','party','actions','plays','hp','selected','intents']),
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
        evolution_seen = False
        reserve_tested = False
        modes_tested = False
        targets_tested = False
        three_seen = False
        reactions_seen = set()
        seed_inspected = False
        history_tested = False

        def configure_modes():
            global modes_tested
            click('hud.pause'); click('pause.settings')
            for mode in ['hidden', 'full', 'partial']:
                click('settings.info.' + mode)
                check(state()['pending_information_mode'] == mode, 'Information mode queues the requested next-round setting: ' + mode)
            back('pause'); back('battle')
            modes_tested = True

        configure_modes()

        def execute(plan, primary=True):
            global illegal_tested, impact_tested, evolution_seen, reserve_tested, targets_tested, three_seen, seed_inspected, history_tested
            for step in plan['plan']:
                if step['action'] == 'play':
                    settled()
                    for target in step.get('targets', []):
                        index = target['index']
                        if state()['hand'][index].get('target_slot') == target['slot']:
                            continue
                        click('hand.' + str(index))
                        click(('party.' if target.get('side', 'enemy') == 'ally' else 'enemy.') + str(target['slot']))
                        click('hand.' + str(index))
                    check(state()['hand'] == step['hand'], 'Visible hand matches deterministic rule state')
                    if primary and not targets_tested and state()['encounter'] == 1:
                        card_index = next(i for i,c in enumerate(state()['hand']) if c['power'] == 'fireball')
                        original_slot = state()['hand'][card_index]['target_slot']
                        other_slot = next(e['slot'] for e in state()['enemies'] if e['hp'] > 0 and e['slot'] != original_slot)
                        click('hand.' + str(card_index))
                        click('enemy.' + str(other_slot))
                        check(state()['hand'][card_index]['target_slot'] == other_slot,
                              'Clicking another opponent changes the selected individual power target')
                        key('q')
                        check(state()['hand'][card_index]['target_slot'] == original_slot, 'Target shortcut cycles past empty positions')
                        click('hud.plan')
                        click('plan.target.' + str(card_index))
                        # PopupMenu consumes keys in its own Window before main._input.
                        # Acknowledge the actual target selection rather than root input.
                        shot('08d-plan-target-popup')
                        page.keyboard.press('ArrowDown')
                        page.keyboard.press('Enter')
                        wait('window.umbralState.hand[' + str(card_index) + '].target_slot === ' + str(other_slot))
                        geometry('Target selector in player plan')
                        shot('08d-plan-target-selector')
                        back('battle')
                        click('enemy.' + str(original_slot))
                        click('hand.' + str(card_index))
                        check(state()['hand'] == step['hand'] and not state()['selected'],
                              'Target planning can be restored without committing an action')
                        targets_tested = True
                    if primary and step['illegal_indices'] and not illegal_tested and not step['swaps']:
                        for index in step['illegal_indices']:
                            click('hand.' + str(index))
                        check(not state()['preview']['valid'] and state()['preview']['actions'] > 3, 'Over-budget selection communicates its action cost')
                        shot('09-action-error')
                        before = state()
                        key('Space')
                        check(state()['actions'] == before['actions'] and state()['hand'] == before['hand'], 'Rejected cast has no side effects')
                        clear_selection()
                        illegal_tested = True
                    for swap in step['swaps']:
                        reserve = next(index for index,u in enumerate(sorted([u for u in state()['party'] if u['slot'] < 0 and u['hp'] > 0], key=lambda u:u['uid'])) if u['uid'] == swap['in_uid'])
                        before_party = state()['party']
                        click('reserve.' + str(reserve))
                        wait("window.umbralState.screen === 'swap'")
                        shot('14-reserve-planning')
                        click('swap.slot.' + str(swap['slot']))
                        wait("window.umbralState.screen === 'battle'")
                        check(state()['party'] == before_party, 'Planning reserve entry waits for Conjurar')
                        if primary and not reserve_tested:
                            click('hud.plan')
                            shot('14a-plan-reserve')
                            click('plan.remove.swap.' + str(swap['slot']))
                            check(not state()['queued_swaps'] and state()['party'] == before_party,
                                  'Removing a planned entry preserves the original bodies and card cycle')
                            back('battle')
                            click('reserve.' + str(reserve))
                            click('swap.slot.' + str(swap['slot']))
                        reserve_tested = True
                    for index in step['indices']:
                        click('hand.' + str(index))
                    check(state()['preview']['damage'] == step['damage'] and state()['preview']['actions'] == step['cost'], 'Preview matches owned power effects and shared action cost')
                    if primary and not history_tested:
                        check(any(c['visible'] and '→' in c.get('text', '') for k,c in state()['controls'].items() if k.startswith('hud.command.')), 'The own-command strip keeps actors and target slots visible before commitment')
                        shot('08e-visible-own-commands')
                    if primary and state()['encounter'] == 2 and not evolution_seen:
                        shot('12-evolved-boss')
                        evolution_seen = any(u['stage'] == 2 for u in state()['party'])
                    before = state()
                    if step.get('reroll'):
                        click('hud.redraw')
                    else:
                        page.keyboard.press('Space')
                        wait('window.umbralState.busy')
                        if primary and not impact_tested:
                            page.keyboard.press('Space')
                            check(state()['actions'] == before['actions'] + 1, 'Impact feedback cannot double-cast')
                            displayed = lambda snapshot: {key: [value['card_instance'], value['chosen'], value['blocked']] for key,value in snapshot['controls'].items() if key.startswith('hand.')}
                            check(displayed(state()) == displayed(before), 'Committed cards keep their identity, selection and owner state during impact feedback')
                            page.wait_for_timeout(170)
                            page.screenshot(path=str(OUT / '10-cast-feedback.png'))
                            (OUT / '10-cast-feedback.state.json').write_text(json.dumps(state(),indent=2,ensure_ascii=False))
                            captures.append({'name':'10-cast-feedback','file':'10-cast-feedback.png','screen':state()['screen'],'viewport':page.viewport_size,'seconds':round(time.monotonic()-started,3)})
                            impact_tested = True
                    settled()
                    if primary and not history_tested and state()['screen'] == 'battle':
                        history_before = [state()['party'], state()['hand'], state()['round_number']]
                        click('hud.history')
                        geometry('Last-round recap')
                        shot('10b-last-round-recap')
                        back('battle')
                        check([state()['party'], state()['hand'], state()['round_number']] == history_before, 'Reading the last round does not change combat or draw cards')
                        history_tested = True
                    if not seed_inspected and state()['screen'] == 'battle':
                        seeded = next((e for e in state()['enemies'] if e['hp'] > 0 and e['statuses'].get('seed', 0) > 0), None)
                        if seeded:
                            click('enemy.' + str(seeded['slot']))
                            geometry('Seed duration and original source inspection')
                            shot('17b-seed-source-inspection')
                            back('battle')
                            seed_inspected = True
                    for reaction in state()['resolved_reactions']:
                        if reaction['reaction'] not in reactions_seen:
                            reactions_seen.add(reaction['reaction'])
                            shot('17-reaction-' + reaction['reaction'])
                    if not primary and not three_seen and state()['encounter'] == 2 and len([u for u in state()['party'] if u['slot'] >= 0 and u['hp'] > 0]) == 3 and len([u for u in state()['enemies'] if u['hp'] > 0]) == 3:
                        shot('15-actual-three-vs-three')
                        inspected_hand = state()['hand']
                        inspected_round = state()['round_number']
                        eligible = [i for i in range(len(inspected_hand)) if not state()['controls']['hand.' + str(i)]['disabled']][:3]
                        for index in eligible:
                            click('hand.' + str(index))
                        click('hud.plan')
                        geometry('Three-versus-three command editor')
                        shot('16-trio-plan')
                        back('battle')
                        clear_selection()
                        check(state()['hand'] == inspected_hand and state()['round_number'] == inspected_round,
                              'Reviewing a multi-owner plan during 3x3 preserves the actual route')
                        three_seen = True
                    check(actors_match(state()['party'], step['party_after']) and actors_match(state()['enemies'], step['enemies_after']) and state()['phase'] == step['phase_after'], 'Animated speed queue resolves the same individual actors and outcome')
                    if primary:
                        check(state()['feedback']['particles'] <= 64 and state()['audio']['voice_pool'] == 4, 'Feedback uses bounded particle and audio pools')
                        check(state()['feedback']['hits'] >= before['feedback']['hits'], 'Damage feedback counters remain monotonic')
                elif step['action'] == 'ko_replacement':
                    wait("window.umbralState.screen === 'ko_replacement'")
                    for swap in step['swaps']:
                        reserves = sorted([u for u in state()['party'] if u['slot'] < 0 and u['hp'] > 0], key=lambda u:u['uid'])
                        index = next(i for i,u in enumerate(reserves) if u['uid'] == swap['in_uid'])
                        click('ko.' + str(swap['slot']) + '.' + str(index))
                    click('ko.finish')
                    settled()
                    if not primary and not three_seen and state()['encounter'] == 2 and len([u for u in state()['party'] if u['slot'] >= 0 and u['hp'] > 0]) == 3 and len([u for u in state()['enemies'] if u['hp'] > 0]) == 3:
                        shot('15-actual-three-vs-three')
                        three_seen = True
                    check(actors_match(state()['party'], step['party_after']), 'Free post-KO replacement preserves the chosen roster identity')
                else:
                    wait("window.umbralState.screen === 'reward'")
                    check(state()['phase'] == 'reward', 'Clear opens capture/evolution')
                    if primary:
                        shot('11-capture' if step['offer']['kind']=='capture' else '11-evolution')
                    click('reward.' + str(step['index']))
                    if step['offer']['kind'] == 'capture':
                        wait("window.umbralState.screen === 'capture_destination'")
                        geometry('Capture destination')
                        if primary:
                            shot('11b-capture-destination')
                            before_cancel = state()['party']
                            back('reward')
                            check(state()['party'] == before_cancel, 'Canceling the capture destination leaves the roster unchanged')
                            click('reward.' + str(step['index']))
                            wait("window.umbralState.screen === 'capture_destination'")
                        destination = step.get('capture_slot', -1)
                        click('capture.reserve' if destination < 0 else 'capture.slot.' + str(destination))
                        click('capture.confirm')
                    wait("window.umbralState.screen === 'battle'")
                    settled()
                    check(actors_match(state()['party'], step['party_after']), 'Reward preserves the offered identity and passive')
                    if step['offer']['kind']=='evolve':
                        all_cards=state()['hand']+state()['deck']+state()['discard']
                        check(len({c['instance_id'] for c in all_cards})==len(all_cards), 'Evolution preserves unique learned copies')
                        check(state()['party'][0]['passive']==initial_party[0]['passive'], 'Evolution preserves the individual passive')

        execute(plans['primary'])
        check(impact_tested and evolution_seen and reserve_tested and modes_tested and illegal_tested and targets_tested and history_tested, 'The run covers animated impact, capture, reserve planning, evolution, targeting, rejected actions, configurable information and round recap')
        check(state()['screen']=='victory' and state()['stats']['wins']==1 and state()['stats']['runs']==1, 'Complete animated victory records statistics exactly once')
        shot('13-victory')
        page.wait_for_timeout(650)
        check(state()['feedback']['trauma']==0, 'Shake returns to rest')
        load()
        check(state()['stats']['wins']==1, 'Statistics persist through a browser reload')
        start()
        execute(plans['replacement'], primary=False)
        check(three_seen, 'An actual three-versus-three battle was reached through legal reserve deployment')
        check(state()['phase'] == plans['replacement']['outcome'], 'Alternative capture path reaches its actual planned outcome')
        click('result.menu')
        wait("window.umbralState.screen === 'menu'")

        # New mechanics are exercised through starter selection, captures and legal commands.
        start('moss')
        sowing = next(i for i,c in enumerate(state()['hand']) if c['power'] == 'sowing')
        check(state()['controls']['hand.' + str(sowing)]['nature'] == 'forest', 'Semeadura displays its own Bosque nature')
        click('hand.' + str(sowing)); key('c')
        geometry('Semeadura inspection')
        shot('18-sowing-inspection')
        back('battle'); clear_selection()
        execute(plans['elemental'], primary=False)
        check(seed_inspected and {'sprouting','bloom','wildfire'} <= reactions_seen, 'Legal Musgo route executes Brotação, Floração and Incêndio')
        check(state()['phase'] == plans['elemental']['outcome'], 'Elemental route matches its actual terminal outcome')
        shot('19-elemental-outcome')
        click('result.menu')
        start('volt')
        interference = next(i for i,c in enumerate(state()['hand']) if c['power'] == 'interference')
        check('Eletrificado' in state()['controls']['hand.' + str(interference)]['effect_text'], 'Electrical control explains Eletrificado before committing')
        click('hand.' + str(interference)); key('c')
        geometry('Interferência inspection')
        shot('20-interference-inspection')
        back('battle'); clear_selection()
        execute(plans['electric'], primary=False)
        check('conduction' in reactions_seen and plans['electric']['control_seen'], 'Faísca route exercises Interferência and Condução after capturing Orvalho')
        shot('21-electric-combination')
        click('hud.pause'); click('pause.menu'); click('confirm.yes')

        if not args.no_matrix:
            profiles = contracts['viewports']
            for width,height in profiles:
                page.set_viewport_size({'width':width,'height':height})
                page.wait_for_timeout(250)
                load()
                meta=geometry(f'Menu {width}×{height}')
                shot(f'matrix-menu-{width}x{height}')
                click('menu.practice')
                geometry(f'Starter {width}×{height}')
                shot(f'matrix-starter-{width}x{height}')
                back('menu')
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
                key('c')
                geometry(f'Large effect inspection {width}×{height}')
                shot(f'matrix-inspect-{width}x{height}')
                back('battle')
                shot(f'matrix-large-battle-{width}x{height}')
                click('hud.plan')
                geometry(f'Large plan {width}×{height}')
                shot(f'matrix-large-plan-{width}x{height}')
                back('battle')
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
    report={'suite':'umbral_ui_experience','version':version,'chromium':globals().get('browser_version'),'checks':len(checks),'failed':int(failure is not None),'failure':failure,'passed':checks,'outcome':'victory' if failure is None else 'failed','matrix':matrix,'matrix_requested':not args.no_matrix,'matrix_executed':len(matrix)==len(contracts['viewports']),'captures':captures,'reactions_seen':sorted(globals().get('reactions_seen', [])),'seconds':round(time.monotonic()-started,2),'limits':['software WebGL rendering','synthetic Godot gamepad events are separate from physical controller testing','beauty, fun and full accessibility require review','full-roster capture replacement is validated by numerical fixture, not this three-encounter browser run']}
    (OUT / 'browser-report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
    print(json.dumps({k:v for k,v in report.items() if k in ['suite','version','checks','failed','failure','outcome','seconds']},ensure_ascii=False))
