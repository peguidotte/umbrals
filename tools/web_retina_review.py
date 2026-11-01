"""Focused Web startup review: high DPR, sequential preload, touch and checkpoint reload."""
from pathlib import Path
import argparse,functools,http.server,threading,json,time
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--web-root',type=Path,required=True);parser.add_argument('--output',type=Path,default=ROOT/'test-results/V04-UX-05D-retina');args=parser.parse_args();out=args.output;out.mkdir(parents=True,exist_ok=True)
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=str(args.web_root.resolve())));threading.Thread(target=server.serve_forever,daemon=True).start();base=f'http://127.0.0.1:{server.server_port}/index.html?test=1&visual=1';checks=[];errors=[];started=time.monotonic()
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader'])
 context=browser.new_context(viewport={'width':393,'height':852},device_scale_factor=3,has_touch=True,is_mobile=True)
 context.add_init_script('''window.bootTrace=[];const instantiate=WebAssembly.instantiateStreaming;WebAssembly.instantiateStreaming=function(...args){bootTrace.push({kind:'compile.start',time:performance.now()});return instantiate.apply(this,args).then(result=>{bootTrace.push({kind:'compile.end',time:performance.now()});return result})};const originalFetch=fetch;window.fetch=function(resource,...args){bootTrace.push({kind:'fetch',url:String(resource),time:performance.now()});return originalFetch.call(this,resource,...args)};''')
 page=context.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' or 'SCRIPT ERROR:' in m.text else None)
 def check(v,msg):
  assert v,msg
  checks.append(msg)
 def wait(s):page.wait_for_function('window.umbralState && ('+s+')',timeout=90000)
 def state():return page.evaluate('umbralState')
 def tap(identity):
  s=state();c=s['controls'][identity];check(c['active'] and c['visible'] and not c['disabled'],'Reachable '+identity);canvas=page.locator('#canvas').bounding_box();page.touchscreen.tap(canvas['x']+c['cx']/s['logical_size'][0]*canvas['width'],canvas['y']+c['cy']/s['logical_size'][1]*canvas['height']);wait(f'umbralState.interaction_serial > {s["interaction_serial"]} && umbralState.last_interaction === "{identity}"')
 def canvas_bounds():
  d=page.evaluate('({width:canvas.width,height:canvas.height,cssWidth:innerWidth,cssHeight:innerHeight,dpr:devicePixelRatio})');check(d['width']==d['cssWidth'] and d['height']==d['cssHeight'],'Framebuffer equals CSS dimensions at DPR '+str(d['dpr']));return d
 page.goto(base);wait('umbralState.screen === "menu"');portrait=canvas_bounds();page.screenshot(path=str(out/'retina-portrait.png'),scale='css')
 trace=page.evaluate('bootTrace');compiled=next(e['time'] for e in trace if e['kind']=='compile.end');first_pack=next(e['time'] for e in trace if e['kind']=='fetch' and '.part-' in e.get('url',''));check(first_pack>=compiled,'Pack preload begins after WASM compilation completes')
 tap('menu.play');page.wait_for_timeout(200);page.screenshot(path=str(out/'journey-portrait.png'),scale='css');tap('journey.back')
 page.set_viewport_size({'width':852,'height':393});page.wait_for_timeout(300);page.keyboard.press('Shift');landscape=canvas_bounds();page.screenshot(path=str(out/'retina-landscape.png'),scale='css')
 tap('menu.play');tap('journey.new');tap('starter.ember');wait('umbralState.screen === "map"');saved=state()['expedition'];page.reload();wait('umbralState.screen === "menu"');tap('menu.play');tap('journey.continue');wait('umbralState.screen === "map"');check(state()['expedition']==saved,'Reload and Continue restore the exact public checkpoint');check(not errors,'No browser or engine errors');context.close()
 # Desktop density remains supported by the same CSS-budget path.
 context=browser.new_context(viewport={'width':1600,'height':900},device_scale_factor=2);page=context.new_page();page.goto(base);wait('umbralState.screen === "menu"');desktop=canvas_bounds();context.close();browser.close()
server.shutdown();report={'suite':'web_retina_scoped','checks':len(checks),'failed':0,'passed':checks,'portrait':portrait,'landscape':landscape,'desktop':desktop,'boot_trace':trace,'errors':errors,'seconds':round(time.monotonic()-started,2),'limits':['Chromium high-DPR/touch emulation, not physical Safari/iPhone.','No full combat or mutation suite.']};(out/'report.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:report[k] for k in ['suite','checks','failed','seconds','errors']}))
