"""Focused current-product replacement scenario."""
def run(s):
    s.fixture('replacement'); before = s.state()
    s.check(len(before['party']) == 6, 'Replacement fixture uses the current six-member roster')
    s.click('reward.0'); s.wait("window.umbralState.screen === 'replacement'"); s.shot('replacement')
    s.back('reward'); s.check(s.state()['party'] == before['party'] and s.state()['offers'] == before['offers'], 'Cancel preserves rolled identity/team')
    s.click('reward.0'); s.click('replace.0'); s.wait("window.umbralState.screen === 'capture_destination'")
    s.click('capture.reserve'); s.click('capture.confirm'); s.wait("window.umbralState.screen === 'map'")
    s.check(all(u['uid'] != before['party'][0]['uid'] for u in s.state()['party']), 'Only confirmed replacement releases the selected UID')
    s.check(len(s.state()['party']) == 6, 'Replacement preserves the six-member cap')
