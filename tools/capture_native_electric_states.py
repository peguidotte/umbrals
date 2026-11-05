"""Capture the actual native actor scene in real time, with cadence telemetry."""
import argparse
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--adults', action='store_true')
    parser.add_argument('--form', choices=['auravel', 'zuldar'])
    args = parser.parse_args()
    if not os.environ.get('DISPLAY'):
        raise SystemExit('A real or Xvfb X11 display is required; no fixed-fps movie substitution')
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    with (output / 'capture.log').open('w') as log:
        display = os.environ['DISPLAY'].split('.')[0] + '.0+0,0'
        recorder = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'x11grab',
            '-framerate', '30', '-video_size', '1600x900', '-i', display, '-t', '26',
            '-c:v', 'libx264', '-threads', '1', '-preset', 'ultrafast', '-crf', '20',
            '-pix_fmt', 'yuv420p', str(output / 'native-states.mp4')], stdout=log, stderr=log)
        try:
            game = subprocess.run(['godot', '--path', str(ROOT), '--rendering-method', 'gl_compatibility',
                '--audio-driver', 'Dummy', '--max-fps', '60', '--resolution', '1600x900', '--position', '0,0',
                'res://tests/electric_states_preview.tscn', '--', '--native-review', str(output)] + (['--adults'] if args.adults else []) + (['--form', args.form] if args.form else []),
                capture_output=True, text=True, timeout=60)
            (output / 'godot.log').write_text(game.stdout + game.stderr)
            recorder.wait(timeout=40)
            if game.returncode or 'SCRIPT ERROR:' in game.stderr:
                raise RuntimeError(game.stderr[-6000:])
        finally:
            if recorder.poll() is None:
                recorder.terminate()
                recorder.wait(timeout=10)
    print(output / 'native-states.mp4')


if __name__ == '__main__':
    main()
