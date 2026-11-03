"""Focused real-input inventory scenario."""
from .common import focus

def run(s):
    fixture = s.args.fixture or 'wounded'
    s.fixture(fixture); s.large_text()
    if fixture == 'inventory_full':
        s.click('hud.inventory')
        expected = [key for key in s.state()['focus_order'] if key.startswith('inventory.') and not s.state()['controls'][key]['disabled']]
        for identity in expected:
            focus(s, identity)
        s.geometry('Scrollable inventory', scrollable=True)
        s.shot('inventory-full-last-focus')
        s.check(len(expected) > 10, 'Full inventory exercises more than ten controls')
        return
    card_index = next(i for i, card in enumerate(s.state()['hand']) if card['owner'] == 1 and card['power'] == 'fireball')
    s.click('hand.' + str(card_index))
    base_damage = s.state()['preview']['damage']
    s.click('hud.inventory'); s.geometry('Inventory')
    before = s.state()
    s.click('inventory.equip.2.1')
    s.check(s.state()['inventory'][1]['equipped_uid'] == 1, 'Relic equips to stable UID')
    s.click('inventory.use.1')
    s.check(s.state()['hp'] == 40 and s.state()['inventory'][0]['quantity'] == 0, 'Tonic applies capped healing and spends one dose')
    s.check(s.state()['plays'] == before['plays'] and s.state()['burn'] == before['burn'], 'Item preserves round/status clocks')
    s.check(s.state()['controls']['inventory.use.1']['disabled'], 'Exhausted tonic is disabled')
    s.shot('inventory-consumed')
    s.back('battle')
    s.check(s.state()['focused'] == 'hud.inventory', 'Bag restores opener focus')
    s.check(s.state()['preview']['damage'] == base_damage + 2, 'Relic modifies projection once')
    s.click('hud.cast'); s.settled()
    s.check(any(event['source_id'] == 'ember_charm' for event in s.state()['history']), 'Relic damage appears in committed events')
    s.click('hud.inventory'); s.click('inventory.remove.2')
    s.check(s.state()['inventory'][1]['equipped_uid'] == -1, 'Relic can return to bag')

