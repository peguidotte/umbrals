"""Capture the complete native actor cycle after its first visible frame."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--adults', action='store_true')
    parser.add_argument('--form', choices=['auravel', 'zuldar'])
    parser.add_argument('--resolution', choices=['1600x900', '1280x720'], default='1600x900')
    args = parser.parse_args()
    if not os.environ.get('DISPLAY'):
        raise SystemExit('A real or Xvfb X11 display is required; no fixed-fps movie substitution')
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    for name in ['ready.flag', 'begin.flag']:
        (output / name).unlink(missing_ok=True)
    command = ['godot', '--path', str(ROOT), '--rendering-method', 'gl_compatibility',
        '--audio-driver', 'Dummy', '--max-fps', '60', '--resolution', args.resolution, '--position', '0,0',
        'res://tests/electric_states_preview.tscn', '--', '--native-review', str(output), '--capture-ready']
    if args.adults: command.append('--adults')
    if args.form: command.extend(['--form', args.form])
    display = os.environ['DISPLAY'].split('.')[0] + '.0+0,0'
    record = ['ffmpeg', '-v', 'error', '-y', '-f', 'x11grab', '-framerate', '30',
        '-video_size', args.resolution, '-i', display, '-filter_threads', '1', '-filter_complex_threads', '1',
        '-c:v', 'libx264', '-threads', '1', '-preset', 'ultrafast', '-crf', '20',
        '-pix_fmt', 'yuv420p', str(output / 'native-states.mp4')]
    recorder = None
    with (output / 'godot.log').open('w') as game_log, (output / 'capture.log').open('w') as log:
        game = subprocess.Popen(command, stdout=game_log, stderr=game_log)
        try:
            deadline = time.monotonic() + 70
            while not (output / 'ready.flag').exists():
                if game.poll() is not None: raise RuntimeError('Game exited before its first visible frame')
                if time.monotonic() >= deadline: raise TimeoutError('No first visible frame')
                time.sleep(.1)
            recorder = subprocess.Popen(record, stdin=subprocess.PIPE, stdout=log, stderr=log)
            time.sleep(.6)
            (output / 'begin.flag').write_text('Begin the full real-time cycle after recording is armed')
            game.wait(timeout=55)
            recorder.communicate(b'q\n', timeout=30)
            if game.returncode: raise RuntimeError('Godot failed; see retained godot.log')
        finally:
            if game.poll() is None: game.terminate(); game.wait(timeout=10)
            if recorder is not None and recorder.poll() is None: recorder.terminate(); recorder.wait(timeout=10)
    if 'SCRIPT ERROR:' in (output / 'godot.log').read_text(): raise RuntimeError('Godot script error; see retained log')
    video = output / 'native-states.mp4'
    probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries',
        'stream=avg_frame_rate,nb_frames,width,height:format=duration', '-of', 'json', str(video)], text=True))
    black = subprocess.run(['ffmpeg', '-hide_banner', '-i', str(video), '-vf',
        'blackdetect=d=0.2:pix_th=0.05', '-an', '-f', 'null', '-'], capture_output=True, text=True, check=True).stderr
    intervals = [dict(start=float(a), end=float(b), duration=float(c)) for a,b,c in
        re.findall(r'black_start:([\d.]+) black_end:([\d.]+) black_duration:([\d.]+)', black)]
    report = dict(head=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        command=command, record=record, probe=probe, black_intervals=intervals, full_cycle_seconds=22.4,
        readiness='First rendered frame, then screen recorder, then explicit cycle start',
        snapshots='Extracted from the actual MP4 after recording; PNG readbacks disabled during motion')
    (output / 'capture-provenance.json').write_text(json.dumps(report, indent=2))
    if float(probe['format']['duration']) < 22.4: raise RuntimeError('Native video cuts the complete cycle')
    if any(i['start'] < .1 and i['duration'] > .5 for i in intervals): raise RuntimeError('Native video begins with black frames')
    for phase in range(7):
        stamp = .7 + phase * 3.2 + (.15 if phase == 2 else .9)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(stamp), '-i', str(video),
            '-frames:v', '1', '-threads', '1', str(output / ('state-%d.png' % phase))], check=True)
    print(video)


if __name__ == '__main__':
    main()
