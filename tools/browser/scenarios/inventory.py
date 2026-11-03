"""Focused current-product inventory scenario."""
def run(s):
    s.fixture(s.args.fixture or 'wounded')
    before = s.state(); target = before['party'][0]
    s.click('hud.backpack'); s.wait("window.umbralState.screen === 'pouch'")
    s.geometry('Pouch', scrollable=True); s.shot('pouch')
    s.click('pouch.potion.0'); s.wait("window.umbralState.screen === 'battle'")
    planned = s.state()
    s.check(planned['inventory'] == before['inventory'] and planned['party'] == before['party'], 'Queuing potion does not consume or heal')
    s.check(len(planned['queued_items']) == 1, 'Potion enters the shared action plan')
    s.click('hud.cast'); s.settled()
    after = s.state(); unit = next(u for u in after['party'] if u['uid'] == target['uid'])
    s.check(after['inventory']['potion'] == before['inventory']['potion'] - 1, 'Committed potion consumes one dose')
    s.check(unit['hp'] > target['hp'], 'Potion heals through the collective resolver')
    s.shot('potion-committed')
