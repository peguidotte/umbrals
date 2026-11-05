"""Author inspected Foli/Folife rear anatomy into ignored staging only.

Only the timing/channel helpers are shared with the final hares. All image-space
joints, sockets and grounding below refer to the inspected rear stills. Front
assets, authored images, lifecycle pixels and runtime pins are never modified.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any

from PIL import Image

from build_grass_final_motion import CHANNELS, cast, reaction, state

ROOT = Path(__file__).resolve().parents[2]
IMAGE_SIZE = 1254
FPS = 30
HELPERS = ROOT / 'tools/asset_authoring/build_grass_final_motion.py'
PERFORMANCES = ROOT / 'assets/attacks/woodland-elements/versions/1.1.0/performances.json'

# Pixel coordinates, manually located on the ORIGINAL rear PNGs. fore is the
# primary socket consumed by CreatureRig; fore_primary is an explicit alias.
SPECS: dict[str, dict[str, Any]] = {
    'moss': {
        'species': 'foli', 'name': 'Foli',
        'source_sha256': 'cf0caad407c3b463a91c1342446215f193050e49ab8cdea0e554c846c7c9d7c9',
        'ground': (631, 1217), 'visible_top': 29, 'shadow_width': 320,
        'profile': {'name': 'Foli', 'mass': .72, 'breath': .008, 'tempo': 1.0},
        'sockets': {
            'eye': (853, 531), 'mouth': (886, 594), 'head': (787, 570),
            'fore': (810, 852), 'fore_primary': (810, 852),
            'fore_secondary': (806, 887), 'root': (690, 1138),
            'tail': (466, 1027), 'crest': (454, 425), 'ear': (729, 281),
            'ears': (729, 281), 'bough': (951, 741), 'hind': (730, 1170),
            'reservoir': (951, 741), 'antenna': (729, 281),
            'antennaB': (454, 425), 'shell': (602, 941),
        },
        # Joint: pivotX, pivotY, influence-centerX/Y, Gaussian radiusX/Y.
        'joints': {
            'head': (715, 660, 787, 570, 155, 150),
            'fore': (764, 739, 806, 849, 70, 113),
            'tail': (480, 1120, 466, 1027, 91, 127),
            'crest': (710, 493, 454, 425, 236, 115),
            'ear': (759, 510, 729, 281, 100, 245),
            'bough': (911, 751, 951, 741, 83, 170),
        },
        'roles': {
            'fore': 'Near tucked brown forepaw; secondary is the partly occluded far paw edge.',
            'crest': 'Swept-left leaf ear, independently from the upright leaf ear.',
            'ear': 'Upright leaf ear about its own ear base.',
            'bough': 'The three detached blade leaves, not a copied plant branch.',
        },
        'anchor_reason': 'X631 is the rear support/body origin and is close to the native lifecycle center313/627; Y1217 is the inspected substantial floor.',
    },
    'verdalio': {
        'species': 'folife', 'name': 'Folife',
        'source_sha256': 'ee03b7256f06113a28538d39eb34c23a738b1f89a1f1ebf06e991b8cca149d4d',
        'ground': (620, 1246), 'visible_top': 5, 'shadow_width': 760,
        'profile': {'name': 'Folife', 'mass': 1.1, 'breath': .006, 'tempo': .96},
        'sockets': {
            'eye': (1077, 553), 'mouth': (1120, 606), 'head': (1028, 571),
            'fore': (1030, 836), 'fore_primary': (1030, 836),
            'fore_secondary': (878, 1110), 'root': (610, 1125),
            'tail': (160, 748), 'crest': (755, 649), 'ear': (640, 260),
            'ears': (640, 260), 'bough': (977, 976), 'hind': (440, 1210),
            'reservoir': (755, 649), 'antenna': (900, 253),
            'antennaB': (540, 236), 'shell': (484, 868),
        },
        'joints': {
            'head': (929, 665, 1028, 571, 145, 122),
            'fore': (885, 800, 1030, 836, 105, 105),
            'tail': (232, 817, 160, 748, 90, 125),
            'crest': (850, 673, 755, 649, 250, 170),
            'ear': (987, 519, 660, 275, 390, 270),
            'bough': (1030, 836, 977, 976, 75, 115),
        },
        'roles': {
            'fore': 'Primary is the cream gripping paw; secondary is the free supporting forepaw.',
            'crest': 'Rear layered leaf collar, not the old evolved plant canopy.',
            'ear': 'Both long hare ears around their adjacent head bases.',
            'bough': 'Short held leaf blade about its grip; supporting toes are outside the influence core.',
        },
        'anchor_reason': 'X620 is a virtual body/shadow anchor near static-bbox midpoint616 and lifecycle center313/627. Physical lowest-foot center402 is recorded separately; using it as the origin would shift the idle-to-atlas handoff horizontally. Y1246 remains the inspected substantial floor.',
    },
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')


def definition(form_id: str) -> dict[str, Any]:
    """Return only this form's normalized rear coordinates, never front data."""
    spec = SPECS[form_id]
    anatomy: dict[str, Any] = {'family': 'moss', 'name': spec['name']}
    anatomy.update({key: [x / IMAGE_SIZE, y / IMAGE_SIZE]
                    for key, (x, y) in spec['sockets'].items()})
    return {
        'anatomy': anatomy, 'profile': dict(spec['profile']),
        'ground': [value / IMAGE_SIZE for value in spec['ground']],
        'joints': {key: [value / IMAGE_SIZE for value in values]
                   for key, values in spec['joints'].items()},
    }


def source_measurements(form_id: str) -> dict[str, Any]:
    spec = SPECS[form_id]
    base = ROOT / 'builds/asset-work' / (spec['species'] + '-views')
    source = base / 'static-01/original.png'
    if digest(source) != spec['source_sha256']:
        raise ValueError('Rear reference changed; inspect pixels before reauthoring ' + form_id)
    with Image.open(source) as image:
        if image.size != (IMAGE_SIZE, IMAGE_SIZE) or image.mode != 'RGBA':
            raise ValueError('Unexpected inspected rear source: ' + str(source))
        alpha = image.getchannel('A')
        substantial = alpha.point(lambda value: 255 if value >= 128 else 0)
        bounds = substantial.getbbox()
        if bounds is None or bounds[1] != spec['visible_top'] or bounds[3] != spec['ground'][1]:
            raise ValueError('Rear source floor/top changed for ' + form_id)
        band = substantial.crop((0, bounds[3] - 4, IMAGE_SIZE, bounds[3])).getbbox()
        assert band is not None
        samples = {key: {'pixel': list(point), 'rgba': list(image.getpixel(point))}
                   for key, point in spec['sockets'].items()}
        for key in ['eye', 'mouth', 'head', 'fore', 'fore_secondary', 'tail', 'crest', 'ear', 'bough']:
            if samples[key]['rgba'][3] < 128:
                raise ValueError('Visible socket outside substantial source: ' + form_id + ':' + key)
    lifecycle: dict[str, Any] = {}
    for name in ['walk', 'ko']:
        path = base / (name + '-01') / 'normalization-native.json'
        data = json.loads(path.read_text())
        frame = data['frames'][0]['candidate_bounds_alpha_ge_128']
        lifecycle[name] = {
            'normalization_file': str(path.relative_to(ROOT)), 'sha256': digest(path),
            'frame_size': data['source_cell_size'], 'pivot': data['candidate_pivot'],
            'floor_y': data['candidate_floor_y'], 'first_visible_height': frame[3] - frame[1],
        }
    return {
        'source': str(source.relative_to(ROOT)), 'source_sha256': digest(source),
        'source_dimensions': [IMAGE_SIZE, IMAGE_SIZE], 'bounds_alpha_ge_128': list(bounds),
        'physical_lowest_contact_bottom4_x': [band[0], band[2]],
        'physical_lowest_contact_center_x': (band[0] + band[2]) / 2,
        'virtual_ground_anchor': list(spec['ground']), 'anchor_reason': spec['anchor_reason'],
        'shadow_width': spec['shadow_width'],
        'shadow_width_basis': 'Manual visible-footprint estimate for this view; matrix review pending.',
        'sockets_pixels_and_rgba': samples,
        'sockets_normalized_uv': definition(form_id)['anatomy'],
        'joint_pixels': {key: list(values) for key, values in spec['joints'].items()},
        'joint_roles': spec['roles'], 'lifecycle_native627': lifecycle,
        'limits': ['No engine/render/matrix validation in this authoring step.',
                   'Occluded paw edges and dorsal overlaps limit socket precision.',
                   'Virtual anchor reduces, but does not prove absence of, idle/walk/KO jumps.',
                   'Legacy reservoir/antenna/shell names are anatomical socket aliases, not new organs or mechanics.'],
    }


def bake_tracks(form: dict[str, Any], performances: dict[str, Any]) -> None:
    form['states'] = {str(index): [state(index, frame / FPS) for frame in range(97)]
                      for index in range(6)}
    form['attacks'] = {str(index): [cast(index, spec, frame / FPS) for frame in range(97)]
                       for index, spec in enumerate(performances['specs'])}
    form['reactions'] = {str(index): [reaction(index, frame / FPS) for frame in range(61)]
                         for index in range(15)}
    for group in ['states', 'attacks', 'reactions']:
        for key, frames in form[group].items():
            for pose in frames:
                if len(pose) != len(CHANNELS) or not all(math.isfinite(value) for value in pose):
                    raise ValueError('Invalid helper track: ' + group + ':' + key)
            form[group][key] = [[round(value, 7) for value in pose] for pose in frames]


def build(form_id: str, performances: dict[str, Any], helper_hash: str) -> dict[str, Any]:
    spec = SPECS[form_id]
    measurements = source_measurements(form_id)
    form = definition(form_id)
    bake_tracks(form, performances)
    parameters = {
        'grounding': {'foot': list(spec['ground']), 'visible_top': spec['visible_top'],
                      'width': spec['shadow_width'], 'height': 118},
        'standing_height': measurements['lifecycle_native627']['walk']['first_visible_height'],
        'source_height_ratio': (spec['ground'][1] - spec['visible_top']) / IMAGE_SIZE,
    }
    if digest(HELPERS) != helper_hash:
        raise ValueError('Shared timing helper changed during generation; rerun after it is stable.')
    output = ROOT / 'builds/asset-work' / (spec['species'] + '-views') / 'runtime'
    output.mkdir(parents=True, exist_ok=True)
    data = {'schema': 1, 'fps': FPS, 'channels': CHANNELS, 'forms': {form_id + ':back': form}}
    write_json(output / 'motion-back.json', data)
    write_json(output / 'runtime-parameters.json', parameters)
    measurements.update({
        'form_key': form_id + ':back', 'runtime_parameters': parameters,
        'timing_helper': {'path': str(HELPERS.relative_to(ROOT)), 'sha256': helper_hash,
                          'functions': ['state', 'cast', 'reaction'], 'channels': CHANNELS},
        'performances': {'path': str(PERFORMANCES.relative_to(ROOT)), 'sha256': digest(PERFORMANCES)},
        'front_data_preserved': True, 'attack_presentation': 'Not authored here; existing runtime routing remains responsible.',
    })
    write_json(output / 'anatomy-measurements.json', measurements)
    return {'form': form_id + ':back', 'output': str(output.relative_to(ROOT)),
            'motion_sha256': digest(output / 'motion-back.json'), 'parameters': parameters}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--form', choices=['all', 'foli', 'folife'], default='all')
    args = parser.parse_args()
    helper_hash = digest(HELPERS)
    performances = json.loads(PERFORMANCES.read_text())
    if len(CHANNELS) != 20 or len(performances['specs']) != 15:
        raise ValueError('Existing motion/performance contract changed.')
    selected = [form_id for form_id, spec in SPECS.items()
                if args.form == 'all' or spec['species'] == args.form]
    print(json.dumps([build(form_id, performances, helper_hash) for form_id in selected], indent=2))


if __name__ == '__main__':
    main()
