"""Real-input review of the standalone pixel-art study, not the production game."""
import argparse,functools,http.server,json,threading,traceback
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--build-dir',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
class H(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*_):pass
s=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(H,directory=str(a.build_dir.resolve())));threading.Thread(target=s.serve_forever,daemon=True).start()
checks=[];errors=[];observations=[];captures=[];failure=None;video=None
def check(value,label):
 assert value,label
 checks.append(label)
try:
 with sync_playwright() as pw:
  b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader'])
  c=b.new_context(viewport={'width':1600,'height':1000},device_scale_factor=1,record_video_dir=str(out/'video'),record_video_size={'width':1600,'height':1000});page=c.new_page();v=page.video
  page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  page.add_init_script('''window.studyFrames=[];function observe(){const s=window.pietroStudy;if(s){const previous=window.studyFrames.at(-1);if(!previous||JSON.stringify(s)!==JSON.stringify(previous.state))window.studyFrames.push({t_ms:performance.now(),state:s});}requestAnimationFrame(observe)}requestAnimationFrame(observe);''')
  def state():return page.evaluate('window.pietroStudy')
  def click(key):
   x,y=state()['controls'][key];box=page.locator('#canvas').bounding_box();page.mouse.click(box['x']+x/1600*box['width'],box['y']+y/1000*box['height'])
  def shot(name):
   page.screenshot(path=str(out/(name+'.png')));captures.append({'file':name+'.png','state':state()})
  page.goto(f'http://127.0.0.1:{s.server_port}/index.html');page.wait_for_function("window.pietroStudy?.mode==='static'",timeout=90000);page.wait_for_timeout(300)
  check(state()['gather']==0,'Initial static uses the unchanged approved source');shot('static');page.wait_for_timeout(1700)
  click('reference');page.wait_for_function("window.pietroStudy.mode==='reference'");shot('approved-reference');page.wait_for_timeout(1500)
  click('static');page.wait_for_function("window.pietroStudy.mode==='static'");check(state()['anchor']==[620,812],'Static comparison returns to its calibrated same-plane anchor')
  click('walk');page.wait_for_function("window.pietroStudy.stage==='walking'")
  page.wait_for_function("window.pietroStudy.stage==='finished'",timeout=20000);page.wait_for_timeout(300);shot('finished');page.wait_for_timeout(1500)
  observations=page.evaluate('window.studyFrames');walk=[x['state'] for x in observations if x['state']['stage']=='walking']
  orders=[1 if x['foot_progress'][0]>x['foot_progress'][1] else -1 for x in walk]
  alternations=sum(x!=y for x,y in zip(orders,orders[1:]))
  check(alternations>=5 and walk[-1]['cycle']-walk[0]['cycle']>2.5,'Real playback alternates forward progress on the separate three-quarter support lanes across all cycles')
  check(min(x['boot_gap'] for x in walk)>10,'The two rendered boot silhouettes keep separate horizontal bounds')
  check(max(x['body_drop'] for x in walk)<12,'Observed pelvis compensation stays below twelve source pixels')
  check(max(x['upper_angles'][0] for x in walk)-min(x['upper_angles'][0] for x in walk)>.08 and max(x['upper_angles'][2] for x in walk)-min(x['upper_angles'][2] for x in walk)>.03,'Observed arms and backpack have independent phased motion')
  check(max(x['reach_error'] for x in walk)<.01,'Observed walk remains within original bone lengths')
  check(state()['anchor']==[620,812] and state()['gather']==0,'The short walk ends at the static anchor and original pose')
  initial=Image.open(out/'static.png').crop((7,8,1593,888));final=Image.open(out/'finished.png').crop((7,8,1593,888));check(initial.tobytes()==final.tobytes(),'The rendered scene returns pixel-identically to the initial static comparison')
  check(not errors,'Browser has no runtime errors');c.close();video=str(v.path());b.close()
except Exception:
 failure=traceback.format_exc()
 try:page.screenshot(path=str(out/'failure.png'))
 except Exception:pass
finally:s.shutdown()
if video is None:
 files=list((out/'video').glob('*.webm'))
 if len(files)==1:video=str(files[0])
r={'scope':'standalone Godot art-direction study; real controls, no production-game integration claim','checks':len(checks),'passed':checks,'failed':int(failure is not None),'failure':failure,'errors':errors,'captures':captures,'observations':observations,'video':video};(out/'report.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'checks':r['checks'],'failed':r['failed'],'video':video}))
if failure:raise SystemExit(failure)
