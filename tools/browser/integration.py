"""Full production-route regression. Original assertions retained; layout runs independently."""
import json
import math
import time


def run(session):
    page, plans = session.page, session.plans
    state, wait, settled, load = session.state, session.wait, session.settled, session.load
    key, back, click, shot = session.key, session.back, session.click, session.shot
    check, geometry, clear_selection, start = session.check, session.geometry, session.clear_selection, session.start
    OUT, captures, started = session.output, session.captures, session.started
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
        nonlocal illegal_tested, impact_tested, signature_seen
        check(state()['party'] == plan['initial_party'], 'Seeded species/forms/passives survive the actual Web export')
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
    load()
    check(state()['stats']['wins']==1, 'Statistics persist through a browser reload')
    start()
    execute(plans['replacement'], primary=False)
    check(state()['screen']=='battle' and state()['encounter']==2, 'Alternative capture path resumes with a rebuilt team')
    click('hud.pause'); click('pause.menu'); click('confirm.yes')

    # A separate real-input run exercises items without changing deterministic victory plans.
    start()
    first = plans['primary']['plan'][0]
    for index in first['indices']:
        click('hand.' + str(index))
    original_damage = state()['preview']['damage']
    click('hud.inventory')
    geometry('Inventory before equipment')
    check(state()['controls']['inventory.use.1']['disabled'], 'Full-health tonic is visibly unavailable')
    click('inventory.equip.2.1')
    check(state()['inventory'][1]['equipped_uid'] == 1, 'Real input equips relic to stable individual UID')
    shot('15-inventory-equipped')
    back('battle')
    check(state()['focused'] == 'hud.inventory', 'Bag restores opener focus')
    check(state()['preview']['damage'] == original_damage + 2, 'Equipped relic contributes once to preview')
    click('hud.cast')
    settled()
    check(state()['history'] and any(event['source_id'] == 'ember_charm' for event in state()['history']), 'Committed history attributes relic damage')
    click('hud.inventory')
    before_item = state()
    check(not before_item['controls']['inventory.use.1']['disabled'], 'Wounded team can use tonic')
    click('inventory.use.1')
    check(state()['hp'] == 40 and state()['inventory'][0]['quantity'] == 0, 'Real input applies and consumes one tonic')
    check(state()['plays'] == before_item['plays'] and state()['burn'] == before_item['burn'], 'Tonic preserves round and burn clocks')
    check(state()['controls']['inventory.use.1']['disabled'], 'Consumed tonic cannot be reused')
    shot('16-inventory-consumed')
    click('inventory.remove.2')
    check(state()['inventory'][1]['equipped_uid'] == -1, 'Real input unequips relic')
    back('battle')
    click('hud.pause'); click('pause.menu'); click('confirm.yes')

