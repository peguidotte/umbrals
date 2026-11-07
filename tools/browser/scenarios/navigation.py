"""Focused current-product navigation scenario."""
import json


def record_focus(s, description):
    snapshot = s.state()
    focused = snapshot['focused']
    control = snapshot['controls'].get(focused, {})
    s.check(focused.startswith('codex.') and control.get('active') and control.get('visible'),
            description + ': focus belongs to the active codex')


def record_links(s, suffix):
    s.click('menu.settings'); s.click('settings.codex')
    s.wait("window.umbralState.screen === 'codex'"); s.shot('codex' + suffix)
    stored = s.page.evaluate('JSON.stringify(Object.fromEntries(Object.entries(localStorage).sort()))')
    original_link = s.state()['controls']['codex.evolution']['text']
    s.click('codex.evolution')
    s.wait("window.umbralState.controls['codex.evolution'].text !== " + json.dumps(original_link))
    s.check(s.state()['focused'] == 'codex.section.story', 'Mouse form link focuses the destination reading tab')
    s.geometry('Evolved record', scrollable=True); s.shot('codex-evolution-focus' + suffix)
    count = sum(c['visible'] and c['active'] and not c['disabled'] for c in s.state()['controls'].values())
    for step in range(count + 1):
        s.key('Tab'); record_focus(s, 'Rebuilt record Tab cycle ' + str(step))
    s.key('Shift+Tab'); record_focus(s, 'Reverse Tab')
    s.back('codex')
    s.check(s.state()['focused'] == 'codex.evolution', 'Back from evolved record restores its originating form link')
    s.key('Enter')
    s.wait("window.umbralState.controls['codex.evolution'].text !== " + json.dumps(original_link))
    s.check(s.state()['focused'] == 'codex.section.story', 'Keyboard form link focuses the destination reading tab')
    s.back('codex'); s.click('codex.section.details')
    # Larger text puts powers below the record's clipped reading area. Reveal
    # the real target before clicking; registration alone does not mean on-screen.
    canvas = s.page.locator('#canvas').bounding_box()
    s.page.mouse.move(canvas['x'] + canvas['width'] * .85, canvas['y'] + canvas['height'] * .7)
    s.page.mouse.wheel(0, 500)
    s.key('Tab')
    s.wait("window.umbralState.focused === 'codex.related.fireball'")
    s.settled()
    visible = s.state()['controls']
    s.check(visible['codex.related.fireball']['cy'] < visible['codex.back']['y'] - 20,
            'Related power is revealed above the clipped panel boundary before the real click')
    s.click('codex.related.fireball')
    s.wait("window.umbralState.controls['codex.section.story'].text === 'Descrição'")
    s.check(s.state()['focused'] == 'codex.section.story', 'Related power focuses the destination description tab')
    s.key('Tab'); record_focus(s, 'Related power Tab')
    s.geometry('Related power', scrollable=True); s.shot('codex-power-focus' + suffix)
    s.back('codex')
    s.check(s.state()['focused'] == 'codex.related.fireball', 'Back from power restores its originating link')
    s.check(stored == s.page.evaluate('JSON.stringify(Object.fromEntries(Object.entries(localStorage).sort()))'),
            'Record navigation preserves the saved profile and checkpoints byte for byte')
    s.back('settings'); s.check(s.state()['focused'] == 'settings.codex', 'Codex restores Options opener'); s.back('menu')


def run(s):
    # Isolated saved-profile fixture, loaded through production Storage/CodexProgress.
    # It unlocks the two existing records; no game setters or catalog edits are used.
    knowledge = {'version': 1, 'umbrals': {'ember': True, 'ignivar': True},
                 'powers': {'fireball': True}, 'items': {}, 'passives': {}}
    s.context.add_init_script("localStorage.setItem('umbral.codex.v1', " + json.dumps(json.dumps(knowledge)) + ");")
    s.load(); s.geometry('Title')
    record_links(s, '')
    s.click('menu.settings'); s.click('settings.large_text')
    s.check(s.state()['preferences']['large_text'], 'Large text enabled through its real control')
    s.back('menu'); record_links(s, '-large')
    s.click('menu.settings'); s.click('settings.large_text'); s.back('menu')
    s.start(); before = s.state()['hand']
    s.click('hud.pause'); s.click('pause.settings'); s.geometry('Nested settings')
    s.shot('settings'); s.back('pause'); s.back('battle')
    s.check(s.state()['hand'] == before, 'Nested navigation preserves hand')
