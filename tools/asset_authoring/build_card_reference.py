"""Publish a new candidate asset version from the reattached approved card reference.

Keeps generation masters byte-identical in review/. Only deterministic sheet
splitting/face crops and original native SVG UI contours are derived locally.
"""
import argparse
import copy
from pathlib import Path
import shutil
import subprocess
import sys

from PIL import Image, PngImagePlugin

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from asset_pipeline import ROOT, build, digest, file_record, read_json, write_json
from card_asset_pipeline import snapshot, validate_presentation
from harness_lib.executor import environment


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('moss-frame', 'dew-frame', 'forest-plates', 'water-plates', 'healing-art', 'forest-demo'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    modules = []
    vectors = []

    def module(asset_id, version, source=None):
        folder = ROOT / 'assets' / asset_id / 'versions' / version
        if folder.exists():
            raise ValueError('Refusing to overwrite a candidate version: ' + str(folder))
        folder.mkdir(parents=True)
        review = folder / 'review'
        review.mkdir()
        (review / '.gdignore').touch()
        data = {'schema_version': 1, 'id': asset_id, 'version': version, 'status': 'prototype',
                'description': 'Card reference correction candidate; human visual approval pending',
                'provenance': {'kind': 'Controlled Image Gen edit from Pedro reattached approved card concept',
                               'reference': 'Direct chat attachment re-sent by Pedro; pixels supplied to image generation',
                               'license': 'Generated for this project; originals preserved with metadata'},
                'files': {}, 'dependencies': []}
        if source:
            destination = review / source.name
            shutil.copy2(source, destination)
            data['files']['generation-master'] = file_record(destination, 'review/' + source.name, 'review')
            data['provenance'].update(source_sha256=digest(source), source_file=source.name)
        modules.append((folder, data))
        return folder, data

    def texture(folder, data, role, name):
        data['files'][role] = file_record(folder / name, name, 'texture')

    def crop(source, box, destination):
        with Image.open(source) as image:
            derived = image.crop(box)
            metadata = PngImagePlugin.PngInfo()
            metadata.add_text('UmbralNormalization', 'Deterministic crop only; original generation master preserved in review/')
            metadata.add_text('SourceSHA256', digest(source))
            metadata.add_text('SourceCrop', ','.join(map(str, box)))
            derived.save(destination, pnginfo=metadata)

    for family, source in [('moss', args.moss_frame), ('dew', args.dew_frame)]:
        folder, data = module('ui/card-frame-' + family, '0.2.0', source)
        shutil.copy2(source, folder / 'frame.png')
        texture(folder, data, 'frame', 'frame.png')

    palettes = {'forest': ('#c6ef65', '#1a5f0c', '#070e03'),
                'water': ('#b9eaff', '#008fc6', '#061527'),
                'fire': ('#ffd0a2', '#d85317', '#3a1409'),
                'lightning': ('#ffeaa2', '#d8a800', '#302109')}
    for nature, (background, outline, foreground) in palettes.items():
        sheet = {'forest': args.forest_plates, 'water': args.water_plates}.get(nature)
        folder, data = module('ui/card-nature-' + nature, '0.2.0', sheet)
        if sheet:
            with Image.open(sheet) as image:
                for role, start, end in [('title-plate', 0, image.height // 2), ('owner-plate', image.height // 2, image.height)]:
                    region = image.getchannel('A').crop((0, start, image.width, end))
                    bbox = region.point(lambda value: 255 if value >= 16 else 0).getbbox()
                    if not bbox:
                        raise ValueError('Missing sheet component: ' + role)
                    x0, y0, x1, y1 = bbox
                    box = (max(0, x0 - 2), max(start, start + y0 - 2), min(image.width, x1 + 2), min(end, start + y1 + 2))
                    crop(sheet, box, folder / (role + '.png'))
                    texture(folder, data, role, role + '.png')
        else:
            # No approved fire/lightning concept exists. Retain their explicit
            # prototype plates; only remove the old white photo contour.
            data['provenance']['kind'] = 'Original native UI contour; existing prototype plates retained'
            for role in ('title-plate', 'owner-plate'):
                shutil.copy2(ROOT / 'assets/ui' / ('card-nature-' + nature) / 'versions/0.1.0' / (role + '.png'), folder / (role + '.png'))
                texture(folder, data, role, role + '.png')
        contour = 'M64 3 L448 3 Q509 3 509 41 L509 471 Q509 509 448 509 L64 509 Q3 509 3 471 L3 41 Q3 3 64 3Z'
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><path d="{contour}" fill="none" stroke="#d0a049" stroke-width="5"/><path d="{contour}" fill="none" stroke="{outline}" stroke-width="2.5"/></svg>'
        source = folder / 'review/art-border.svg'
        source.write_text(svg)
        data['files']['source-art-border'] = file_record(source, 'review/art-border.svg', 'review')
        vectors.append({'source': str(source), 'destination': str(folder / 'art-border.png')})
        data['_tokens'] = {'background': background, 'foreground': foreground}

    folder, data = module('umbrals/card-art-dew', '0.2.0', args.healing_art)
    shutil.copy2(args.healing_art, folder / 'power-dew-mend.png')
    texture(folder, data, 'power-dew-mend', 'power-dew-mend.png')
    shutil.copy2(args.forest_demo, folder / 'power-thorn-lash-demo.png')
    texture(folder, data, 'power-thorn-lash-demo', 'power-thorn-lash-demo.png')
    shutil.copy2(args.forest_demo, folder / 'review' / args.forest_demo.name)
    data['files']['demo-master'] = file_record(folder / 'review' / args.forest_demo.name, 'review/' + args.forest_demo.name, 'review')
    data['provenance']['demo'] = 'Isolated nonplayable Lonlon/Forest example; never grants learning'

    for family, box in [('moss', (600, 440, 1150, 990)), ('dew', (50, 300, 600, 850))]:
        folder, data = module('umbrals/card-target-' + family, '0.1.0', args.healing_art)
        crop(args.healing_art, box, folder / 'portrait.png')
        texture(folder, data, 'portrait', 'portrait.png')
        data['provenance']['kind'] = 'Deterministic face crop from the new healing illustration, no repaint or resampling'
        data['provenance']['crop'] = list(box)

    plan = ROOT / 'test-results/card-reference-vectors.json'
    write_json(plan, vectors)
    result = subprocess.run(['godot', '--headless', '--path', str(ROOT), '--script', 'tools/asset_authoring/render_card_vectors.gd', '--', str(plan)], env=environment(ROOT), capture_output=True, text=True, timeout=60)
    if result.returncode or 'ERROR:' in result.stdout + result.stderr:
        raise RuntimeError(result.stdout + result.stderr)
    tokens = {}
    for folder, data in modules:
        if '_tokens' in data:
            tokens[data['id'].removeprefix('ui/card-nature-')] = data.pop('_tokens')
            texture(folder, data, 'art-border', 'art-border.png')
        write_json(folder / 'manifest.json', data)

    candidate = copy.deepcopy(read_json(ROOT / 'assets/ui/power-card-system/versions/0.2.0/presentation.json'))
    def entry(asset_id, role, version='0.2.0'):
        return {'asset': {'id': asset_id, 'version': version, 'role': role}, 'status': 'prototype',
                'review': 'Reattached approved reference used directly; candidate pixels inspected, in-game/human approval pending'}
    for family in ('moss', 'dew'):
        candidate['families'][family]['default_frame'] = entry('ui/card-frame-' + family, 'frame')
        candidate['target_portraits'][family] = {**entry('umbrals/card-target-' + family, 'portrait', '0.1.0'), 'crop': [0, 0, 1, 1], 'focal_point': [0.5, 0.5]}
    for nature in palettes:
        candidate['power_styles'][nature] = {key: entry('ui/card-nature-' + nature, key.replace('_', '-')) for key in ('art_border', 'title_plate', 'owner_plate')}
        candidate['power_styles'][nature]['tokens'] = tokens[nature]
    candidate['illustrations']['dew']['dew']['dew_mend'] = entry('umbrals/card-art-dew', 'power-dew-mend')
    candidate['illustrations']['dew']['dew']['thorn_lash'] = entry('umbrals/card-art-dew', 'power-thorn-lash-demo')
    candidate['coverage']['pending'] = sorted(set(candidate['coverage']['pending']) | {'demonstration:dew/dew/thorn_lash'})
    candidate['layout'].update(art_region=[.08, .235, .84, .64], safe_region=[.07, .14, .86, .82], anchors={'title': [.5, .19], 'owner': [.5, .895], 'cost': [.88, .15], 'target': [.88, .065]}, review='V05-CARD-04: reattached reference supplied directly; organic frames, serif native labels and broad illustration opening. Human review pending.')
    candidate['layout']['text']['title_max_lines'] = 1
    dependencies = set()
    def collect(value):
        if isinstance(value, dict):
            if isinstance(value.get('asset'), dict):
                dependencies.add((value['asset']['id'], value['asset']['version']))
            for child in value.values(): collect(child)
        elif isinstance(value, list):
            for child in value: collect(child)
    collect(candidate)
    folder, data = module('ui/power-card-system', '0.3.0')
    write_json(folder / 'presentation.json', candidate)
    data['files']['presentation'] = file_record(folder / 'presentation.json', 'presentation.json', 'data')
    data['dependencies'] = [{'id': key, 'version': version} for key, version in sorted(dependencies)]
    write_json(folder / 'manifest.json', data)
    build()
    report = validate_presentation(ROOT, ('ui/power-card-system', '0.3.0'), snapshot(), 'development')
    print({key: report[key] for key in ('required', 'covered', 'approved', 'failed')})


if __name__ == '__main__':
    main()
