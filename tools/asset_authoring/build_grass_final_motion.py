"""Author final-hare motion profiles in ignored staging; never publish or pin.

Foslash/Folivel share visual timing helpers, not the previous plant anatomy.
Coordinates below refer to the inspected original portraits, with explicit views.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

from build_foli_motion import CHANNELS, envelope, neutral

ROOT = Path(__file__).resolve().parents[2]


def definition(form, view):
    if form == 'foslash' and view == 'front':
        return {
            'anatomy': {
                'family': 'moss', 'name': 'Foslash', 'eye': [.636, .314],
                'mouth': [.682, .359], 'head': [.630, .337],
                'fore': [.701, .502], 'fore_secondary': [.287, .583],
                'root': [.635, .905], 'crest': [.400, .300],
                'tail': [.183, .642], 'hind': [.318, .929],
                'ears': [.405, .190], 'reservoir': [.701, .502],
                'antenna': [.405, .190], 'antennaB': [.287, .583],
                'shell': [.500, .630],
            },
            'profile': {'name': 'Foslash', 'mass': 1.4, 'breath': .005, 'tempo': 1.0},
            'ground': [650 / 1254, 1184 / 1254],
            'joints': {
                'head': [.590, .405, .630, .337, .14, .11],
                'fore': [.530, .460, .701, .502, .12, .17],
                'tail': [.400, .700, .183, .642, .20, .21],
                'crest': [.580, .365, .400, .300, .23, .12],
                'ear': [.600, .345, .405, .190, .23, .14],
                'bough': [.380, .510, .287, .583, .13, .20],
            },
        }
    raise ValueError('No inspected anatomy for ' + form + ':' + view)


def state(index, time):
    p = neutral()
    breath = math.sin(time * math.tau / 3.6)
    p[5], p[8], p[9] = -.24 * breath, .005 * breath, .018 * breath
    p[12], p[13] = .010 * breath, .010 * math.sin(time * math.tau / 3.6 + .3)
    beat = envelope(time, .1, .65, 1.6)
    if index == 1:
        p[8], p[10], p[17] = -.018 * beat, -.065 * beat, .055 * beat
    elif index == 2:
        p[8], p[13] = .020 * beat, -.035 * beat
    elif index == 3:
        p[0], p[2], p[8], p[10] = -3.0 * beat, -.018 * beat, -.040 * beat, .045 * beat
    elif index == 4:
        p[10], p[17], p[12] = -.080 * beat, .065 * beat, -.025 * beat
    elif index == 5:
        p[8], p[10], p[13] = .020 * beat, -.055 * beat, .035 * beat
    return p


def cast(index, spec, time):
    p = neutral()
    release = spec['release']
    gather = envelope(time, spec['start'], release - .07, release + .22)
    launch = envelope(time, release - .08, release + .12, spec['end'])
    p[8] = -.025 * gather + .025 * launch
    p[10] = -.10 * gather + .12 * launch
    p[17] = .070 * gather - .090 * launch
    p[12] = .020 * gather - .030 * launch
    p[13] = -.030 * gather + .030 * launch
    p[9] = -.020 * gather
    p[5] = .35 * gather - .20 * launch
    if index >= 12:
        reach = envelope(time, release - .16, spec['contact'], spec['end'])
        p[19], p[0] = reach, 300 * reach
    return p


def reaction(index, time):
    p = neutral()
    beat = envelope(time, 0, .12 + .01 * (index % 3), .85)
    p[0], p[2], p[8] = -4.0 * beat, -.018 * beat, -.045 * beat
    p[10], p[17], p[13] = .055 * beat, -.040 * beat, -.040 * beat
    return p


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--form', choices=['foslash', 'folivel'], required=True)
    parser.add_argument('--view', choices=['front', 'back'], default='front')
    args = parser.parse_args()
    form = definition(args.form, args.view)
    form['attack_presentation'] = {'profile': 'leaf_blades', 'binding': 'attacks/grass-leaf-blades', 'blade_scale': 1.1}
    performances = json.loads((ROOT / 'assets/attacks/woodland-elements/versions/1.1.0/performances.json').read_text())
    form['states'] = {str(i): [state(i, f / 30) for f in range(97)] for i in range(6)}
    form['attacks'] = {str(i): [cast(i, spec, f / 30) for f in range(97)] for i, spec in enumerate(performances['specs'])}
    form['reactions'] = {str(i): [reaction(i, f / 30) for f in range(61)] for i in range(15)}
    for group in ['states', 'attacks', 'reactions']:
        form[group] = {key: [[round(v, 7) for v in p] for p in frames] for key, frames in form[group].items()}
    key = args.form if args.view == 'front' else args.form + ':' + args.view
    data = {'schema': 1, 'fps': 30, 'channels': CHANNELS, 'forms': {key: form}}
    out = ROOT / 'builds/asset-work' / args.form / 'runtime'
    out.mkdir(parents=True, exist_ok=True)
    path = out / ('motion-' + args.view + '.json')
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'form': key, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}))


if __name__ == '__main__':
    main()
