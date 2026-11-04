"""Real keyboard locomotion in the production Web build; bridge stays read-only."""
def review_room(page, state, wait, key, click, shot, check):
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    before = state()
    fields = ('hand', 'deck', 'discard', 'party', 'enemies', 'actions', 'stats', 'expedition', 'checkpoint_status')
    check(state()['focused'] == 'refuge.walk', 'Refuge gives movement initial focus')
    shot('refuge-main.png')

    def move_to(axis, target):
        # Bounded real key pulses avoid overshooting narrow corridors when the
        # renderer/CI delays an acknowledgement. Shift requests a fresh read-only
        # snapshot after release; it is not bound to a gameplay action.
        for _ in range(80):
            current = state()['refuge']['position'][axis]
            if abs(current - target) <= (35 if axis == 0 else 24):
                return
            button = ('a', 'd')[current < target] if axis == 0 else ('w', 's')[current < target]
            page.keyboard.press(button, delay=70)
            page.wait_for_timeout(120)
            key('Shift')
        shot('refuge-walk-failure.png')
        raise AssertionError(f"Walking did not reach axis {axis} target {target}: {state()['refuge']}")

    move_to(1, 420)
    move_to(0, 320)
    check(state()['refuge']['nearby'] == 'codex', 'Walking reaches reading station')
    page.keyboard.down('w')
    page.wait_for_timeout(700)
    page.keyboard.up('w')
    key('Shift')
    check(378 <= state()['refuge']['position'][1] < 400, 'Reading desk blocks further movement')
    shot('refuge-reading-desk.png')
    key('e')
    wait("window.umbralState.screen === 'codex'")
    stationary = state()['refuge']['position']
    page.keyboard.down('d')
    page.wait_for_timeout(300)
    page.keyboard.up('d')
    key('Shift')
    check(state()['refuge']['position'] == stationary, 'Codex modal suspends avatar movement')
    shot('refuge-codex.png')
    key('Escape')
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    check(state()['refuge']['position'] == stationary and state()['focused'] == 'refuge.walk',
          'Closing codex restores avatar position and movement focus')
    move_to(0, 840)
    key('e')
    check(state()['screen'] == 'refuge' and 'indisponíveis' in state()['refuge']['notice'],
          'Workbench honestly reports unavailable improvements')
    shot('refuge-future-workbench.png')
    move_to(0, 1030)
    move_to(1, 310)
    check(state()['refuge']['nearby'] == 'journey', 'Walking reaches departure door')
    shot('refuge-departure.png')
    key('Enter')
    wait("window.umbralState.screen === 'journey'")
    check(state()['controls']['journey.continue']['disabled'], 'Departure opens once and does not accidentally start New')
    key('Escape')
    wait("window.umbralState.screen === 'refuge'")
    check(all(before[field] == state()[field] for field in fields),
          'Walking and consultations preserve all exposed gameplay/checkpoint fields')
