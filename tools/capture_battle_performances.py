"""Record the integrated game through validated fixture snapshots and real clicks.

Uses the existing disposable fixture export. The production browser bridge stays
read-only. Audio is captured from the actual WebAudio output, never added later.
"""
import argparse
import base64
import json
import re
import subprocess
from pathlib import Path
from types import SimpleNamespace

from browser.session import Session

AUDIO_CAPTURE = r'''(() => {
    if (!window.AudioContext && !window.webkitAudioContext) return;
    window.__gameAudioContexts=[];
    const connect = AudioNode.prototype.connect;
    AudioNode.prototype.connect = function(destination, ...args) {
        const context=this.context;
        if (destination === context.destination) {
            if(!context.__recordOutput){
                context.__recordOutput=context.createMediaStreamDestination();
                window.__gameAudioContexts.push(context);
            }
            // Identical connections are idempotent; Godot may rebuild a bus.
            connect.call(this, context.__recordOutput);
            context.__recordedNodes=(context.__recordedNodes||0)+1;
            window.__gameAudio=context;
        }
        return connect.call(this, destination, ...args);
    };
})()'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--build-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--forms', default='ember,ignivar,moss,verdalio,dew,mareveu,volt,tempestral')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    settings = SimpleNamespace(output=args.output, build_dir=args.build_dir,
        viewport='1600x900', video=False, large_text=False, fixture=None, scenario='combat', capture_audio=True)
    session = Session(settings)
    session.context.add_init_script(AUDIO_CAPTURE)
    records = []
    powers = {'ember':['fireball'], 'ignivar':['fireball'], 'moss':['thorn_lash'],
              'verdalio':['thorn_lash'], 'dew':['tidal_splash'], 'mareveu':['tidal_splash'],
              'volt':['lightning','storm_dive'], 'tempestral':['lightning','storm_dive'], 'auravel':['lightning','storm_dive'], 'zuldar':['lightning','storm_dive']}
    try:
        for form in args.forms.split(','):
            assert form in powers, form
            session.fixture('motion_' + form)
            session.page.evaluate('''() => {
                const audio = window.__gameAudio;
                if (!audio) throw new Error('The actual game AudioContext was not observed');
                const stream = document.querySelector('canvas').captureStream(30);
                audio.__recordOutput.stream.getAudioTracks().forEach(track => stream.addTrack(track));
                const mimeType = MediaRecorder.isTypeSupported('video/webm;codecs=vp9,opus') ? 'video/webm;codecs=vp9,opus' : 'video/webm;codecs=vp8,opus';
                const recorder = new MediaRecorder(stream,{mimeType,videoBitsPerSecond:4500000,audioBitsPerSecond:160000});
                const chunks=[]; recorder.ondataavailable=e=>{if(e.data.size)chunks.push(e.data)};
                window.__recording={recorder,chunks};recorder.start(200);
            }''')
            for round_index in range(3):
                state = session.state()
                for power in powers[form]:
                    index = next(i for i,card in enumerate(state['hand']) if card['power'] == power)
                    session.click('hand.' + str(index))
                    session.click('enemy.1')
                session.page.keyboard.press('Space')
                session.wait('window.umbralState.busy')
                session.page.wait_for_timeout(900)
                name=f'{form}-{round_index+1}-cast'
                session.page.screenshot(path=str(args.output/(name+'.png')))
                (args.output/(name+'.state.json')).write_text(json.dumps(session.state(),indent=2))
                session.settled()
                session.check(session.state()['actions']==round_index+1, 'Only real committed turns advance the capture')
            encoded = session.page.evaluate('''async () => {
                const {recorder,chunks}=window.__recording;
                await new Promise(resolve=>{recorder.onstop=resolve;recorder.stop()});
                return await new Promise(resolve=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result.slice(reader.result.indexOf('base64,')+7));reader.readAsDataURL(new Blob(chunks,{type:recorder.mimeType}))});
            }''')
            raw=args.output/(form+'.webm');raw.write_bytes(base64.b64decode(encoded))
            target=args.output/(form+'.mp4')
            subprocess.run(['ffmpeg','-v','error','-y','-i',str(raw),'-c:v','libx264',
                '-crf','19','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k',
                '-movflags','+faststart',str(target)],check=True)
            volume=subprocess.run(['ffmpeg','-hide_banner','-i',str(raw),'-vn',
                '-af','volumedetect','-f','null','-'],capture_output=True,text=True,check=True).stderr
            peak=re.search(r'max_volume: ([-\d.]+) dB',volume)
            assert peak and float(peak.group(1)) > -60, 'Captured audio is silent or below a useful level'
            record={'form':form,'power_ids':powers[form],'rounds':3,
                'performances':3*len(powers[form]),'video':target.name,
                'audio_source':'Actual game WebAudio output, including its SFX/Music buses.',
                'audio_levels':[line.strip() for line in volume.splitlines() if '_volume:' in line]}
            records.append(record)
            (args.output/'capture-report.json').write_text(json.dumps({'records':records,'errors':session.errors},indent=2))
            print(json.dumps(record),flush=True)
        assert not session.errors, session.errors
        frames=args.output/'clips.txt'
        frames.write_text('\n'.join("file '"+str((args.output/r['video']).resolve())+"'" for r in records))
        subprocess.run(['ffmpeg','-v','error','-y','-f','concat','-safe','0','-i',str(frames),
            '-c','copy','-movflags','+faststart',str(args.output/'combate-integrado.mp4')],check=True)
    finally:
        session.browser.close()
        session.playwright.stop()
        session.server.shutdown()


if __name__=='__main__':
    main()
