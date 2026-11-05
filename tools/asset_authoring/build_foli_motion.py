"""Author Foli's own mesh tracks; preserve the generated transparent PNG bytes.

This is an initial-form presentation pilot, not a walk or hand-drawn pose set.
Writes ignored staging only. Copy reviewed outputs into a new asset release.
"""
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'builds/asset-work/foli'
CHANNELS = ['x', 'y', 'rotation', 'sx', 'sy', 'bob', 'inflate', 'blink', 'head',
            'tail', 'fore', 'hind', 'crest', 'ear', 'jaw', 'wing', 'feeler', 'bough',
            'fin', 'reach']


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')


def neutral():
    return [0.0, 0.0, 0.0, 1.0, 1.0] + [0.0] * 15


def envelope(t, start, peak, end):
    if t <= start or t >= end:
        return 0.0
    if t <= peak:
        return math.sin((t - start) / (peak - start) * math.pi / 2)
    return math.cos((t - peak) / (end - peak) * math.pi / 2)


def state(index, t):
    pose = neutral()
    breath = math.sin(t * math.tau / 3.2)
    # No whole-body vertical translation or scaling: planted paws stay planted.
    pose[5] = -0.45 * breath
    pose[8] = 0.009 * breath
    pose[9] = 0.035 * breath
    pose[12] = 0.018 * math.sin(t * math.tau / 3.2 + 0.4)
    pose[13] = 0.022 * breath
    pose[17] = 0.055 * math.sin(t * math.tau / 3.2 + 0.8)
    # Blink overlay is deliberately omitted: the source eye remains intact.
    beat = envelope(t, 0.1, 0.65, 1.6)
    if index == 1:  # prepare: forepaws and orbiting leaves gather near the chest
        pose[8] -= 0.035 * beat
        pose[10] = -0.13 * beat
        pose[17] -= 0.17 * beat
    elif index == 2:  # short alert gesture, not locomotion
        pose[8] += 0.035 * beat
        pose[13] -= 0.06 * beat
    elif index == 3:  # hurt, with a bounded recoil around the ground pivot
        pose[0] = -4.0 * beat
        pose[2] = -0.025 * beat
        pose[8] = -0.07 * beat
        pose[10] = 0.09 * beat
    elif index == 4:  # protect: fold the forepaws inward
        pose[8] = -0.025 * beat
        pose[10] = -0.16 * beat
        pose[12] -= 0.04 * beat
        pose[17] -= 0.10 * beat
    elif index == 5:  # celebrate/heal: ears open, paws rise, feet remain on floor
        pose[8] += 0.035 * beat
        pose[10] = -0.10 * beat
        pose[13] += 0.08 * beat
        pose[17] += 0.12 * beat
    return pose


def cast(index, spec, t):
    pose = neutral()
    release = spec['release']
    gather = envelope(t, spec['start'], release - 0.07, release + 0.22)
    launch = envelope(t, release - 0.08, release + 0.12, spec['end'])
    pose[8] = -0.045 * gather + 0.04 * launch
    pose[10] = -0.18 * gather + 0.13 * launch
    pose[13] = -0.055 * gather + 0.06 * launch
    pose[12] = 0.03 * gather - 0.04 * launch
    pose[17] = -0.16 * gather + 0.22 * launch
    pose[9] = -0.035 * gather
    pose[5] = 0.7 * gather - 0.4 * launch
    if index >= 12:
        # Existing choreography owns the world-space travel. Compensate its
        # canonical 300-unit reach so the source's local floor stays consistent.
        reach = envelope(t, release - 0.16, spec['contact'], spec['end'])
        pose[19] = reach
        pose[0] = 300.0 * reach
    return pose


def reaction(index, t):
    pose = neutral()
    recoil = envelope(t, 0.0, 0.12 + 0.01 * (index % 3), 0.85)
    pose[0] = -5.0 * recoil
    pose[2] = -0.025 * recoil
    pose[8] = -0.065 * recoil
    pose[10] = 0.1 * recoil
    pose[13] = -0.07 * recoil
    pose[17] = 0.16 * recoil
    return pose


def main():
    # Published releases are immutable; authoring never writes into assets/.
    OUTPUT.mkdir(parents=True, exist_ok=True)
    performances = json.loads((ROOT / 'assets/attacks/woodland-elements/versions/1.1.0/performances.json').read_text())
    form = {
        'anatomy': {
            'family': 'moss', 'name': 'Foli', 'eye': [0.623, 0.423],
            'mouth': [0.730, 0.466], 'head': [0.626, 0.440],
            'fore': [0.614, 0.670], 'root': [0.635, 0.906],
            'crest': [0.560, 0.218], 'tail': [0.300, 0.745],
            'hind': [0.440, 0.880], 'ears': [0.546, 0.265],
            'reservoir': [0.761, 0.611], 'antenna': [0.560, 0.218],
            'antennaB': [0.343, 0.350], 'shell': [0.465, 0.731],
        },
        'profile': {'name': 'Foli', 'mass': 0.72, 'breath': 0.008, 'tempo': 1.0},
        'ground': [650 / 1254, 1182 / 1254],
        'joints': {
            'head': [0.544, 0.551, 0.626, 0.440, 0.16, 0.14],
            'fore': [0.535, 0.625, 0.614, 0.670, 0.09, 0.10],
            'tail': [0.350, 0.810, 0.300, 0.745, 0.08, 0.12],
            'crest': [0.580, 0.390, 0.345, 0.355, 0.22, 0.085],
            'ear': [0.611, 0.375, 0.560, 0.218, 0.075, 0.20],
            'bough': [0.765, 0.610, 0.784, 0.602, 0.080, 0.145],
        },
        'states': {str(i): [state(i, f / 30) for f in range(97)] for i in range(6)},
        'attacks': {str(i): [cast(i, spec, f / 30) for f in range(97)]
                    for i, spec in enumerate(performances['specs'])},
        'reactions': {str(i): [reaction(i, f / 30) for f in range(61)] for i in range(15)},
    }
    # Round serialized samples for reproducible files without noise-sized diffs.
    for group in ['states', 'attacks', 'reactions']:
        form[group] = {k: [[round(v, 7) for v in pose] for pose in frames]
                       for k, frames in form[group].items()}
    write(OUTPUT / 'motion.json', {'schema': 1, 'fps': 30, 'channels': CHANNELS, 'forms': {'moss': form}})
    write(OUTPUT / 'authoring.json', {
        'schema_version': 1, 'format': 'battle-motion-v1', 'form_id': 'moss',
        'motion_source': {'id': 'characters/foli-pilot', 'version': '1.0.0', 'role': 'motion'},
        'performances_source': {'id': 'attacks/woodland-elements', 'version': '1.1.0', 'role': 'performances'},
        'states': {'idle': {'group': 'states', 'clip': '0'},
                   'walk': {'missing': 'No authored locomotion poses or runtime walk in this initial-form mesh pilot.'},
                   'hurt': {'group': 'states', 'clip': '3'}}, 'attacks': [3, 4, 5],
    })
    print(json.dumps({'motion_sha256': hashlib.sha256((OUTPUT / 'motion.json').read_bytes()).hexdigest(),
                      'form': 'moss', 'walk_authored': False}))


if __name__ == '__main__':
    main()
