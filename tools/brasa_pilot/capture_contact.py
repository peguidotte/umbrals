"""Capture the same production actor diagnostic in native Godot and real Web canvas."""
import argparse
import base64
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from browser.session import Session
from asset_pipeline import ROOT, digest


def run(command, cwd, log):
    with log.open('w') as output:
        result = subprocess.run(command, cwd=cwd, stdout=output, stderr=subprocess.STDOUT)
    text = log.read_text()
    if result.returncode or 'SCRIPT ERROR:' in text or '\nERROR:' in text:
        raise RuntimeError(f'Capture command failed; see {log}')


def analyze(samples):
    result = []
    for body in range(6):
        rows = [(i, row['bodies'][body]) for i, row in enumerate(samples) if row['bodies'][body]['state'] == 'walk']
        frames = sorted({row['frame'] for i, row in rows})
        if frames != list(range(8)): raise AssertionError(f'Incomplete walk: view {body}: {frames}')
        drift = 0
        dwell = []
        for frame in frames:
            group = [(i, row) for i, row in rows if row['frame'] == frame]
            points = [row['contact'] for i, row in group]
            drift = max(drift, max(abs(p[0]-points[0][0]) for p in points))
            dwell.append(sum(samples[i]['delta'] for i, row in group))
        for support in ['stance_a','stance_b']:
            points = [row['contact'] for i,row in rows if row['support']==support]
            drift = max(drift, max(abs(p[0]-points[0][0]) for p in points))
        if drift > .05: raise AssertionError(f'Contact drift in rendered samples: {drift}')
        if any(row['mesh_alpha'] != 0 or row['sprite_alpha'] != 1 for i,row in rows): raise AssertionError('Two silhouettes')
        result.append({'view':body,'indices_sampled':frames,'designated_contact_drift_pixels':drift,'sampled_dwell_seconds_by_pose':dwell})
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--native-only',action='store_true')
    args=p.parse_args();out=args.output.resolve();out.mkdir(parents=True,exist_ok=True);(out/'.gdignore').touch()
    native=out/'native';native.mkdir(exist_ok=True)
    native_project=out/'native-project';native_project.mkdir()
    for name in ['scripts','assets','content','scenes','tools','.godot']:
        (native_project/name).symlink_to(ROOT/name,target_is_directory=True)
    native_config=(ROOT/'project.godot').read_text().replace('window/size/window_width_override=1280','window/size/window_width_override=1600').replace('window/size/window_height_override=720','window/size/window_height_override=900')
    (native_project/'project.godot').write_text(native_config)
    run(['godot','--path',str(native_project),'--audio-driver','Dummy','--fixed-fps','30','--write-movie',str(native/'capture.avi'),
         'res://tools/brasa_pilot/review_contact.tscn','--','--autoplay','--output='+str(native)],native_project,out/'native.log')
    run(['ffmpeg','-v','error','-y','-i',str(native/'capture.avi'),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(native/'brasa-contact-native.mp4')],ROOT,out/'native-encode.log')
    native_data=json.loads((native/'samples.json').read_text())
    report={'native':analyze(native_data['samples']),'native_engine':native_data['engine'],
            'scope':'Engine samples from a diagnostic scene using production actors. Sampled indices do not prove that every pose appears in an encoded canvas video. Decode and inspect the video separately. Integrated gameplay evidence is separate.',
            'video_pose_coverage':'requires independent decoded-pixel inspection'}
    if not args.native_only:
        project=out/'review-project';project.mkdir()
        for name in ['scripts','assets','content','scenes']:
            shutil.copytree(ROOT/name,project/name,ignore=shutil.ignore_patterns('*.uid','*.import'))
        shutil.copy2(ROOT/'tools/brasa_pilot/review_contact.gd',project/'scripts/ui/review_contact.gd')
        scene=(ROOT/'tools/brasa_pilot/review_contact.tscn').read_text().replace('res://tools/brasa_pilot/review_contact.gd','res://scripts/ui/review_contact.gd')
        (project/'scenes/review_contact.tscn').write_text(scene)
        config=(ROOT/'project.godot').read_text().replace('res://scenes/main.tscn','res://scenes/review_contact.tscn')
        (project/'project.godot').write_text(config+'\n[editor]\nimport/use_multiple_threads=false\n')
        shutil.copy2(ROOT/'export_presets.cfg',project/'export_presets.cfg')
        # Reuse valid content-addressed imports, while keeping the diagnostic boot isolated.
        if (ROOT/'.godot').is_dir(): shutil.copytree(ROOT/'.godot',project/'.godot')
        web=out/'web-build';web.mkdir()
        run(['godot','--headless','--path',str(project),'--editor','--import','--quit'],project,out/'web-import.log')
        run(['godot','--headless','--path',str(project),'--export-release','Web',str(web/'index.html')],project,out/'web-export.log')
        captures=out/'web';captures.mkdir()
        session=Session(SimpleNamespace(output=captures,build_dir=web,viewport='1600x900',video=False,large_text=False,fixture=None,scenario='combat',capture_audio=False))
        try:
            session.page.goto(session.base_url)
            session.page.wait_for_function('window.brasaReview?.phase === "ready"',timeout=120000)
            session.page.evaluate('''() => {
                const recorder=new MediaRecorder(document.querySelector('canvas').captureStream(30),{mimeType:'video/webm;codecs=vp8',videoBitsPerSecond:6000000});
                const chunks=[];recorder.ondataavailable=e=>{if(e.data.size)chunks.push(e.data)};
                window.__brasaVideo={recorder,chunks};recorder.start(100);
            }''')
            session.page.mouse.click(800,847)
            session.page.wait_for_function('window.brasaReview?.phase === "done"',timeout=120000)
            state=session.page.evaluate('window.brasaReview')
            encoded=session.page.evaluate('''async () => {
                const {recorder,chunks}=window.__brasaVideo;
                await new Promise(r=>{recorder.onstop=r;recorder.stop()});
                return await new Promise(r=>{const reader=new FileReader();reader.onload=()=>r(reader.result.split('base64,')[1]);reader.readAsDataURL(new Blob(chunks,{type:recorder.mimeType}))});
            }''')
            (captures/'capture.webm').write_bytes(base64.b64decode(encoded))
            (captures/'samples.json').write_text(json.dumps(state,indent=2))
            session.page.screenshot(path=str(captures/'recovered.png'))
            report['web']=analyze(state['samples'])
            report['web_errors']=session.errors
            if session.errors: raise AssertionError(session.errors)
            run(['ffmpeg','-v','error','-y','-i',str(captures/'capture.webm'),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(captures/'brasa-contact-web.mp4')],ROOT,out/'web-encode.log')
        finally:
            session.browser.close();session.playwright.stop();session.server.shutdown()
    report['source_hashes']={str(p.relative_to(ROOT)):digest(p) for p in [ROOT/'scripts/ui/creature_lifecycle.gd',ROOT/'scripts/ui/creature_rig.gd',ROOT/'tools/brasa_pilot/review_contact.gd',ROOT/'assets/runtime-lock.json']}
    (out/'cadence-report.json').write_text(json.dumps(report,indent=2))
    print(json.dumps({'report':str(out/'cadence-report.json'),'native_video':str(native/'brasa-contact-native.mp4')}))


if __name__=='__main__': main()
