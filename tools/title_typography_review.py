from pathlib import Path
from playwright.sync_api import sync_playwright
import json,functools,http.server,threading,hashlib,time
root=Path(__file__).resolve().parents[1];out=root/'test-results/title-typography';out.mkdir(parents=True,exist_ok=True)
pack=root/'builds/web/index.pck';digest=hashlib.sha256(pack.read_bytes()).hexdigest();started=time.monotonic();checks=[];errors=[]
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=str(root/'builds/web')));threading.Thread(target=server.serve_forever,daemon=True).start()
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader']);c=b.new_context(viewport={'width':390,'height':844},has_touch=True);page=c.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' or m.text.startswith('ERROR:') or 'SCRIPT ERROR:' in m.text else None)
 def wait(s):page.wait_for_function('window.umbralState && ('+s+')',timeout=90000)
 def state():return page.evaluate('window.umbralState')
 def click(identity):
  s=state();control=s['controls'][identity];assert control['active'] and control['visible'] and not control['disabled'];canvas=page.locator('#canvas').bounding_box();x=canvas['x']+control['cx']/s['logical_size'][0]*canvas['width'];y=canvas['y']+control['cy']/s['logical_size'][1]*canvas['height'];page.touchscreen.tap(x,y);wait(f'window.umbralState.last_interaction === "{identity}" && window.umbralState.interaction_serial > {s["interaction_serial"]}');checks.append('Touch '+identity)
 def shot(name):page.wait_for_timeout(350);page.screenshot(path=str(out/name))
 page.goto(f'http://127.0.0.1:{server.server_port}/index.html?test=1&visual=1');wait('window.umbralState.screen === "menu"');click('menu.play');shot('journey-portrait.png');click('journey.back')
 page.set_viewport_size({'width':844,'height':390});page.wait_for_timeout(200);page.keyboard.press('Shift');page.wait_for_timeout(200);click('menu.play');shot('journey-landscape.png');click('journey.back')
 page.set_viewport_size({'width':1672,'height':941});page.wait_for_timeout(200);page.keyboard.press('Shift');page.wait_for_timeout(200);click('menu.play');shot('journey-desktop.png');click('journey.new');click('starter.ember');wait('window.umbralState.screen === "map"');saved=state()['expedition'];click('map.pause');click('pause.menu');click('confirm.yes');click('menu.play');shot('journey-saved.png');assert state()['journey_summary']=='Bosque · Próxima parada: Clareira';checks.append('Saved summary unchanged');click('journey.new');click('new.cancel');click('journey.continue');wait('window.umbralState.screen === "map"');assert state()['expedition']==saved;checks.append('Exact checkpoint restored after typography change');assert not errors;assert hashlib.sha256(pack.read_bytes()).hexdigest()==digest;checks.extend(['No browser/engine errors','Pack unchanged']);c.close();b.close()
server.shutdown();report={'suite':'title_typography_final','failed':0,'checks':len(checks),'passed':checks,'errors':errors,'web_pck_sha256':digest,'seconds':round(time.monotonic()-started,2),'scope':'Final Journey font floor, touch, public saved summary and exact continuation after presentation-only change.'};(out/'report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
