"""Real home traversal; the production bridge remains read-only."""

def depart(page, wait):
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed && !window.umbralState.refuge.waking")
    home = page.evaluate('window.umbralState.refuge')
    if home['room'] == 'mother' or home['on_stairs']:
        page.keyboard.down('s')
        try:
            wait("window.umbralState.refuge.room === 'kitchen' && !window.umbralState.refuge.on_stairs", timeout=30000)
        finally:
            page.keyboard.up('s')
    if page.evaluate("window.umbralState.refuge.room === 'kitchen'"):
        page.keyboard.down('a')
        try:
            wait("window.umbralState.refuge.room === 'living'", timeout=30000)
        finally:
            page.keyboard.up('a')
    if not page.evaluate('window.umbralState.refuge.exit_ready'):
        page.keyboard.down('a')
        try:
            wait("window.umbralState.refuge.position[0] < 1430", timeout=15000)
        finally:
            page.keyboard.up('a')
    page.keyboard.down('d')
    try:
        wait("window.umbralState.screen === 'journey'", timeout=30000)
    finally:
        page.keyboard.up('d')


def review_room(page, state, wait, key, click, shot, check):
    if state()["refuge"]["waking"]:
        shot("house-waking.png")
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    before = state()
    fields = ('hand', 'deck', 'discard', 'party', 'enemies', 'actions', 'stats', 'expedition', 'checkpoint_status')
    check(state()['focused'] == 'refuge.walk', 'Home gives walking initial focus')
    check(state()['refuge']['room'] == 'bedroom' and state()['refuge']['location'] == 'pietro_house', 'Initial home opens in Pietro bedroom, separate from portable shelter')
    shot('house-pietro-bedroom.png')
    click('refuge.living')
    check(state()['refuge']['room'] == 'bedroom', 'Distant bedroom door requires an actual walk')
    wait("window.umbralState.refuge.room === 'living'", 20000)
    shot('refuge-main.png')
    click('refuge.kitchen')
    wait("window.umbralState.refuge.room === 'kitchen'", 20000)
    shot('house-kitchen.png')
    review_stairs(page, state, wait, key, click, lambda name: shot('house-' + name + '.png'), check)
    click('refuge.living')
    wait("window.umbralState.refuge.room === 'living'", 20000)
    click('refuge.codex')
    wait("window.umbralState.screen === 'codex'", 20000)
    stationary = state()['refuge']['position']
    page.keyboard.press('d', delay=300)
    key('Shift')
    check(state()['refuge']['position'] == stationary, 'Codex suspends locomotion')
    shot('refuge-codex.png')
    key('Escape')
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    check(state()['focused'] == 'refuge.walk', 'Closing codex restores walking focus')
    click('refuge.improvements')
    wait("window.umbralState.refuge.notice.includes('indisponíveis')", 20000)
    shot('refuge-future-workbench.png')
    depart(page, wait)
    check(state()['controls']['journey.continue']['disabled'], 'Exterior exit opens preparation without starting a new run')
    shot('refuge-departure.png')
    key('Escape')
    wait("window.umbralState.screen === 'refuge'")
    page.wait_for_timeout(500)
    check(state()['screen'] == 'refuge', 'Returning at threshold does not reopen departure')
    check(all(before[f] == state()[f] for f in fields), 'All rooms, stairs and consultations preserve gameplay and checkpoint fields')


def point_walk(page, state, wait, target_x, expression, touch=False):
    """Click/tap actual floor and observe continuous walking, without setters."""
    s = state()
    canvas = page.locator('#canvas').bounding_box()
    room = s['refuge']
    logical_x = room['scene_origin'][0] + target_x * room['scene_scale']
    logical_y = room['scene_origin'][1] + 825 * room['scene_scale']
    x = canvas['x'] + logical_x / s['logical_size'][0] * canvas['width']
    y = canvas['y'] + logical_y / s['logical_size'][1] * canvas['height']
    if touch:
        page.touchscreen.tap(x, y)
    else:
        page.mouse.click(x, y)
    wait(expression, timeout=20000)


def responsive_home(session, width, height):
    """Inspect every real room at each contracted viewport, then leave in living."""
    wait, click, shot = session.wait, session.click, session.shot
    wait("window.umbralState.refuge.armed && !window.umbralState.refuge.waking")
    session.geometry(f'Pietro bedroom {width}×{height}')
    shot(f'matrix-house-bedroom-{width}x{height}')
    click('refuge.living')
    wait("window.umbralState.refuge.room === 'living'", timeout=20000)
    session.geometry(f'Living room {width}×{height}')
    shot(f'matrix-house-living-{width}x{height}')
    click('refuge.kitchen')
    wait("window.umbralState.refuge.room === 'kitchen'", timeout=20000)
    session.geometry(f'Kitchen {width}×{height}')
    shot(f'matrix-house-kitchen-{width}x{height}')
    def capture_stairs(name):
        if name == 'mother-bedroom':
            session.geometry(f'Mother bedroom {width}×{height}')
            shot(f'matrix-house-mother-{width}x{height}')
        else:
            shot(f'matrix-house-{name}-{width}x{height}')
    review_stairs(session.page, session.state, wait, session.key, click, capture_stairs, session.check)
    click('refuge.living')
    wait("window.umbralState.refuge.room === 'living'", timeout=20000)


def actor_margin(state, check, label):
    home = state()['refuge']
    x, y, w, h = home['actor_frame']
    ox, oy = home['scene_origin']
    scale = home['scene_scale']
    inset = 32 * scale
    check(x >= ox + inset - .5 and y >= oy + inset - .5
          and x+w <= ox + 1672*scale - inset + .5
          and y+h <= oy + 941*scale - inset + .5,
          'Full actor frame retains 32-reference-pixel room margin: ' + label)


def pause_stairs(page, wait):
    # A real horizontal movement input pauses both pointer and E approaches.
    page.keyboard.press('d', delay=80)
    wait("window.umbralState.refuge.on_stairs && window.umbralState.refuge.stair_automatic === 0", timeout=20000)


def review_stairs(page, state, wait, key, click, capture, check):
    click('refuge.stairs')
    wait("window.umbralState.refuge.on_stairs && window.umbralState.refuge.stair_progress >= .739", timeout=20000)
    pause_stairs(page, wait)
    up = state()['refuge']['stair_progress']
    actor_margin(state, check, 'paused ascent')
    capture('stair-ascent')
    key('e')
    wait(f"window.umbralState.refuge.room === 'mother' || window.umbralState.refuge.stair_progress > {up + .005}", timeout=20000)
    check(state()['refuge']['stair_direction'] == 1, 'E resumes a paused upper-half ascent in the same direction')
    wait("window.umbralState.refuge.room === 'mother'", timeout=20000)
    actor_margin(state, check, 'upstairs arrival')
    capture('mother-bedroom')
    click('refuge.stairs')
    wait("window.umbralState.refuge.room === 'kitchen' && window.umbralState.refuge.on_stairs", timeout=20000)
    pause_stairs(page, wait)
    actor_margin(state, check, 'upper descent; original hair-clipping case')
    capture('stair-descent')
    key('e')
    wait("window.umbralState.refuge.on_stairs && window.umbralState.refuge.stair_progress < .45", timeout=20000)
    pause_stairs(page, wait)
    down = state()['refuge']['stair_progress']
    click('refuge.stairs')
    wait(f"!window.umbralState.refuge.on_stairs || window.umbralState.refuge.stair_progress < {down - .005}", timeout=20000)
    check(state()['refuge']['stair_direction'] == -1, 'Click resumes a paused lower-half descent in the same direction')
    wait("!window.umbralState.refuge.on_stairs", timeout=20000)
    actor_margin(state, check, 'kitchen return')
