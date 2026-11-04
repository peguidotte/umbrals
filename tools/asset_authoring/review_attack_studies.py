"""Validate exported choreography media, assemble a comparison and ZIP."""
from pathlib import Path
import argparse
import importlib.util
import json
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'builds/attack-studies-v2'


def main(revision=2):
    global OUT
    OUT=ROOT/'builds'/f'attack-studies-v{revision}'
    path = ROOT / '.agents/skills/game-vfx/scripts/validate_vfx_spec.py'
    module_spec = importlib.util.spec_from_file_location('vfx_spec', path)
    validator = importlib.util.module_from_spec(module_spec)
    module_spec.loader.exec_module(validator)
    motion = json.loads((OUT / 'rig-motion.json').read_text())
    durations = [1450,1750,1650,1700,1900,1800,1400,1850,1800,1300,1650,1700,1850,2100,2000]
    specs = OUT / 'performance-specs'
    specs.mkdir(exist_ok=True)
    for i, entry in enumerate(motion):
        duration = durations[i]
        packet = {
            'name': f'attack-study-v{revision}-{i+1:02d}', 'duration_ms': duration,
            'source': entry['source'], 'phases': [
                {'id': name, 'start_ms': round(a*duration), 'end_ms': round(b*duration)}
                for name,a,b in [('preparation',0,.25),('emission',.25,.35),('travel',.35,.66),('impact',.66,.84),('recovery',.84,1)]
            ],
            'layers': [
                {'id':'sprite-skin', 'type':'canvas-triangle-mesh', 'max_particles':0, 'draw_calls':392},
                {'id':'motion-echoes', 'type':'canvas-triangle-mesh', 'max_particles':0, 'draw_calls':784},
                {'id':'materials', 'type':'textured-mesh-and-fragments' if revision>=4 else 'procedural-vector', 'max_particles':96 if revision>=3 else 64, 'draw_calls':700 if revision>=3 else 450},
                {'id':'environment', 'type':'original-sprites', 'max_particles':0, 'draw_calls':16}
            ],
            'budgets': {'max_particles':96 if revision>=3 else 64,'max_draw_calls':2000 if revision>=3 else 1700,'max_overdraw':8,'max_blur_radius':0},
            'budget_status':'Conservative Canvas design caps, not GPU profiling or Godot budgets.',
            'reduced_motion':{'enabled':True,'behavior':'Rest pose, no joint motion, no travel, no echoes; retain static source and target markers.'},
            'audio':False, 'rig':entry['poses']
        }
        if revision >= 5:
            packet['layers'].append({'id':'target-skins','type':'species-specific-mesh-reaction','max_particles':0,'draw_calls':784})
            packet['budgets']['max_draw_calls']=3000
            packet['audio']=True
            packet['duration_ms']=3200
            events=json.loads((OUT/'choreography.json').read_text())[i]
            packet['phases']=[{'id':'preparation','start_ms':200,'end_ms':round(events['release']*1000)},{'id':'travel','start_ms':round(events['release']*1000),'end_ms':round(events['contact']*1000)},{'id':'contact-hold','start_ms':round(events['contact']*1000),'end_ms':round((events['contact']+events['hold'])*1000)},{'id':'consequence','start_ms':round((events['contact']+events['hold'])*1000),'end_ms':2650}]
        validator.validate(packet)
        (specs / f'{i+1:02d}.json').write_text(json.dumps(packet,indent=2,ensure_ascii=False))
    if revision >= 5:
        # Five complete gestures, with dead time trimmed; one accessible short reel.
        command=['ffmpeg','-v','error','-y']
        for clip in ['02','05','08','10','14']:
            command += ['-i',str(OUT/f'{clip}.mp4')]
        filters=[]
        for i in range(5):
            filters += [f'[{i}:v]trim=start_frame=3:end_frame=84,setpts=PTS-STARTPTS[v{i}]',
                        f'[{i}:a]atrim=start=0.1:end=2.8,asetpts=PTS-STARTPTS[a{i}]']
        filters += [''.join(f'[v{i}][a{i}]' for i in range(5))+'concat=n=5:v=1:a=1[v][a]']
        command += ['-filter_complex',';'.join(filters),'-map','[v]','-map','[a]',
                    '-c:v','libx264','-crf','18','-pix_fmt','yuv420p',
                    '-c:a','aac','-b:a','160k','-movflags','+faststart',str(OUT/'destaques-com-som.mp4')]
        subprocess.run(command,check=True)
    media = []
    for video in sorted(OUT.glob('*.mp4')):
        if video.name == 'antes-depois-cauda.mp4':
            continue
        info = json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=width,height,nb_frames:format=duration','-of','json',str(video)]))
        expected = 1440 if video.name == '15-animacoes.mp4' else 576 if video.name=='vida-umbrals.mp4' else 405 if video.name=='destaques-com-som.mp4' else 96
        assert int(info['streams'][0]['nb_frames']) == expected, video
        subprocess.run(['ffmpeg','-v','error','-i',str(video),'-f','null','-'],check=True)
        if revision>=5 and video.name not in ['vida-umbrals.mp4','comparativo.mp4']:
            audio_info=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','a:0','-show_entries','stream=codec_name,sample_rate,channels','-of','json',str(video)]))
            assert audio_info['streams'] and audio_info['streams'][0]['channels']==2,video
            info['audio']=audio_info['streams'][0]
        media.append({'file':video.name,**info})
    # The previous take remains intact; scale/time labels are baked only into the comparison.
    comparison = OUT / 'antes-depois-cauda.mp4'
    previous=ROOT/'builds'/(f'attack-studies-v{revision-1}' if revision>=3 else 'attack-studies-v1')/'02.mp4'
    left=f'ANTES - revisao {revision-1}' if revision>=3 else 'ANTES - sprite inteiro'
    right=f'AGORA - revisao {revision}' if revision>=3 else 'AGORA - cauda e contrapeso'
    subprocess.run([
        'ffmpeg','-v','error','-y','-stream_loop','-1','-i',str(previous),
        '-i',str(OUT/'02.mp4'),'-filter_complex',
        f"[0:v]fps=30,drawtext=text='{left}':x=18:y=46:fontsize=18:fontcolor=white:box=1:boxcolor=black@0.7[a];[1:v]drawtext=text='{right}':x=18:y=46:fontsize=18:fontcolor=white:box=1:boxcolor=black@0.7[b];[a][b]hstack=inputs=2[v]",
        '-map','[v]','-t','3.2','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(comparison)
    ],check=True)
    # Keep the HTML caption in sync with the source; this does not alter rendered choreography.
    gallery = OUT/'galeria.html'
    gallery_text=gallery.read_text().replace('Mandíbula e patas compensam','Cabeça e patas compensam')
    if revision>=5:
        gallery_text=gallery_text.replace('Revisão 04:', 'Revisão 05: personalidade, peso, reações por espécie e som;')
    gallery.write_text(gallery_text)
    review_path = OUT / 'review.json'
    review = json.loads(review_path.read_text())
    review.update({'validated_vfx_packets':15,'decoded_media':media,'visual_review':[
        'Compared six poses of the tail cast: windup, local tail sweep, hip/body counterrotation, emission and rest.',
        'Reviewed enlarged source and target frames for Ignivar and Mareveu; no visible mesh cracks at review scale.',
        'Reviewed desktop gallery and 390px capture; emission labels and controls remain available.',
        'First v2 take retained as attack-studies-v2-pass1; roots revised from triangular forms to branching bark and leaves.'
    ] if revision==2 else []})
    review_path.write_text(json.dumps(review,indent=2,ensure_ascii=False))
    archive = OUT / f'umbral-animacoes-v{revision}.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for file in sorted(OUT.rglob('*')):
            if any(part.startswith('frame-cache') for part in file.relative_to(OUT).parts):
                continue
            if file.is_file() and file != archive and file.suffix in ['.html','.mp4','.gif','.json','.txt','.wav']:
                z.write(file,file.relative_to(OUT))
    print(json.dumps({'validated_vfx_packets':15,'decoded_videos':len(media),'comparison':str(comparison),'archive_mb':round(archive.stat().st_size/1024**2,1)},indent=2))


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--revision',type=int,choices=[2,3,4,5],default=2)
    main(parser.parse_args().revision)
