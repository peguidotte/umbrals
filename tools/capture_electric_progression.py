"""Review both explicit adult choices and owned attacks through actual UI input."""
import argparse
import json
import os
from pathlib import Path
import subprocess
from types import SimpleNamespace

from browser.session import Session


def start_recording(session, path):
    region = session.page.evaluate('''() => {const r=document.querySelector('canvas').getBoundingClientRect();return {x:Math.round(window.screenX+r.left),y:Math.round(window.screenY+window.outerHeight-window.innerHeight+r.top)}}''')
    display = os.environ['DISPLAY'].split('.')[0] + '.0+' + str(region['x']) + ',' + str(region['y'])
    log = path.with_suffix('.capture.log').open('w')
    recorder = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'x11grab', '-framerate', '30',
        '-video_size', '1280x720', '-i', display, '-filter_threads', '1', '-filter_complex_threads', '1', '-c:v', 'libx264', '-threads', '1', '-preset',
        'ultrafast', '-crf', '20', '-pix_fmt', 'yuv420p', str(path)], stdin=subprocess.PIPE, stdout=log, stderr=log)
    return recorder, log


def stop_recording(recorder, log, path):
    recorder.communicate(b'q\n', timeout=30)
    log.close()
    probe = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries',
        'stream=avg_frame_rate,nb_frames,width,height:format=duration', '-of', 'json', str(path)],
        capture_output=True, text=True, check=True)
    return json.loads(probe.stdout)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    settings = SimpleNamespace(output=args.output, build_dir=args.build_dir, viewport='1280x720',
        video=False, large_text=False, fixture=None, scenario='electric-family', native_gl=True)
    session = Session(settings)
    records = []
    failure = None
    recorder = None
    try:
        for form in ['auravel', 'zuldar']:
            session.fixture('electric_branches')
            state = session.state()
            before = state['party'][0]
            offers = state['offers']
            session.check([o['target_form_id'] for o in offers if o['kind'] == 'evolve'] == ['auravel', 'zuldar'], 'Both explicit adult choices are offered together')
            chosen = next(i for i, offer in enumerate(offers) if offer.get('target_form_id') == form)
            path = args.output / (form + '-evolution.mp4')
            recorder, log = start_recording(session, path)
            session.page.wait_for_timeout(1200)
            session.shot(form + '-choices')
            session.click('reward.' + str(chosen))
            session.wait("window.umbralState.screen === 'map'")
            after = session.state()['party'][0]
            session.check(after['form_id'] == form and after['uid'] == before['uid'] and after['passive'] == before['passive'], 'Chosen adult keeps individual UID and passive')
            session.check(session.state()['checkpoint_status'] == 'ok', 'Adult choice is checkpointed')
            session.click('map.node.thicket')
            session.click('map.confirm')
            session.wait("window.umbralState.screen === 'battle'")
            session.check(session.state()['party'][0]['form_id'] == form, 'The selected adult enters the next real encounter')
            session.shot(form + '-next-encounter')
            session.page.wait_for_timeout(2200)
            probe = stop_recording(recorder, log, path)
            recorder = None
            records.append(dict(form=form, kind='evolution-to-encounter', video=path.name, probe=probe))

            session.fixture('motion_' + form)
            path = args.output / (form + '-owned-attacks.mp4')
            recorder, log = start_recording(session, path)
            for round_index in range(3):
                state = session.state()
                for power in ['lightning', 'storm_dive']:
                    index = next(i for i, card in enumerate(state['hand']) if card['power'] == power)
                    session.click('hand.' + str(index))
                    session.click('enemy.1')
                session.page.keyboard.press('Space')
                session.wait('window.umbralState.busy')
                session.page.wait_for_timeout(900)
                session.page.screenshot(path=str(args.output / (form + '-cast-' + str(round_index + 1) + '.png')))
                session.settled()
                session.check(session.state()['actions'] == round_index + 1, 'Only committed owned powers advance the actual turn')
            cadence = session.page.evaluate('window.fixtureCadence || []')
            session.check(bool(cadence), 'The actual engine publishes rendered-frame cadence')
            probe = stop_recording(recorder, log, path)
            recorder = None
            records.append(dict(form=form, kind='owned-attacks', rounds=3, performances=6,
                powers=['lightning', 'storm_dive'], video=path.name, cadence=cadence, probe=probe,
                sufficient_review_cadence=min(entry['fps'] for entry in cadence) >= 24))
    except Exception as error:
        failure = str(error)
        session.failure()
        raise
    finally:
        if recorder is not None:
            stop_recording(recorder, log, path)
        report = session.finish(failure)
        report.update(records=records, capture='Actual Web game canvas via X11 at 30 fps; engine cadence measured separately',
            limits=['Fixture recipients have endurance to permit six real owned casts.', 'This is visual evidence, not balance or hardware-wide performance acceptance.'])
        (args.output / 'electric-progression-report.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print(args.output / 'electric-progression-report.json')


if __name__ == '__main__':
    main()
