"""Real inputs in one continuous house; production bridge stays read-only."""


def walk_to(page, wait, x, key='d'):
    sign = '>' if key == 'd' else '<'
    page.keyboard.down(key)
    try:
        wait(f"window.umbralState.refuge.position[0] {sign} {x}", timeout=30000)
    finally:
        page.keyboard.up(key)
    page.wait_for_timeout(180)


def depart(page, wait):
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed && !window.umbralState.refuge.waking")
    home = page.evaluate('window.umbralState.refuge')
    if home['upper_floor'] or home['on_stairs']:
        if not home['on_stairs']:
            walk_to(page, wait, 2220)
        page.keyboard.down('s')
        try:
            wait("!window.umbralState.refuge.upper_floor && !window.umbralState.refuge.on_stairs", timeout=30000)
        finally:
            page.keyboard.up('s')
    if not page.evaluate('window.umbralState.refuge.exit_ready'):
        walk_to(page, wait, 3740, 'a')
    page.keyboard.down('d')
    try:
        wait("window.umbralState.screen === 'journey'", timeout=30000)
    finally:
        page.keyboard.up('d')


def actor_margin(state, check, label):
    home = state()['refuge']
    x, y, w, h = home['actor_frame']
    vw, vh = home['viewport']
    inset = 32 * home['scene_scale']
    check(x >= inset-.5 and y >= inset-.5 and x+w <= vw-inset+.5 and y+h <= vh-inset+.5,
          'Full actor frame retains camera margin: ' + label)


def review_room(page, state, wait, key, click, shot, check):
    if state()['refuge']['waking']:
        shot('house-waking.png')
    wait("window.umbralState.refuge.armed && !window.umbralState.refuge.waking")
    before = state()
    fields = ('hand', 'deck', 'discard', 'party', 'enemies', 'actions', 'stats', 'expedition', 'checkpoint_status')
    check(state()['focused'] == 'refuge.walk', 'Home gives walking initial focus')
    check(state()['refuge']['room'] == 'bedroom' and state()['refuge']['location'] == 'pietro_house', 'First entry wakes in initial home, separate from portable shelter')
    shot('house-pietro-bedroom.png')
    origin = state()['refuge']['scene_origin']
    # Sample the real bridge during held input. No state setters or teleports.
    page.keyboard.down('d')
    samples = []
    try:
        for _ in range(10):
            page.wait_for_timeout(110)
            samples.append(state()['refuge']['position'])
    finally:
        page.keyboard.up('d')
    check(all(0 <= b[0]-a[0] < 180 and a[1] == b[1] for a,b in zip(samples,samples[1:])), 'Walking across room boundary has continuous positions on one floor')
    check(state()['refuge']['room'] == 'living' and state()['refuge']['scene_origin'] != origin, 'Camera follows across bedroom and living without scene replacement')
    shot('refuge-main.png')
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
    walk_to(page, wait, 2310)
    click('refuge.improvements')
    wait("window.umbralState.refuge.notice.includes('indisponíveis')", 20000)
    shot('refuge-future-workbench.png')
    walk_to(page, wait, 3010)
    shot('house-kitchen.png')
    review_stairs(page, state, wait, key, click, lambda name: shot('house-' + name + '.png'), check)
    depart(page, wait)
    check(state()['controls']['journey.continue']['disabled'], 'Exterior exit opens preparation without starting a run')
    shot('refuge-departure.png')
    key('Escape')
    wait("window.umbralState.screen === 'refuge'")
    page.wait_for_timeout(500)
    check(state()['screen'] == 'refuge', 'Return at exterior threshold does not reopen preparation')
    check(all(before[f] == state()[f] for f in fields), 'Continuous home, stairs and consultations preserve gameplay/checkpoint fields')


def point_walk(page, state, wait, target_x, expression, touch=False):
    s = state()
    canvas = page.locator('#canvas').bounding_box()
    room = s['refuge']
    floor = 742 if room['upper_floor'] else 1730
    logical_x = room['scene_origin'][0] + target_x * room['scene_scale']
    logical_y = room['scene_origin'][1] + (floor+30) * room['scene_scale']
    x = canvas['x'] + logical_x / s['logical_size'][0] * canvas['width']
    y = canvas['y'] + logical_y / s['logical_size'][1] * canvas['height']
    if touch: page.touchscreen.tap(x, y)
    else: page.mouse.click(x, y)
    wait(expression, timeout=20000)


def touch_depart(page, state, wait, click):
    while state()['refuge']['position'][0] < 3400:
        x = min(3450, state()['refuge']['position'][0]+550)
        point_walk(page, state, wait, x, f"window.umbralState.refuge.position[0] >= {x-5}", touch=True)
    click('refuge.exit', touch=True)
    wait("window.umbralState.screen === 'journey'", 20000)


def responsive_home(session, width, height):
    wait, click, shot = session.wait, session.click, session.shot
    wait("window.umbralState.refuge.armed && !window.umbralState.refuge.waking")
    session.geometry(f'Pietro bedroom {width}×{height}')
    actor_margin(session.state, session.check, 'bedroom')
    shot(f'matrix-house-bedroom-{width}x{height}')
    walk_to(session.page, wait, 1600)
    session.geometry(f'Living room {width}×{height}')
    shot(f'matrix-house-living-{width}x{height}')
    walk_to(session.page, wait, 3010)
    session.geometry(f'Kitchen {width}×{height}')
    shot(f'matrix-house-kitchen-{width}x{height}')
    def capture(name):
        session.geometry(f'Continuous house {name} {width}×{height}')
        shot(f'matrix-house-{name}-{width}x{height}')
    review_stairs(session.page, session.state, wait, session.key, click, capture, session.check)
    walk_to(session.page, wait, 2450, 'a')


def pause_stairs(page, wait):
    # Hold until a physics tick acknowledges the input, including slow WebGL frames.
    page.keyboard.down('d')
    try:
        wait("window.umbralState.refuge.on_stairs && window.umbralState.refuge.stair_automatic === 0", timeout=20000)
    finally:
        page.keyboard.up('d')


def review_stairs(page, state, wait, key, click, capture, check):
    click('refuge.stairs')
    wait("window.umbralState.refuge.on_stairs && window.umbralState.refuge.stair_progress >= .739", timeout=20000)
    pause_stairs(page, wait)
    up = state()['refuge']['stair_progress']
    actor_margin(state, check, 'paused ascent')
    capture('stair-ascent')
    key('e')
    wait(f"window.umbralState.refuge.upper_floor || window.umbralState.refuge.stair_progress > {up+.005}", timeout=20000)
    check(state()['refuge']['stair_direction'] == 1, 'E resumes paused ascent in the same direction')
    wait("window.umbralState.refuge.upper_floor && !window.umbralState.refuge.on_stairs", timeout=20000)
    walk_to(page, wait, 1250, 'a')
    actor_margin(state, check, 'mother bedroom')
    capture('mother-bedroom')
    walk_to(page, wait, 2210)
    click('refuge.stairs')
    wait("window.umbralState.refuge.on_stairs && window.umbralState.refuge.stair_progress < .98", timeout=20000)
    pause_stairs(page, wait)
    actor_margin(state, check, 'upper descent; hair-clipping regression')
    capture('stair-descent')
    key('e')
    wait("window.umbralState.refuge.on_stairs && window.umbralState.refuge.stair_progress < .45", timeout=20000)
    pause_stairs(page, wait)
    down = state()['refuge']['stair_progress']
    click('refuge.stairs')
    wait(f"!window.umbralState.refuge.on_stairs || window.umbralState.refuge.stair_progress < {down-.005}", timeout=20000)
    check(state()['refuge']['stair_direction'] == -1, 'Click resumes lower-half descent in the same direction')
    wait("!window.umbralState.refuge.on_stairs", timeout=20000)
    actor_margin(state, check, 'ground return')
