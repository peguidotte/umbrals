"""Focused real-input rewards scenario."""
from .common import focus

def run(s):
    fixture = s.args.fixture or 'branching_rewards'
    s.fixture(fixture)
    s.check(s.state()['screen'] == 'reward', 'Reward fixture opens actual reward view')
    offers = s.state()['offers']
    s.check(len(offers) >= (4 if fixture == 'branching_rewards' else 3), 'Fixture exposes its independent reward offers')
    s.shot('rewards-branches')
    identity = 'reward.' + str(len(offers) - 1)
    focus(s, identity)
    s.geometry('Reward after horizontal focus', scrollable=True)
    s.shot('rewards-last-focus')
    chosen = offers[-1]
    before = next(unit for unit in s.state()['party'] if unit['uid'] == chosen['uid'])
    s.click(identity)
    s.wait("window.umbralState.screen === 'battle'")
    after = next(unit for unit in s.state()['party'] if unit['uid'] == chosen['uid'])
    s.check(after['passive'] == before['passive'] and after['form_id'] == chosen['target_form_id'], 'Chosen evolution preserves UID and passive')

