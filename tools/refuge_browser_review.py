"""Real keyboard traversal; production bridge remains read-only."""
def depart(page, wait):
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    # Returning from departure requires leaving the threshold before re-entry.
    if not page.evaluate('window.umbralState.refuge.exit_ready'):
        page.keyboard.down('a')
        page.wait_for_timeout(550)
        page.keyboard.up('a')
    page.keyboard.down('d')
    try:
        wait("window.umbralState.screen === 'journey'", timeout=20000)
    finally:
        page.keyboard.up('d')


def review_room(page, state, wait, key, click, shot, check):
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    before = state()
    fields = ('hand', 'deck', 'discard', 'party', 'enemies', 'actions', 'stats', 'expedition', 'checkpoint_status')
    check(state()['focused'] == 'refuge.walk', 'Refuge gives movement initial focus')
    shot('refuge-main.png')
    page.keyboard.down('d')
    page.wait_for_timeout(1000)
    shot('refuge-walking-right.png')
    page.keyboard.up('d')
    page.keyboard.down('a')
    page.wait_for_timeout(1000)
    shot('refuge-walking-left.png')
    page.keyboard.up('a')
    key('Shift')
    def approach(target):
        for _ in range(90):
            x = state()['refuge']['position'][0]
            if abs(x-target) < 35: return
            page.keyboard.press('d' if x < target else 'a', delay=70)
            page.wait_for_timeout(120)
            key('Shift')
        raise AssertionError('Could not walk to station')
    approach(270)
    check(state()['refuge']['nearby'] == 'codex', 'Horizontal walking reaches reading station')
    shot('refuge-reading-desk.png')
    key('e')
    wait("window.umbralState.screen === 'codex'")
    stationary = state()['refuge']['position']
    page.keyboard.press('d', delay=300)
    key('Shift')
    check(state()['refuge']['position'] == stationary, 'Codex suspends locomotion')
    shot('refuge-codex.png')
    key('Escape')
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    check(state()['focused'] == 'refuge.walk', 'Closing codex restores walking focus')
    approach(1170)
    key('e')
    check('indisponíveis' in state()['refuge']['notice'], 'Future station makes no functional promise')
    shot('refuge-future-workbench.png')
    depart(page, wait)
    check(state()['controls']['journey.continue']['disabled'], 'Physical exit opens preparation without starting a new run')
    shot('refuge-departure.png')
    key('Escape')
    wait("window.umbralState.screen === 'refuge'")
    page.wait_for_timeout(500)
    check(state()['screen'] == 'refuge', 'Returning at the threshold does not reopen departure')
    check(all(before[f] == state()[f] for f in fields), 'Walking and consultations preserve gameplay and checkpoint fields')


def pointer_walk(page, state, wait, identity, expression, touch=False):
    """Hold an actual pointer on a movement control; never invoke game methods."""
    s = state()
    control = s['controls'][identity]
    canvas = page.locator('#canvas').bounding_box()
    x = canvas['x'] + control['cx'] / s['logical_size'][0] * canvas['width']
    y = canvas['y'] + control['cy'] / s['logical_size'][1] * canvas['height']
    client = page.context.new_cdp_session(page) if touch else None
    if touch:
        client.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': [{'x': x, 'y': y}]})
    else:
        page.mouse.move(x, y)
        page.mouse.down()
    try:
        wait(expression, timeout=20000)
    finally:
        if touch:
            client.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
            client.detach()
        else:
            page.mouse.up()
