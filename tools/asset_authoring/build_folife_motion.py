"""Author Folife's own anatomical tracks into ignored staging.

The intermediate hare uses the second approved v11 design. This authoring tool
does not publish assets, change pins, or create mechanics/evolution rules.
"""
import hashlib
import json
import math
from pathlib import Path

from build_foli_motion import CHANNELS, envelope, neutral

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'builds/asset-work/folife/runtime'


def state(index, time):
    pose = neutral()
    breath = math.sin(time * math.tau / 3.6)
    pose[5] = -0.30 * breath
    pose[8] = 0.006 * breath
    pose[9] = 0.020 * breath
    pose[12] = 0.010 * math.sin(time * math.tau / 3.6 + 0.5)
    pose[13] = 0.012 * breath
    beat = envelope(time, 0.1, 0.65, 1.6)
    if index == 1:
        pose[8] -= 0.025 * beat
        pose[10] = -0.080 * beat
        pose[12] -= 0.022 * beat
    elif index == 2:
        pose[8] += 0.022 * beat
        pose[13] -= 0.040 * beat
    elif index == 3:
        pose[0] = -3.0 * beat
        pose[2] = -0.018 * beat
        pose[8] = -0.045 * beat
        pose[10] = 0.050 * beat
    elif index == 4:
        pose[8] = -0.020 * beat
        pose[10] = -0.100 * beat
        pose[12] -= 0.025 * beat
    elif index == 5:
        pose[8] += 0.024 * beat
        pose[10] = -0.060 * beat
        pose[13] += 0.040 * beat
    return pose


def cast(index, spec, time):
    pose = neutral()
    release = spec['release']
    gather = envelope(time, spec['start'], release - 0.07, release + 0.22)
    launch = envelope(time, release - 0.08, release + 0.12, spec['end'])
    # The short held blade and collar move around Folife's own forepaw/neck.
    pose[8] = -0.030 * gather + 0.028 * launch
    pose[10] = -0.100 * gather + 0.080 * launch
    pose[13] = -0.035 * gather + 0.035 * launch
    pose[12] = 0.025 * gather - 0.035 * launch
    pose[9] = -0.022 * gather
    pose[5] = 0.40 * gather - 0.25 * launch
    if index >= 12:
        reach = envelope(time, release - 0.16, spec['contact'], spec['end'])
        pose[19] = reach
        pose[0] = 300.0 * reach
    return pose


def reaction(index, time):
    pose = neutral()
    recoil = envelope(time, 0, 0.12 + 0.01 * (index % 3), 0.85)
    pose[0] = -4.0 * recoil
    pose[2] = -0.018 * recoil
    pose[8] = -0.045 * recoil
    pose[10] = 0.065 * recoil
    pose[13] = -0.045 * recoil
    pose[12] = 0.055 * recoil
    return pose


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    performances = json.loads((ROOT / 'assets/attacks/woodland-elements/versions/1.1.0/performances.json').read_text())
    form = {
        'anatomy': {
            'family': 'moss', 'name': 'Folife',
            'eye': [0.825, 0.482], 'mouth': [0.891, 0.530],
            'head': [0.795, 0.510], 'fore': [0.750, 0.720],
            'root': [0.640, 0.905], 'crest': [0.650, 0.535],
            'tail': [0.120, 0.680], 'hind': [0.375, 0.870],
            'ears': [0.525, 0.240], 'reservoir': [0.815, 0.745],
            'antenna': [0.550, 0.235], 'antennaB': [0.720, 0.185],
            'shell': [0.425, 0.740],
        },
        'profile': {'name': 'Folife', 'mass': 1.1, 'breath': 0.006, 'tempo': 0.96},
        'ground': [500 / 1254, 1174 / 1254],
        'joints': {
            'head': [0.700, 0.585, 0.795, 0.510, 0.14, 0.10],
            'fore': [0.680, 0.680, 0.780, 0.755, 0.11, 0.15],
            'tail': [0.220, 0.735, 0.120, 0.680, 0.085, 0.10],
            'crest': [0.650, 0.585, 0.625, 0.530, 0.18, 0.13],
            'ear': [0.720, 0.410, 0.525, 0.240, 0.24, 0.22],
        },
        'states': {str(i): [state(i, f / 30) for f in range(97)] for i in range(6)},
        'attacks': {str(i): [cast(i, spec, f / 30) for f in range(97)]
                    for i, spec in enumerate(performances['specs'])},
        'reactions': {str(i): [reaction(i, f / 30) for f in range(61)] for i in range(15)},
    }
    for group in ['states', 'attacks', 'reactions']:
        form[group] = {k: [[round(v, 7) for v in pose] for pose in frames]
                       for k, frames in form[group].items()}
    data = {'schema': 1, 'fps': 30, 'channels': CHANNELS, 'forms': {'verdalio': form}}
    path = OUTPUT / 'motion.json'
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'motion_sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'form': 'verdalio'}))


if __name__ == '__main__':
    main()
