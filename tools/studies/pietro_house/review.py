"""Real-input A/B, normal cadence and reduced motion in the actual house."""
import argparse,functools,http.server,json,threading,traceback
from pathlib import Path
from PIL import Image
import numpy as np
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
  shot('hair-soft');click('hair');wait('!window.pietroHouseStudy.soft_hair');shot('hair-original')
  soft=np.asarray(Image.open(out/'hair-soft.png').convert('RGB'));original=np.asarray(Image.open(out/'hair-original.png').convert('RGB'));changed=np.any(soft!=original,axis=2);body=np.zeros(changed.shape,bool);head=np.zeros(changed.shape,bool);body[103:647,668:932]=True;head[113:240,725:888]=True;hair_changes=changed & body & head;check(int((changed & body & ~head).sum())==0 and int(hair_changes.sum())>20,'Material changes are confined to the rendered hair region');check(float(original[hair_changes].mean()-soft[hair_changes].mean())>15,'The bright hair rim is visibly dimmer');check(np.array_equal(soft[190:240,773:864],original[190:240,773:864]),'Face and eyes remain pixel-identical during the hair A/B');click('hair');wait('window.pietroHouseStudy.soft_hair')
  normal_start=state();walk('a',180);left=state();check(left['room']['camera_center'][0]<normal_start['room']['camera_center'][0],'The unchanged house camera follows normal movement');walk('d',180);normal_end=state();cadence=2*(normal_end['cycles_advanced']-normal_start['cycles_advanced'])/(normal_end['moving_time']-normal_start['moving_time']);check(normal_end['speed']==330 and 2.8<cadence<3.2,'Real playback measures about three steps per second at unchanged house speed');shot('normal-walk-stop');check(state()['gather']==0,'Release settles to the approved neutral pose')
  click('frame');page.wait_for_timeout(600);click('motion');wait('window.pietroHouseStudy.reduced && window.pietroHouseStudy.brasa.reduced_motion');page.wait_for_timeout(300);reduced=state();shot('reduced-first');page.wait_for_timeout(900);shot('reduced-second');check(state()['brasa']['idle_time']==reduced['brasa']['idle_time'],'Reduced motion freezes the live Brasa idle clock')
  scale=reduced['room']['scene_scale'];origin=reduced['room']['scene_origin'];foot=reduced['brasa']['world_foot'];x=origin[0]+foot[0]*scale;y=origin[1]+foot[1]*scale;box=(max(0,int(x-180*scale)),max(0,int(y-280*scale)),min(1600,int(x+180*scale)),min(900,int(y+20*scale)));check(Image.open(out/'reduced-first.png').crop(box).tobytes()==Image.open(out/'reduced-second.png').crop(box).tobytes(),'Rendered Brasa pixels are unchanged while reduced motion is enabled')
  walk('a',120);check(state()['speed']==330 and state()['gather']==0 and state()['cycle']==.5,'Reduced motion retains logical speed and suppresses Pietro gait');click('motion');wait('!window.pietroHouseStudy.reduced && !window.pietroHouseStudy.brasa.reduced_motion');page.wait_for_timeout(700);check(state()['brasa']['idle_time']>reduced['brasa']['idle_time'],'Brasa resumes after restoring motion')
  game_after=page.evaluate('JSON.stringify([window.umbralState.party,window.umbralState.stats,window.umbralState.expedition,window.umbralState.checkpoint_status])');check(game_after==game_before,'Walking and accessibility preserve party, stats, expedition and checkpoint')
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
report={'scope':'Opt-in experiment in current house; scenery not approved; normal logical speed and reduced motion; no slow controller mode or production replacement','checks':len(checks),'passed':checks,'failed':int(failure is not None),'failure':failure,'errors':errors,'captures':captures,'observations':observations,'video':video};(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['checks','failed','failure','video']}))
if failure:raise SystemExit(failure)
