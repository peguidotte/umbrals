"""Focused current-product rewards scenario."""
def run(s):
    s.fixture(s.args.fixture or 'rewards_many')
    offers = s.state()['offers']; s.check(len(offers) >= 2, 'Real encounter produces capture/evolution offers')
    s.shot('rewards'); chosen = next(i for i,o in enumerate(offers) if o['kind'] == 'evolve')
    uid = offers[chosen]['uid']; before = next(u for u in s.state()['party'] if u['uid'] == uid)
    s.click('reward.' + str(chosen)); s.wait("window.umbralState.screen === 'map'")
    after = next(u for u in s.state()['party'] if u['uid'] == uid)
    s.check(after['passive'] == before['passive'] and after['stage'] == before['stage'] + 1, 'Evolution preserves UID/passive and returns to map')
    s.shot('reward-map')
