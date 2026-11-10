"""Real rendered composition at all supported sizes, plus normal battle input with preview."""
from urllib.parse import urlencode
import json
import time


def cast_with_clear_lane(s, name):
    round_before = s.state()['round_number']
    s.click('hud.cast')
    s.wait('window.umbralState.busy')
    s.wait("Object.entries(window.umbralState.controls).filter(([key]) => key.startsWith('hand.')).every(([, card]) => !card.moving)")
    state = s.state()
    s.check(state['busy'] and not state['card_raster']['focus']['visible'], 'Conjurar collapses the expanded hand card while the real effects are still playing')
    s.check(all(card['scale'] <= 1.01 for card in state['card_raster']['hand']), 'The actual owned buttons finish collapsing before occupying the effect corridor')
    s.check(all(state['controls']['hand.' + str(i)]['disabled'] for i in range(len(state['hand']))), 'Committed cards stay visible but cannot receive input during the round')
    s.page.screenshot(path=str(s.output / (name + '.png')))
    (s.output / (name + '.state.json')).write_text(json.dumps(state, indent=2, ensure_ascii=False))
    s.captures.append({'name': name, 'file': name + '.png', 'screen': 'battle', 'seconds': round(time.monotonic() - s.started, 3)})
    s.wait('!window.umbralState.busy && window.umbralState.round_number > ' + str(round_before), timeout=90000)
    s.check(s.state()['round_number'] == round_before + 1, 'Conjurar executes exactly one round from the real fanned hand')


def run(s):
    measurements = []
    # Fail early on real GUI picking: Godot's canvas Z alone does not reorder
    # overlapping Buttons for input. This sequence must toggle the intended copy.
    s.page.goto(s.base_url + '?test=1&visual=1&fixture=motion_dew&card_preview=1')
    s.wait('window.umbralState && window.umbralState.fixture_ready', timeout=90000)
    s.settled()
    identities = [s.state()['controls']['hand.' + str(i)]['instance_id'] for i in range(6)]
    for index in [0, 2, 0, 2, 0, 0]:
        expected = set(s.state()['selected']) ^ {index}
        s.click('hand.' + str(index))
        s.check(set(s.state()['selected']) == expected, 'Overlapped input toggles the exact intended card %d, including the foreground card' % index)
        s.check([s.state()['controls']['hand.' + str(i)]['instance_id'] for i in range(6)] == identities, 'Sibling picking order never rebuilds or reindexes the six owned nodes')
    s.click('hand.' + str(next(i for i, card in enumerate(s.state()['hand']) if card['power'] == 'tidal_splash')))
    cast_with_clear_lane(s, 'card-casting-clear-lane-cold')
    for viewport in [(1280, 720), (1440, 900), (1920, 1080), (1024, 768), (2560, 1080)]:
        s.page.set_viewport_size({'width': viewport[0], 'height': viewport[1]})
        for large in (False, True):
            query = urlencode({'test': '1', 'card_gallery': '1', 'large_text': '1' if large else '0'})
            s.page.goto(s.base_url + '?' + query)
            s.page.wait_for_function('window.cardGalleryState && window.cardGalleryState.ready', timeout=90000)
            data = s.page.evaluate('window.cardGalleryState')
            measurements.append({'viewport': viewport, 'large_text': large, **data['metrics']})
            cards = data['cards']
            s.check(len(cards) == 7 and [card['art_pending'] for card in cards] == [False, False, False, False, False, False, True], 'Exact initial/adult candidates and isolated Forest demo load; shared-family missing art stays pending')
            s.check(cards[3]['frame'] == cards[4]['frame'] == cards[5]['frame'] and cards[3]['frame'] != cards[0]['frame'], 'Family frame stays fixed across attack natures and differs between Foli/Lonlon')
            s.check(cards[3]['title_plate'] != cards[5]['title_plate'] and cards[3]['owner_plate'] != cards[5]['owner_plate'], 'Both Lonlon name plates change together with Water/Forest move nature')
            s.check(cards[0]['frame'] == cards[2]['frame'] and cards[0]['form'] != cards[2]['form'], 'Explicit family reuse supports adult and initial form identities')
            s.check(cards[3]['title_plate'] == cards[6]['title_plate'] and cards[3]['species'] != cards[6]['species'], 'A legal shared Water move uses one style across two families')
            s.check(cards[4]['target'] == 'single' and cards[4]['target_uid'] == 1, 'Highlighted healing card has the current Foli target portrait')
            s.check(not data['illegal_demo_learnable'], 'Lonlon/Forest remains an isolated nonplayable demo')
            s.check(data['metrics']['catalog']['cached_textures'] <= data['metrics']['catalog']['cache_limit'], 'Rendered gallery respects the exact texture cache bound')
            s.check(all(card['texture_filter'] == 4 for card in cards), 'Painted card components explicitly use linear mipmap sampling')
            s.check(all(profile['mipmap_count'] > 0 for profile in data['metrics']['catalog']['texture_profiles']), 'Cold-exported real textures provide measured mip levels')
            s.check(data['metrics']['catalog']['release'].endswith('@0.3.0') and all('/0.2.0/' in card['frame'] for card in cards[:6]), 'Real gallery uses the new reference-derived family frames and exact candidate release')
            s.page.screenshot(path=str(s.output / ('cards-%dx%d%s.png' % (*viewport, '-large' if large else ''))))
            s.captures.append({'name': 'cards-%dx%d%s' % (*viewport, '-large' if large else ''), 'file': 'cards-%dx%d%s.png' % (*viewport, '-large' if large else ''), 'screen': 'gallery'})
    s.page.set_viewport_size({'width': 1280, 'height': 720})
    s.page.goto(s.base_url + '?test=1&card_gallery=1&card_concept=1')
    s.page.wait_for_function('window.cardGalleryState && window.cardGalleryState.ready', timeout=90000)
    concept = s.page.evaluate('window.cardGalleryState')
    s.check(concept['concept'] and len(concept['cards']) == 6 and not any(card['art_pending'] for card in concept['cards']), 'Approved six-card composition uses actual candidate art for every isolated visual example')
    s.check(concept['cards'][4]['target_uid'] == 1 and not concept['illegal_demo_learnable'], 'Foli is the concept recipient; Lonlon/Forest illustration still grants no gameplay eligibility')
    s.check(concept['cards'][3]['frame'] == concept['cards'][5]['frame'] and concept['cards'][3]['owner_plate'] != concept['cards'][5]['owner_plate'], 'Lonlon keeps the blue family perimeter while both plaques follow Water versus Forest')
    s.page.screenshot(path=str(s.output / 'cards-reference-composition.png'))
    s.captures.append({'name': 'cards-reference-composition', 'file': 'cards-reference-composition.png', 'screen': 'gallery'})
    # Return to the actual fixture boot; its production bridge remains read-only.
    s.page.set_viewport_size({'width': 1280, 'height': 720})
    s.page.goto(s.base_url + '?' + urlencode({'test': '1', 'visual': '1', 'fixture': 'motion_dew', 'card_preview': '1'}))
    s.wait('window.umbralState && window.umbralState.fixture_ready', timeout=90000)
    s.settled()
    original = s.state()
    s.click('hand.0')
    s.check(s.state()['selected'], 'Real mouse selects an owned card with the new renderer')
    # Exercise the renderer inside the actual four-zone battle HUD too; the
    # isolated gallery alone cannot prove hand/pause/settings integration.
    def set_large(enabled):
        if s.state()['preferences']['large_text'] != enabled:
            s.click('hud.pause'); s.click('pause.settings'); s.click('settings.large_text')
            s.back('pause'); s.back('battle')

    for width, height in [(1280, 720), (1440, 900), (1920, 1080), (1024, 768), (2560, 1080)]:
        s.page.set_viewport_size({'width': width, 'height': height})
        s.page.evaluate('() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))')
        for large in (False, True):
            set_large(large)
            s.settled()
            s.check(s.state()['preferences']['large_text'] == large, 'Actual large-text preference applies to the preview hand')
            s.geometry('Modular battle hand %dx%d large=%s' % (width, height, large))
            s.check(len(s.state()['hand']) == 6 and all(s.state()['controls']['hand.' + str(i)]['visible'] for i in range(6)), 'All six real cards remain visible in the battle HUD')
            raster = s.state()['card_raster']
            canvas = s.page.evaluate('''() => {
                const c = document.querySelector('#canvas'), r = c.getBoundingClientRect();
                const gl = c.getContext('webgl2');
                return {css: [r.width, r.height], backing: [c.width, c.height],
                    dpr: devicePixelRatio, drawing_buffer: [gl.drawingBufferWidth, gl.drawingBufferHeight]};
            }''')
            s.check(raster['world_filter'] == 1 and all(card['filter'] == 4 for card in raster['hand']), 'Battle sprites keep nearest sampling while painted cards override it')
            s.check(raster['focus']['visible'] and raster['focus']['filter'] == 4 and raster['focus']['mode'] == 'in_place' and not raster['focus']['duplicate_projection'], 'Selection enlarges the real hand button without a duplicate central projection')
            focused = next(card for card in raster['hand'] if card['instance_id'] == raster['focus']['instance_id'])
            s.check(focused['node_id'] == raster['focus']['node_id'] and all(a > b * 1.15 for a, b in zip(raster['focus']['art_logical'], focused['art_logical'])), 'The exact owned node grows in place, retaining its instance and button identity')
            s.check(all(card['fanned'] for card in raster['hand']) and raster['hand'][0]['home_rotation'] < 0 < raster['hand'][-1]['home_rotation'], 'The actual six-card combat hand uses the curved family-card fan')
            s.check('Lonlon' in raster['focus']['target_label'], 'Live healing recipient remains Lonlon even though the fixed illustration depicts Foli')
            s.check(canvas['backing'] == canvas['drawing_buffer'] and all(a >= b for a, b in zip(canvas['backing'], canvas['css'])), 'Browser draws into a native-size backing buffer without CSS upscaling')
            s.check(raster['render_readback_size'] == canvas['backing'] == raster['window_size'], 'Actual GPU pixel readback equals the canvas backing size, independently of scaled ViewportTexture metadata')
            measurements.append({'viewport': [width, height], 'large_text': large, 'battle': raster, 'canvas': canvas, 'logical_size': s.state()['logical_size']})
            s.shot('card-hand-%dx%d%s' % (width, height, '-large' if large else ''))
    s.page.set_viewport_size({'width': 1280, 'height': 720})
    set_large(False)
    s.click('hand.0'); s.click('hand.0')  # Restore real card focus after settings.
    s.shot('card-battle')
    attack = next(i for i, card in enumerate(s.state()['hand']) if card['power'] == 'tidal_splash')
    s.click('hand.0'); s.click('hand.' + str(attack))
    s.shot('card-enemy-target')
    s.click('hand.' + str(attack)); s.click('hand.0')
    s.key('c')
    s.wait("window.umbralState.screen === 'inspect'")
    s.geometry('Preview card inspection', scrollable=True)
    s.shot('card-inspection')
    s.back('battle')
    s.click('hud.draw')
    s.wait("window.umbralState.screen === 'pile'")
    s.shot('card-pile')
    s.back('battle')
    s.check(s.state()['party'] == original['party'] and s.state()['hand'] == original['hand'], 'Selection/inspection/pile preview leave canonical owners/cards unchanged')
    # Every overlapped card remains clickable. Real slot targeting and Conjurar
    # must work after the visual change, not only a static gallery or keyboard.
    for index in range(6):
        if index in s.state()['selected']:
            s.click('hand.' + str(index))
        s.click('hand.' + str(index))
        s.check(index in s.state()['selected'], 'Fan exposes actual button %d to real mouse input' % index)
        s.click('hand.' + str(index))
    s.click('hand.' + str(attack))
    s.click('enemy.2')
    s.check(s.state()['hand'][attack]['target_slot'] == 2, 'Raised fan leaves the lower enemy target reachable')
    cast_with_clear_lane(s, 'card-casting-clear-lane')
    s.shot('card-after-conjurar')
    # A one-owner deck immediately recycles all six cards. Use the existing
    # multi-owner fixture for an actually populated grouped draw pile.
    s.page.goto(s.base_url + '?' + urlencode({'test': '1', 'visual': '1', 'fixture': 'inventory_full', 'card_preview': '1'}))
    s.wait('window.umbralState && window.umbralState.fixture_ready', timeout=90000)
    s.settled()
    s.check(len(s.state()['deck']) > 0, 'Multi-owner fixture has actual cards to display in the grouped draw pile')
    s.click('hud.draw')
    s.wait("window.umbralState.screen === 'pile'")
    s.geometry('Nonempty card pile', scrollable=True)
    s.shot('card-pile-populated')
    s.back('battle')
    # Chromium touch injection exercises the real canvas event path.
    client = s.context.new_cdp_session(s.page)
    client.send('Emulation.setTouchEmulationEnabled', {'enabled': True})
    before = s.state()
    control = before['controls']['hand.0']
    canvas = s.page.locator('#canvas').bounding_box()
    activation = control.get('activation_point', [control['cx'], control['cy']])
    point = {'x': canvas['x'] + activation[0] / before['logical_size'][0] * canvas['width'], 'y': canvas['y'] + activation[1] / before['logical_size'][1] * canvas['height']}
    client.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': [point]})
    client.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
    s.wait("window.umbralState.selected.length === 1")
    s.check(s.state()['hand'] == before['hand'] and s.state()['party'] == before['party'], 'Real touch selects the preview without changing owned cards/individuals')
    client.send('Emulation.setTouchEmulationEnabled', {'enabled': False})
    client.detach()
    (s.output / 'card-runtime-measurements.json').write_text(json.dumps(measurements, indent=2))
