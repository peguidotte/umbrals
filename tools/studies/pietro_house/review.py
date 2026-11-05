"""Real-input A/B, camera and two walking speeds in the actual house experiment."""
import argparse,functools,http.server,json,threading,traceback
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--build-dir',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
class H(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*_):pass
s=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(H,directory=str(a.build_dir.resolve())));threading.Thread(target=s.serve_forever,daemon=True).start()
checks=[];errors=[];captures=[];observations=[];failure=None;video=None
def check(value,label):
 assert value,label
 checks.append(label)
try:
 with sync_playwright() as pw:
  browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader'])
  context=browser.new_context(viewport={'width':1600,'height':900},device_scale_factor=1,record_video_dir=str(out/'video'),record_video_size={'width':1600,'height':900});page=context.new_page();v=page.video
  page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  page.add_init_script('''window.houseFrames=[];function observe(){const s=window.pietroHouseStudy;if(s){const p=window.houseFrames.at(-1);if(!p||JSON.stringify(s)!==JSON.stringify(p.state))window.houseFrames.push({t_ms:performance.now(),state:s})}requestAnimationFrame(observe)}requestAnimationFrame(observe);''')
  def state():return page.evaluate('window.pietroHouseStudy')
  def wait(expression,timeout=45000):page.wait_for_function(expression,timeout=timeout)
  def click(key):
   x,y=state()['controls'][key];box=page.locator('#canvas').bounding_box();page.mouse.click(box['x']+x/1600*box['width'],box['y']+y/900*box['height'])
  def shot(name):page.screenshot(path=str(out/(name+'.png')));captures.append({'file':name+'.png','state':state()})
  def walk(key,distance):
   start=state()['room']['position'][0];op='>' if key=='d' else '<';target=start+distance*(1 if key=='d' else -1)
   page.keyboard.down(key)
   try:wait(f'window.pietroHouseStudy.room.position[0] {op} {target}')
   finally:page.keyboard.up(key)
   page.wait_for_timeout(650)
  page.goto(f'http://127.0.0.1:{s.server_port}/index.html?test=1');wait('window.pietroHouseStudy?.room.armed && window.umbralState',180000);page.wait_for_timeout(500)
  before=state();check(before['candidate'] and before['room']['position']==[1540,1730] and before['room']['world_size']==[4200,2145],'Starts candidate in the actual living room and house coordinates')
  check(before['brasa']['texture'].find('battle-creatures')>=0 and before['brasa']['world_foot'][1]==1730,'Current runtime Brasa is a separate live renderer on the same floor')
  game_before=page.evaluate('JSON.stringify([window.umbralState.party,window.umbralState.stats,window.umbralState.expedition,window.umbralState.checkpoint_status])')
  shot('candidate-real-house');page.wait_for_timeout(1000);check(state()['brasa']['idle_time']>before['brasa']['idle_time'],'Brasa actually animates independently of the house texture')
  click('current');wait('!window.pietroHouseStudy.candidate');current=state();check(current['room']['position']==before['room']['position'] and current['room']['camera_center']==before['room']['camera_center'],'A/B preserves world position and camera');shot('current-real-house');page.wait_for_timeout(1400)
  click('candidate');wait('window.pietroHouseStudy.candidate');check(state()['room']['position']==before['room']['position'],'Candidate returns without resetting the house');page.wait_for_timeout(700)
  click('pace');wait('window.pietroHouseStudy.slow');slow_start=state();walk('d',180);slow_end=state();check(slow_end['room']['position'][0]>slow_start['room']['position'][0]+180 and slow_end['speed']==100,'Explicit slow walk uses the real floor controller at study speed');check(slow_end['room']['camera_center'][0]>slow_start['room']['camera_center'][0],'Actual house camera follows the candidate');shot('slow-walk-stop');page.wait_for_timeout(700)
  click('frame');page.wait_for_timeout(500)
  click('pace');wait('!window.pietroHouseStudy.slow');normal_start=state();walk('d',90);check(state()['speed']==330 and state()['travelled']>normal_start['travelled']+90,'Normal walk preserves the current house speed and distance-driven gait');shot('normal-walk-stop')
  reverse_start=state()['room']['position'][0];walk('a',90);check(state()['room']['position'][0]<reverse_start-90,'Reverse input moves continuously on the same floor');check(state()['gather']==0,'Release settles to the approved neutral pose')
  game_after=page.evaluate('JSON.stringify([window.umbralState.party,window.umbralState.stats,window.umbralState.expedition,window.umbralState.checkpoint_status])');check(game_after==game_before,'A/B and both speeds preserve party, stats, expedition and checkpoint')
  click('frame');page.wait_for_timeout(700);shot('final-comparison')
  # The desk is the unchanged actual house hotspot, approached by real pointer input.
  page.mouse.click(405,300);wait("window.umbralState.screen==='codex'",45000);paused=state();page.wait_for_timeout(450);check(state()['room']['position']==paused['room']['position'] and not state()['room']['active'],'Real codex modal suspends experimental house movement');page.keyboard.press('Escape');wait("window.umbralState.screen==='refuge'");check(state()['room']['position']==paused['room']['position'],'Closing the real codex preserves the house position')
  click('frame');page.wait_for_timeout(700)
  check(not errors,'No browser runtime errors');observations=page.evaluate('window.houseFrames');context.close();video=str(v.path());browser.close()
except Exception:
 failure=traceback.format_exc()
 try:page.screenshot(path=str(out/'failure.png'))
 except Exception:pass
finally:s.shutdown()
if video is None:
 files=list((out/'video').glob('*.webm'))
 if len(files)==1:video=str(files[0])
report={'scope':'Opt-in experiment in actual current house; current Brasa; normal and explicit slow speeds; not visual approval or production replacement','checks':len(checks),'passed':checks,'failed':int(failure is not None),'failure':failure,'errors':errors,'captures':captures,'observations':observations,'video':video};(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['checks','failed','failure','video']}))
if failure:raise SystemExit(failure)
