"""Focused current-product combat scenario."""
def run(s):
    s.fixture(s.args.fixture or 'battle')
    i = next(i for i,c in enumerate(s.state()['hand']) if c['power'] == 'fireball')
    s.click('hand.' + str(i)); before = s.state(); s.geometry('Preview'); s.shot('combat-preview')
    s.page.keyboard.press('Space'); s.wait('window.umbralState.busy'); s.page.keyboard.press('Space')
    s.check(s.state()['actions'] == before['actions'] + 1, 'Busy input cannot double-commit a round')
    s.settled(); after = s.state()
    s.check(after['round_number'] == before['round_number'] + 1, 'One committed round advances once')
    if s.args.fixture == 'enemy_shield':
        s.check(after['enemies'][0]['hp'] == before['enemies'][0]['hp'], 'Enemy shield absorbs direct damage')
    else:
        s.check(after['enemy_hp'] < before['enemy_hp'], 'Applied attack reduces enemy HP')
    s.shot('combat-settled')
