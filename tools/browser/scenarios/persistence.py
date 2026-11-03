"""Focused current-product persistence scenario."""
def run(s):
    s.load(); s.click('menu.settings'); before = s.state()['preferences']['music']; s.key('ArrowRight')
    s.click('settings.large_text'); s.click('settings.reduced_motion'); expected = s.state()['preferences']
    s.check(expected['music'] != before, 'Keyboard adjusts volume'); s.load()
    s.check(s.state()['preferences'] == expected, 'Preferences survive immediate reload')
    s.click('menu.settings'); s.geometry('Restored settings'); s.shot('persisted-settings')
