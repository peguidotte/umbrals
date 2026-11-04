"""Bake the approved v5 poses into engine data and promote exact production assets.

Character geometry, effects and audio retain separate asset owners. The runtime
root pins those dependencies; the original atlases and prototype stay intact.
"""
import hashlib
import json
import shutil
import subprocess
import threading
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[2]
EFFECT = ROOT / 'assets/attacks/woodland-elements/versions/1.1.0'
CHARACTER = ROOT / 'assets/characters/battle-motion/versions/1.0.0'
AUDIO = ROOT / 'assets/audio/battle-performances/versions/1.0.0'


def record(path, kind, provenance):
    return {'path': path.name, 'kind': kind, 'bytes': path.stat().st_size,
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'provenance': provenance}


def unpublished(folder):
    check = subprocess.run(['git', 'cat-file', '-e', 'origin/main:'+
        str((folder/'manifest.json').relative_to(ROOT))], cwd=ROOT, capture_output=True)
    if check.returncode == 0:
        raise RuntimeError(f'Published version is immutable: {folder}')
    folder.mkdir(parents=True, exist_ok=True)


def main():
    for folder in [EFFECT, CHARACTER, AUDIO]:
        unpublished(folder)
    subprocess.run(['python','tools/asset_authoring/build_attack_studies.py',
                    '--revision','5','--html-only'], cwd=ROOT, check=True)
    class Handler(SimpleHTTPRequestHandler):
        def log_message(self, *_args):
            pass
    server = ThreadingHTTPServer(('127.0.0.1',0),partial(
        Handler,directory=str(ROOT/'builds/attack-studies-v5')))
    threading.Thread(target=server.serve_forever,daemon=True).start()
    with sync_playwright() as p:
        browser=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox'])
        page=browser.new_page()
        page.goto(f'http://127.0.0.1:{server.server_port}/galeria.html')
        page.wait_for_function('window.loaded')
        page.evaluate('window.exportMode=true')
        baked=page.evaluate('''()=>{
            const channels=['x','y','rotation','sx','sy','bob','inflate','blink','head','tail','fore','hind','crest','ear','jaw','wing','feeler','bough','fin','reach'];
            const pack=(p,reach=0)=>channels.map(k=>Math.round((k==='x'?p.x-121:k==='y'?p.y-267:k==='reach'?reach:p[k]||0)*100000)/100000);
            const forms={};
            for(const id of Object.keys(Anatomy.forms)){
                const rest=MotionV5.idle(id,0), attacks={}, reactions={}, states={};
                for(let index=0;index<15;index++){
                    attacks[index]=[];reactions[index]=[];
                    const spec=MotionV5.specs[index];
                    for(let frame=0;frame<=96;frame++){
                        const t=frame/30,p=MotionV5.pose(index,t,id),z=MotionV5.sample(index,t);
                        const reach=index>=12?MotionV5.out(z.u)*(1-smooth(MotionV5.range(t,spec.contact+.26,2.55))):0;
                        attacks[index].push(pack(p,reach));
                    }
                    for(let frame=0;frame<=60;frame++){
                        const p=MotionV5.reaction(id,index,spec.contact+frame/30);p.x+=121;
                        reactions[index].push(pack(p));
                    }
                }
                for(let state=0;state<6;state++)states[state]=Array.from({length:97},(_,f)=>pack(MotionV5.life(id,state,f/30)));
                const posed=MotionV5.pose(13,1.12,id);
                forms[id]={anatomy:Anatomy.forms[id],profile:MotionV5.profiles[id],joints:posed.joints,ground:rest.ground,attacks,reactions,states};
            }
            const rects=[];
            for(let n=0;n<16;n++){
                const img=assets.vfxAtlas,x=Math.round(n%4*img.width/4),y=Math.round(Math.floor(n/4)*img.height/4),w=Math.round((n%4+1)*img.width/4)-x,h=Math.round((Math.floor(n/4)+1)*img.height/4)-y;
                const cv=document.createElement('canvas');cv.width=w;cv.height=h;const c=cv.getContext('2d');c.drawImage(img,x,y,w,h,0,0,w,h);const rgba=c.getImageData(0,0,w,h).data;
                let l=w,t=h,r=0,b=0;for(let yy=0;yy<h;yy++)for(let xx=0;xx<w;xx++)if(rgba[(yy*w+xx)*4+3]>16){l=Math.min(l,xx);t=Math.min(t,yy);r=Math.max(r,xx);b=Math.max(b,yy);}
                rects.push([x+l,y+t,r-l+1,b-t+1]);
            }
            return {motion:{schema:1,fps:30,channels,forms},effects:{schema:1,rects,specs:MotionV5.specs,parts:RigStudy.specs.map(s=>s.part)}};
        }''')
        browser.close()
    server.shutdown()
    # Source x includes the study's 300-unit dash. Runtime replaces that component
    # with the actual source-to-target vector; local rotation/foot offsets survive.
    (CHARACTER/'motion.json').write_text(json.dumps(baked['motion'],separators=(',',':')))
    (EFFECT/'performances.json').write_text(json.dumps(baked['effects'],ensure_ascii=False,separators=(',',':')))
    source=ROOT/'assets/attacks/woodland-elements/versions/1.0.0'
    original=json.loads((source/'manifest.json').read_text())
    promoted=json.loads(json.dumps(original));promoted.update(version='1.1.0',status='production',
        changes='Approved v5 elemental performances, event clocks and pinned character/audio dependencies.',
        dependencies=[{'id':'characters/battle-motion','version':'1.0.0'},
                      {'id':'audio/battle-performances','version':'1.0.0'}])
    for item in promoted['files'].values():
        shutil.copyfile(source/item['path'],EFFECT/item['path'])
    provenance={'kind':'Approved v5 Canvas choreography exported for native Godot presentation',
        'source_files':{name:hashlib.sha256((ROOT/'tools/asset_authoring'/name).read_bytes()).hexdigest()
            for name in ['attack_personalities.js','umbral_anatomy.js','attack_actor_rig.js','attack_choreography.json']},
        'approval':'User approved the v5 preview and requested game/main integration.'}
    promoted['files']['performances']=record(EFFECT/'performances.json','data',provenance)
    (EFFECT/'manifest.json').write_text(json.dumps(promoted,indent=2)+'\n')
    character={'schema_version':1,'id':'characters/battle-motion','version':'1.0.0','status':'production',
        'description':'Eight anatomical rigs, fifteen cast tracks and material-aware reactions, approved v5.',
        'dependencies':[{'id':'characters/battle-creatures','version':'1.0.0'},
                        {'id':'characters/battle-evolved','version':'1.0.0'}],
        'files':{'motion':record(CHARACTER/'motion.json','data',provenance)},'provenance':provenance}
    (CHARACTER/'manifest.json').write_text(json.dumps(character,indent=2)+'\n')
    sounds={'schema_version':1,'id':'audio/battle-performances','version':'1.0.0','status':'production',
        'description':'Fifteen original stereo attack performances, synchronized with approved v5 event clocks.',
        'dependencies':[],'files':{},'provenance':{'kind':'Original deterministic synthesis; no external samples.',
        'source_sha256':hashlib.sha256((ROOT/'tools/asset_authoring/attack_study_audio.py').read_bytes()).hexdigest()}}
    for i in range(15):
        file=AUDIO/f'{i+1:02d}.wav';shutil.copyfile(ROOT/f'builds/attack-studies-v5/audio/{i+1:02d}.wav',file)
        sounds['files'][f'performance-{i+1:02d}']=record(file,'audio',sounds['provenance'])
    (AUDIO/'manifest.json').write_text(json.dumps(sounds,indent=2)+'\n')
    lock_path=ROOT/'assets/runtime-lock.json';lock=json.loads(lock_path.read_text())
    lock['bindings']['attacks/battle-performances']={'id':'attacks/woodland-elements','version':'1.1.0','file':'source-atlas'}
    lock_path.write_text(json.dumps(lock,indent=2,sort_keys=True)+'\n')
    print('Exported native motion data, promoted effects and synchronized audio; root pin set explicitly.')


if __name__=='__main__':
    main()
