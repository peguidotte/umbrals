"""Focused real-input combat scenario."""

def run(s):
    fixture = s.args.fixture or 'battle'
    s.fixture(fixture); s.large_text()
    index = next(i for i, card in enumerate(s.state()['hand']) if card['owner'] == 1 and card['power'] == 'fireball')
    s.click('hand.' + str(index))
    before = s.state()
    s.geometry('Combat preview'); s.shot('combat-preview')
    s.page.keyboard.press('Space'); s.wait('window.umbralState.busy')
    s.page.keyboard.press('Space')
    s.check(s.state()['actions'] == before['actions'] + 1, 'Repeated cast cannot commit twice')
    s.settled()
    after = s.state()
    s.check(after['plays'] == before['plays'] - 1, 'One cast spends one round')
    s.check(any(event['source_uid'] == 1 and event['source_id'] == 'fireball' for event in after['history']), 'Events preserve selected power source')
    if fixture == 'enemy_shield':
        s.check(after['enemy_hp'] == 1 and after['phase'] == 'battle', 'Shield defeats a lethal raw-damage prediction')
        s.check(any(event['blocked'] > 0 for event in after['history']), 'Absorption appears in committed events')
    else:
        s.check(after['enemy_hp'] < before['enemy_hp'], 'Cast applies enemy damage')
        s.check(after['feedback']['hits'] > before['feedback']['hits'], 'Applied damage emits visual impact')
    s.page.wait_for_timeout(650)
    s.check(s.state()['feedback']['trauma'] == 0, 'Impact returns to rest')
    s.shot('combat-settled')

