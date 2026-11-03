"""Viewport matrix. This entry never depends on completing combat or replacement."""

def run(session):
    page = session.page
    state, wait, settled, load = session.state, session.wait, session.settled, session.load
    key, back, click, shot = session.key, session.back, session.click, session.shot
    check, geometry, clear_selection, start = session.check, session.geometry, session.clear_selection, session.start
    profiles = [session.viewport] if session.viewport else session.contracts['viewports']
    for width,height in profiles:
        page.set_viewport_size({'width':width,'height':height})
        page.wait_for_timeout(250)
        load()
        meta=geometry(f'Menu {width}×{height}')
        shot(f'matrix-menu-{width}x{height}')
        start()
        meta.update(geometry(f'Battle {width}×{height}'))
        click('hud.inventory')
        geometry(f'Inventory {width}×{height}')
        shot(f'matrix-inventory-{width}x{height}')
        back('battle')
        key('1')
        shot(f'matrix-battle-{width}x{height}')
        click('hud.pause')
        geometry(f'Pause {width}×{height}')
        click('pause.settings')
        click('settings.large_text')
        geometry(f'Large options {width}×{height}')
        shot(f'matrix-options-{width}x{height}')
        back('pause'); back('battle')
        geometry(f'Large battle {width}×{height}')
        shot(f'matrix-large-battle-{width}x{height}')
        click('hud.inventory')
        geometry(f'Large inventory {width}×{height}')
        shot(f'matrix-large-inventory-{width}x{height}')
        back('battle')
        click('hud.pause'); click('pause.menu'); click('confirm.yes')
        click('menu.settings'); click('settings.large_text'); back('menu')
        session.matrix.append({'viewport':{'width':width,'height':height},'status':'passed','details':meta})
