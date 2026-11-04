from refuge_browser_review import depart
"""Full current-main practice route, preserving every original assertion."""
import json
import math
import time

def run(session):
    page, plans = session.page, session.plans
    state, wait, settled, load = session.state, session.wait, session.settled, session.load
    key, back, click, shot = session.key, session.back, session.click, session.shot
    check, geometry, clear_selection, start = session.check, session.geometry, session.clear_selection, session.start
    OUT, captures, started = session.output, session.captures, session.started
    def actors_match(observed, expected):
        fields = ['status_sources', 'resistances', 'uid', 'species', 'passive', 'name', 'art', 'slot', 'hp', 'max_hp', 'form_id', 'attack', 'defense', 'speed', 'block', 'statuses', 'can_act_round']
        return len(observed) == len(expected) and all(
            all(a.get(field) == b.get(field) for field in fields)
            for a,b in zip(observed, expected))
    load()
    check(state()['focused'] == 'menu.play', 'Title opens with clear initial focus')
    geometry('Title')
    shot('01-menu')
    home = {k for k,c in state()['controls'].items() if c['visible'] and c['active'] and k.startswith('menu.')}
    check(home == {'menu.play', 'menu.codex', 'menu.settings', 'menu.help', 'menu.credits'}, 'Gold Web home has exactly five active choices')
    check(not any(k in state()['controls'] for k in ('menu.practice', 'menu.continue', 'menu.quit')), 'Home has no hidden legacy aliases')
    key('Enter')
    wait("window.umbralState.screen === 'refuge'")
    depart(session.page, wait)
    wait("window.umbralState.screen === 'journey'")
    geometry('Expedition choices')
    shot('01b-journey')
    back('refuge')
    back('menu')
    check(state()['focused'] == 'menu.play', 'Back from expedition choices restores Play focus')
    key('ArrowDown')
    check(state()['focused'] == 'menu.codex', 'Arrow keys navigate from Play to the codex')
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
    evolution_uid, evolution_target = None, None
    reserve_tested = False
    modes_tested = False
    targets_tested = False
    three_seen = False
    reactions_seen = set()
    seed_inspected = False
    history_tested = False

    def configure_modes():
        nonlocal modes_tested
        click('hud.pause'); click('pause.settings')
        for mode in ['hidden', 'full', 'partial']:
            click('settings.info.' + mode)
            check(state()['pending_information_mode'] == mode, 'Information mode queues the requested next-round setting: ' + mode)
        back('pause'); back('battle')
        modes_tested = True

    configure_modes()

    def execute(plan, primary=True):
        nonlocal evolution_uid, evolution_target, illegal_tested, impact_tested, evolution_seen, reserve_tested, targets_tested, three_seen, seed_inspected, history_tested
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
                    evolution_seen = any(u['uid'] == evolution_uid and u['form_id'] == evolution_target for u in state()['party'])
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
                if step['offer']['kind'] == 'evolve':
                    evolution_uid, evolution_target = step['offer']['uid'], step['offer']['target_form_id']
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


    session.reactions_seen = sorted(reactions_seen)
