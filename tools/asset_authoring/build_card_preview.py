"""Author an unpublished preview from generated frames and native vector UI components."""
import argparse
import copy
import json
from pathlib import Path
import shutil
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from asset_pipeline import ROOT, build, digest, file_record, load_releases, read_json, write_json
from card_asset_pipeline import snapshot, validate_presentation


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--moss-frame', type=Path, required=True)
    parser.add_argument('--dew-frame', type=Path, required=True)
    parser.add_argument('--portraits', type=Path, required=True)
    args = parser.parse_args()
    version = '0.1.0'
    dependencies = []
    plan = []
    modules = []

    def module(asset_id, provenance):
        folder = ROOT / 'assets' / asset_id / 'versions' / version
        if folder.exists(): raise ValueError('Preview release already exists; bump before authoring: ' + asset_id)
        folder.mkdir(parents=True)
        data = {'schema_version': 1, 'id': asset_id, 'version': version, 'status': 'prototype', 'description': 'Unreviewed modular card preview; not production artwork', 'provenance': provenance, 'files': {}, 'dependencies': []}
        modules.append((folder, data))
        dependencies.append({'id': asset_id, 'version': version})
        return folder, data

    for family, source in [('moss', args.moss_frame), ('dew', args.dew_frame)]:
        folder, data = module('ui/card-frame-' + family, {'kind': 'Image Gen prototype based on directly attached approved card concept', 'source_file': source.name, 'source_sha256': digest(source), 'reference': 'Pedro direct attachment, 1280x720, visually inspected in chat', 'license': 'Generated for this project; retains original PNG metadata'})
        shutil.copy2(source, folder / 'frame.png')
        data['files']['frame'] = file_record(folder / 'frame.png', 'frame.png', 'texture')

    palettes = {'forest': ['#b9e575', '#ecffd3', '#527c28', '#11220c'], 'water': ['#b7e9ff', '#edfbff', '#357cae', '#092139'], 'fire': ['#ffd0a2', '#fff1d7', '#b36431', '#3a1409'], 'lightning': ['#ffeaa2', '#fff9dc', '#ac8a37', '#302109']}
    for nature, (background, light, dark, foreground) in palettes.items():
        folder, data = module('ui/card-nature-' + nature, {'kind': 'Original vector UI authored for the approved composition', 'source': 'Native SVG gradients/shapes, no text or creature art', 'reference': 'Directly attached approved water/forest plates; fire/lightning extend existing game palette and remain prototype', 'license': 'Original project UI component'})
        review = folder / 'review'
        review.mkdir()
        (review / '.gdignore').write_text('')
        definitions = f'<defs><linearGradient id="plate" x2="0" y2="1"><stop stop-color="{light}"/><stop offset=".35" stop-color="{background}"/><stop offset="1" stop-color="{dark}"/></linearGradient><linearGradient id="gold" x2="0" y2="1"><stop stop-color="#fff2bf"/><stop offset=".4" stop-color="#efc46d"/><stop offset="1" stop-color="#a26019"/></linearGradient></defs>'
        drawings = {
            'title-plate': (512, 128, '<path d="M34 8 Q80 1 130 10 L382 10 Q430 1 478 8 Q508 32 496 94 Q491 118 464 116 L288 116 L256 126 L224 116 L48 116 Q20 118 16 94 Q4 32 34 8Z" fill="url(#plate)" stroke="url(#gold)" stroke-width="9"/><path d="M42 18 L470 18" stroke="#fff5cb" stroke-width="2" opacity=".8"/>'),
            'owner-plate': (512, 104, '<path d="M58 7 L454 7 Q504 7 504 52 Q504 97 454 97 L58 97 Q8 97 8 52 Q8 7 58 7Z" fill="url(#plate)" stroke="url(#gold)" stroke-width="9"/><path d="M61 18 L451 18" stroke="#fff5cb" stroke-width="2" opacity=".8"/>'),
            'art-border': (512, 512, f'<rect x="8" y="8" width="496" height="496" rx="35" fill="none" stroke="url(#gold)" stroke-width="14"/><rect x="19" y="19" width="474" height="474" rx="26" fill="none" stroke="{background}" stroke-width="8"/><path d="M30 62 Q40 30 70 27 M442 27 Q476 30 482 62 M30 450 Q40 480 70 485 M442 485 Q476 480 482 450" fill="none" stroke="{light}" stroke-width="5"/>'),
        }
        for role, (width, height, drawing) in drawings.items():
            svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{definitions}{drawing}</svg>'
            source = review / (role + '.svg')
            source.write_text(svg)
            data['files']['source-' + role] = file_record(source, 'review/' + source.name, 'review')
            plan.append({'source': str(source), 'destination': str(folder / (role + '.png'))})
        data['_tokens'] = {'background': background, 'foreground': foreground}
    plan_path = ROOT / 'test-results/card-vector-plan.json'
    write_json(plan_path, plan)
    result = subprocess.run(['godot', '--headless', '--path', str(ROOT), '--script', 'tools/asset_authoring/render_card_vectors.gd', '--', str(plan_path)], cwd=ROOT, capture_output=True, text=True, timeout=45)
    if result.returncode or 'ERROR:' in result.stdout + result.stderr: raise RuntimeError(result.stdout + result.stderr)
    tokens = {}
    for folder, data in modules:
        if '_tokens' in data:
            tokens[data['id'].removeprefix('ui/card-nature-')] = data.pop('_tokens')
            for role in ['art-border', 'title-plate', 'owner-plate']:
                data['files'][role] = file_record(folder / (role + '.png'), role + '.png', 'texture')
        write_json(folder / 'manifest.json', data)

    data = copy.deepcopy(read_json(ROOT / 'assets/ui/power-card-system/versions/0.1.0/presentation.json'))
    entry = lambda asset_id, role: {'asset': {'id': asset_id, 'version': version, 'role': role}, 'status': 'prototype', 'review': 'Unreviewed visual preview, based on direct approved reference; not production approval'}
    for family in ['moss', 'dew']: data['families'][family]['default_frame'] = entry('ui/card-frame-' + family, 'frame')
    for nature in tokens:
        data['power_styles'][nature] = {role: entry('ui/card-nature-' + nature, role.replace('_', '-')) for role in ['art_border', 'title_plate', 'owner_plate']}
        data['power_styles'][nature]['tokens'] = tokens[nature]
    portraits = read_json(args.portraits)
    data.update(portraits)
    for section in portraits.values():
        for portrait in section.values():
            ref = portrait['asset']
            dep = {'id': ref['id'], 'version': ref['version']}
            if dep not in dependencies: dependencies.append(dep)
    data['layout'].update({'aspect': 2 / 3, 'art_region': [.12, .255, .76, .54], 'anchors': {'title': [.5, .17], 'owner': [.5, .88], 'cost': [.13, .06], 'target': [.86, .07]}, 'review': 'Measured prototype layout; reference pixels inspected directly in chat. In-engine visual review pending.'})
    data['visual_references'][-1]['purpose'] += '; matching final concept supplied directly in chat and pixels inspected; original Library transfer remains blocked'
    data['coverage']['pending'] = [key for key in data['coverage']['pending'] if not key.startswith('tokens:')]
    folder = ROOT / 'assets/ui/power-card-system/versions/0.2.0'
    if folder.exists(): raise ValueError('Preview release already exists')
    folder.mkdir(parents=True)
    write_json(folder / 'presentation.json', data)
    write_json(folder / 'manifest.json', {'schema_version': 1, 'id': 'ui/power-card-system', 'version': '0.2.0', 'status': 'prototype', 'description': 'Explicit development preview; frame/plates and reused portraits, no completed attack illustration', 'provenance': {'kind': 'Approved concept directly attached by Pedro; original generated frames and original vector components', 'reference_pixels': 'Direct chat image 1280x720 inspected, no blocked transfer retry'}, 'files': {'presentation': file_record(folder / 'presentation.json', 'presentation.json', 'data')}, 'dependencies': sorted(dependencies, key=lambda d: (d['id'], d['version']))})
    build()
    report = validate_presentation(ROOT, ('ui/power-card-system', '0.2.0'), snapshot(), 'development')
    print(json.dumps({key: report[key] for key in ['required', 'covered', 'approved', 'failed']}))


if __name__ == '__main__': main()
