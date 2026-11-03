"""Focused real-input navigation scenario."""

def run(s):
    s.load()
    s.check(s.state()['focused'] == 'menu.play', 'Title initial focus')
    s.geometry('Title')
    s.key('ArrowDown'); s.key('Enter')
    s.wait("window.umbralState.screen === 'codex'")
    s.geometry('Codex'); s.shot('navigation-codex')
    s.back('menu')
    s.check(s.state()['focused'] == 'menu.codex', 'Back restores menu opener')
    s.start()
    hand = s.state()['hand']
    s.click('hud.pause'); s.click('pause.settings')
    s.geometry('Nested settings'); s.shot('navigation-settings')
    s.back('pause'); s.back('battle')
    s.check(s.state()['hand'] == hand, 'Nested screens preserve hand')

