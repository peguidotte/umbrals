"""Real keyboard locomotion in the production Web build; bridge stays read-only."""
def review_room(page, state, wait, key, click, shot, check):
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    before = state()
    fields = ('hand', 'deck', 'discard', 'party', 'enemies', 'actions', 'stats', 'expedition', 'checkpoint_status')
    check(state()['focused'] == 'refuge.walk', 'Refuge gives movement initial focus')
    shot('refuge-main.png')

    def walk(button, expression):
        page.keyboard.down(button)
        try:
            wait(expression)
        except Exception:
            shot('refuge-walk-failure.png')
            print(state()['refuge'], flush=True)
            raise
        finally:
            page.keyboard.up(button)
        page.wait_for_timeout(140)

    walk('w', 'window.umbralState.refuge.position[1] < 440')
    walk('a', 'window.umbralState.refuge.position[0] < 335')
    check(state()['refuge']['nearby'] == 'codex', 'Walking reaches reading station')
    page.keyboard.down('w')
    page.wait_for_timeout(700)
    page.keyboard.up('w')
    check(378 <= state()['refuge']['position'][1] < 400, 'Reading desk blocks further movement')
    shot('refuge-reading-desk.png')
    key('e')
    wait("window.umbralState.screen === 'codex'")
    stationary = state()['refuge']['position']
    page.keyboard.down('d')
    page.wait_for_timeout(300)
    page.keyboard.up('d')
    check(state()['refuge']['position'] == stationary, 'Codex modal suspends avatar movement')
    shot('refuge-codex.png')
    key('Escape')
    wait("window.umbralState.screen === 'refuge' && window.umbralState.refuge.armed")
    check(state()['refuge']['position'] == stationary and state()['focused'] == 'refuge.walk',
          'Closing codex restores avatar position and movement focus')
    walk('d', 'window.umbralState.refuge.position[0] > 825')
    key('e')
    check(state()['screen'] == 'refuge' and 'indisponíveis' in state()['refuge']['notice'],
          'Workbench honestly reports unavailable improvements')
    shot('refuge-future-workbench.png')
    walk('d', 'window.umbralState.refuge.position[0] > 1015')
    walk('w', 'window.umbralState.refuge.position[1] < 322')
    check(state()['refuge']['nearby'] == 'journey', 'Walking reaches departure door')
    shot('refuge-departure.png')
    key('Enter')
    wait("window.umbralState.screen === 'journey'")
    check(state()['controls']['journey.continue']['disabled'], 'Departure opens once and does not accidentally start New')
    key('Escape')
    wait("window.umbralState.screen === 'refuge'")
    check(all(before[field] == state()[field] for field in fields),
          'Walking and consultations preserve all exposed gameplay/checkpoint fields')
