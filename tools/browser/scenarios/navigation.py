"""Focused current-product navigation scenario."""
def run(s):
    s.load(); s.geometry('Title'); s.click('menu.codex')
    s.wait("window.umbralState.screen === 'codex'"); s.shot('codex')
    s.back('menu'); s.check(s.state()['focused'] == 'menu.codex', 'Codex restores opener')
    s.start(); before = s.state()['hand']
    s.click('hud.pause'); s.click('pause.settings'); s.geometry('Nested settings')
    s.shot('settings'); s.back('pause'); s.back('battle')
    s.check(s.state()['hand'] == before, 'Nested navigation preserves hand')
