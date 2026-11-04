"""Focused current-product rewards scenario."""
def run(s):
    s.fixture(s.args.fixture or 'rewards_many')
    offers = s.state()['offers']; s.check(len(offers) >= 2, 'Real encounter produces capture/evolution offers')
    s.shot('rewards'); chosen = next(i for i,o in enumerate(offers) if o['kind'] == 'evolve')
    uid = offers[chosen]['uid']; before = next(u for u in s.state()['party'] if u['uid'] == uid)
    s.click('reward.' + str(chosen)); s.wait("window.umbralState.screen === 'map'")
    after = next(u for u in s.state()['party'] if u['uid'] == uid)
    s.check(after['passive'] == before['passive'] and after['form_id'] == offers[chosen]['target_form_id'] and before['form_id'] == offers[chosen]['source_form_id'], 'Evolution preserves UID/passive and returns to map')
    s.shot('reward-map')

    # Test-only checkpoint boot; all edits below use real production controls.
    s.fixture('spring_room')
    before = s.state()['expedition']
    s.check(before['phase'] == 'event', 'Spring fixture opens the contextual route room')
    s.shot('room-arrival')
    s.click('event.rest'); s.click('event.cancel')
    s.check(s.state()['expedition'] == before, 'Canceling rest spends neither HP recovery nor room')
    option = before['event']['practice'][0]
    uid = option['uid']
    source = option['donors'][0]
    target = next(p for p in option['receivers'] if p != source)
    def draft():
        s.click('event.practice')
        s.click('event.uid.' + str(uid))
        s.click('event.from_power.' + source)
        s.click('event.to_power.' + target)
    draft()
    s.check(s.state()['expedition'] == before, 'Previewing a complete practice choice leaves the run unchanged')
    s.shot('room-practice-preview')
    s.click('event.cancel')
    s.check(s.state()['expedition'] == before and s.state()['controls']['event.confirm']['disabled'], 'Canceling the transfer leaves all owned cards unchanged')
    if not s.state()['preferences']['large_text']:
        s.click('map.pause'); s.click('pause.settings'); s.click('settings.large_text')
        s.click('settings.back'); s.click('pause.resume')
    s.check(s.state()['expedition'] == before, 'Options preserve the pending contextual room')
    # Full room and confirmation remain actionable in the standard resolution matrix.
    for width,height in s.contracts['viewports']:
        s.page.set_viewport_size({'width':width,'height':height})
        s.page.wait_for_timeout(300)
        s.key('Shift')
        draft()
        s.geometry(f'Contextual practice {width}x{height}', scrollable=True)
        s.shot(f'room-practice-{width}x{height}')
        s.click('event.cancel')
    draft()
    for _ in range(24):
        if s.state()['focused'] == 'event.confirm': break
        s.key('Tab')
    s.check(s.state()['focused'] == 'event.confirm', 'Keyboard navigation reaches the room confirmation')
    s.key('Enter')
    s.wait("window.umbralState.expedition.phase === 'map'")
    after = s.state()['expedition']
    old = next(u for u in before['party'] if u['uid'] == uid)
    new = next(u for u in after['party'] if u['uid'] == uid)
    s.check(len(new['cards']) == len(old['cards']) and [c['instance_id'] for c in new['cards']] == [c['instance_id'] for c in old['cards']], 'Practice conserves the total and physical instances')
    s.check(sum(c['power'] == source for c in new['cards']) == option['counts'][source]-1 and sum(c['power'] == target for c in new['cards']) == option['counts'][target]+1, 'Exactly one copy shifts between known techniques')
    s.check(new['hp'] == old['hp'] and new['passive'] == old['passive'] and new['form_id'] == old['form_id'], 'Practice keeps identity and costs the offered rest')
    s.check(all(u == next(v for v in after['party'] if v['uid'] == u['uid']) for u in before['party'] if u['uid'] != uid), 'Other individuals are untouched')
    s.check('spring' in [n['id'] for n in after['nodes'] if n['completed']] and next(n for n in after['nodes'] if n['id'] == 'thicket')['locked'], 'Room decision closes the branch once')
    s.check(s.state()['checkpoint_status'] == 'ok', 'Contextual practice is checkpointed')
    s.shot('room-practice-completed')
