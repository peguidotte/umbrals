"""Focused real-input replacement scenario."""

def run(s):
    s.fixture('replacement')
    before = s.state()
    s.check(len(before['party']) == 3 and before['inventory'][1]['equipped_uid'] == 2, 'Fixture has a full team with equipment')
    s.click('reward.0'); s.wait("window.umbralState.screen === 'replacement'")
    s.geometry('Replacement'); s.shot('replacement-choice')
    s.back('reward')
    s.check(s.state()['party'] == before['party'] and s.state()['offers'] == before['offers'], 'Cancel preserves team and rolled offer')
    s.click('reward.0')
    index = next(i for i, unit in enumerate(s.state()['party']) if unit['uid'] == 2)
    s.click('replace.' + str(index)); s.wait("window.umbralState.screen === 'battle'")
    after = s.state()
    s.check(all(unit['uid'] != 2 for unit in after['party']), 'Explicit replacement releases selected UID')
    s.check(after['inventory'][1]['equipped_uid'] == -1, 'Released UID returns relic to bag')
    s.check(all(card['owner'] != 2 for card in after['hand'] + after['deck'] + after['discard']), 'Released owner leaves no powers')

