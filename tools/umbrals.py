#!/usr/bin/env python3
"""Create and validate reviewable species packages without changing pinned assets."""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ID = re.compile(r"^[a-z][a-z0-9_]*$")


def read_package(path):
    text = path.read_text(encoding="utf-8")
    def scalar(key):
        match = re.search(rf'^{key} = ("[^"\n]*")$', text, re.M)
        if not match:
            raise ValueError(f"missing {key}")
        return json.loads(match.group(1))
    def array(key):
        match = re.search(rf'^{key} = Array\[Dictionary\]\(\[(.*?)\]\)', text, re.M | re.S)
        if not match:
            raise ValueError(f"missing {key}")
        return json.loads('[' + re.sub(r',\s*$', '', match.group(1).strip()) + ']')
    return scalar('id'), scalar('initial_form'), array('forms'), array('evolutions')


def validate(path, bindings):
    errors = []
    try:
        sid, initial, forms, edges = read_package(path)
        source = path.read_text(encoding='utf-8')
        content = (ROOT / 'scripts/content.gd').read_text(encoding='utf-8')
        def registry(name):
            match = re.search(rf'^const {name} = \{{\n(.*?)^\}}', content, re.M | re.S)
            if not match:
                raise ValueError(f'missing authoritative {name} registry')
            return dict(re.findall(r'^\s*"([a-z][a-z0-9_]*)": \{([^\n]*)', match.group(1), re.M))
        power_registry, passive_registry, nature_registry = registry('POWERS'), registry('PASSIVES'), registry('NATURES')
        def field(name):
            match = re.search(rf'^{name} = (.+)$', source, re.M)
            if not match:
                raise ValueError(f'missing species field {name}')
            return json.loads(match.group(1))
        element, color, signature = field('element'), field('color'), field('signature')
        powers, passive_pool = field('powers'), field('passive_pool')
        if not isinstance(element, str) or not element.strip(): errors.append('invalid element')
        if not isinstance(color, str) or not re.fullmatch(r'[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?', color): errors.append('invalid color')
        if not isinstance(powers, list) or not powers or any(not isinstance(value, str) or value not in power_registry for value in powers): errors.append('unknown or invalid initial power')
        if not isinstance(passive_pool, list) or not passive_pool or any(not isinstance(value, str) or value not in passive_registry for value in passive_pool): errors.append('unknown or invalid passive')
        if not isinstance(signature, str) or signature not in power_registry or not re.search(r'"learning"\s*:\s*"lineage"', power_registry.get(signature, '')): errors.append('signature must identify a lineage power')
        if not ID.fullmatch(sid) or sid != path.parent.name:
            errors.append('species ID must match its folder and use stable lowercase IDs')
        ids = [f.get('id', '') for f in forms]
        if not ids or len(ids) != len(set(ids)) or any(not ID.fullmatch(i) for i in ids):
            errors.append('form IDs must be unique stable lowercase IDs')
        if initial not in ids:
            errors.append('initial form is missing')
        encounter_block = re.search(r'^const ENCOUNTERS = \[\n(.*?)^\]', content, re.M | re.S)
        if not encounter_block:
            raise ValueError('missing authoritative ENCOUNTERS catalog')
        encounter_ids = {art.rsplit('/', 1)[-1] for art in re.findall(r'"uid"\s*:\s*\d+[^\n]*?"art"\s*:\s*"([^"]+)"', encounter_block.group(1))}
        for form_id in ids:
            if form_id in encounter_ids:
                errors.append(f'form ID {form_id} is reserved for encounter discovery')
        registry = (ROOT / 'scripts/battle/traits.gd').read_text(encoding='utf-8')
        handler_line = next(line for line in registry.splitlines() if re.match(r'(?:const|static var) HANDLERS(?:\s*:\s*Dictionary)?\s*=', line))
        trait_ids = set(re.findall(r'"([a-z_]+)"\s*:', handler_line))
        for form in forms:
            required = {'id', 'name', 'nature', 'secondary_nature', 'resistances', 'art', 'trait_id', 'trait', 'trait_description', 'trait_value', 'stats', 'power_profile', 'lore'}
            if not required <= form.keys():
                errors.append(f"form {form.get('id')} lacks required fields")
                continue
            if not ID.fullmatch(str(form['trait_id'])) or form['nature'] not in nature_registry or (form['secondary_nature'] != '' and form['secondary_nature'] not in nature_registry):
                errors.append(f"form {form['id']} has invalid trait or nature ID")
            if form['trait_id'] not in trait_ids:
                errors.append(f"form {form['id']} references unregistered trait {form['trait_id']}")
            binding = bindings.get(form['art'])
            if not binding:
                errors.append(f"form {form['id']} references unpinned art {form['art']}")
            else:
                manifest_path = ROOT / 'assets' / binding['id'] / 'versions' / binding['version'] / 'manifest.json'
                if not manifest_path.is_file():
                    errors.append(f"form {form['id']} has missing pinned release")
                else:
                    asset = json.loads(manifest_path.read_text(encoding='utf-8'))
                    role = asset.get('files', {}).get(binding['file'], {})
                    if not role or not (manifest_path.parent / role.get('path', '')).is_file():
                        errors.append(f"form {form['id']} has missing pinned asset role")
            if any(not isinstance(form[key], str) or not form[key].strip() for key in ('name', 'trait', 'trait_description')):
                errors.append(f"form {form['id']} has empty text")
            if not isinstance(form['lore'], dict) or set(form['lore']) != {'title', 'text'} or any(not isinstance(value, str) or not value.strip() for value in form['lore'].values()):
                errors.append(f"form {form['id']} has invalid lore")
            if type(form['trait_value']) is not int or form['trait_value'] < 0:
                errors.append(f"form {form['id']} has invalid trait value")
            stats, profile, resistance = form['stats'], form['power_profile'], form['resistances']
            if not isinstance(stats, dict) or set(stats) != {'max_hp', 'attack', 'defense', 'speed'} or any(type(value) is not int or value < (1 if key == 'max_hp' else 0) for key, value in stats.items()):
                errors.append(f"form {form['id']} has invalid stats")
            if not isinstance(profile, dict) or set(profile) != {'damage', 'block', 'heal', 'burn', 'wet'} or any(type(value) is not int or value < 0 for value in profile.values()):
                errors.append(f"form {form['id']} has invalid power profile")
            if not isinstance(resistance, dict) or any(key not in nature_registry or type(value) is not int or not 0 <= value <= 100 for key, value in resistance.items()):
                errors.append(f"form {form['id']} has invalid resistances")
        edge_ids = [e.get('id', '') for e in edges]
        if len(edge_ids) != len(set(edge_ids)) or any(not ID.fullmatch(i) for i in edge_ids):
            errors.append('edge IDs must be unique stable lowercase IDs')
        for edge in edges:
            if edge.get('from') not in ids or edge.get('to') not in ids or edge.get('from') == edge.get('to'):
                errors.append(f"invalid edge {edge.get('id')}")
        adjacency = {form_id: [] for form_id in ids}
        for edge in edges:
            if edge.get('from') in adjacency and edge.get('to') in adjacency:
                adjacency[edge['from']].append(edge['to'])
        visited, active = set(), set()
        def visit(form_id):
            if form_id in active:
                return True
            if form_id in visited:
                return False
            active.add(form_id)
            cyclic = any(visit(target) for target in adjacency[form_id])
            active.remove(form_id)
            visited.add(form_id)
            return cyclic
        cyclic = any(visit(form_id) for form_id in ids if form_id not in visited)
        if cyclic:
            errors.append('evolution graph contains a cycle')
        reachable = set()
        pending = [initial] if initial in adjacency else []
        while pending:
            form_id = pending.pop()
            if form_id not in reachable:
                reachable.add(form_id)
                pending.extend(adjacency[form_id])
        if set(ids) != reachable:
            errors.append('evolution graph contains unreachable forms')
    except (ValueError, TypeError, KeyError, json.JSONDecodeError) as exc:
        errors.append(str(exc))
    return errors


def duplicate_form_ids(paths):
    owners = {}
    duplicates = []
    for path in paths:
        try:
            species, _, forms, _ = read_package(path)
            for form in forms:
                form_id = form.get('id', '')
                if form_id in owners and owners[form_id] != species:
                    duplicates.append(f'form ID {form_id} appears in {owners[form_id]} and {species}')
                owners[form_id] = species
        except (ValueError, TypeError, KeyError):
            continue  # Package validation reports malformed input separately.
    return duplicates


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)
    make = sub.add_parser('author', help='create a package using an explicit pinned fallback form')
    make.add_argument('id')
    make.add_argument('--fallback', required=True, choices=['ember', 'moss', 'volt', 'dew'])
    sub.add_parser('validate')
    args = parser.parse_args()
    if args.command == 'author':
        if not ID.fullmatch(args.id):
            parser.error('ID must use lowercase letters, digits and underscores')
        destination = ROOT / 'content/species' / args.id / 'species.tres'
        if destination.exists():
            parser.error('package already exists')
        source = (ROOT / 'content/species' / args.fallback / 'species.tres').read_text(encoding='utf-8')
        _, _, forms, _ = read_package(ROOT / 'content/species' / args.fallback / 'species.tres')
        form = forms[0]
        form['id'] = args.id
        form['name'] = args.id
        prefix = source[:source.index('id = ')]
        species_fields = source[source.index('element = '):source.index('forms = ')]
        destination.parent.mkdir(parents=True, exist_ok=False)
        destination.write_text(prefix + f'id = "{args.id}"\ninitial_form = "{args.id}"\n' + species_fields + 'forms = Array[Dictionary]([\n' + json.dumps(form, ensure_ascii=False) + '\n])\nevolutions = Array[Dictionary]([])\n', encoding='utf-8')
        manifest_path = ROOT / 'content/species/catalog.tres'
        manifest = manifest_path.read_text(encoding='utf-8')
        ids = [int(value) for value in re.findall(r'\bid="(\d+)"', manifest)]
        next_id = max(ids) + 1
        manifest = re.sub(r'load_steps=(\d+)', lambda m: f'load_steps={int(m.group(1)) + 1}', manifest, count=1)
        entry = f'[ext_resource type="Resource" path="res://content/species/{args.id}/species.tres" id="{next_id}"]\n'
        manifest = manifest.replace('\n[resource]\n', entry + '\n[resource]\n', 1)
        manifest = manifest.replace('])\n', f', ExtResource("{next_id}")])\n', 1)
        manifest_path.write_text(manifest, encoding='utf-8')
        print(f'{destination.relative_to(ROOT)} created and added to manifest; review lore, all values and fallback art')
        return 0
    bindings = json.loads((ROOT / 'assets/runtime-lock.json').read_text())['bindings']
    paths = sorted((ROOT / 'content/species').glob('*/species.tres'))
    failures = 0
    content = (ROOT / 'content/species/catalog.tres').read_text(encoding='utf-8')
    manifest_paths = re.findall(r'path="res://content/species/([^/]+)/species\.tres"', content)
    folder_ids = [path.parent.name for path in paths]
    if len(manifest_paths) != len(set(manifest_paths)) or sorted(manifest_paths) != folder_ids:
        print('manifest and species folders differ or contain duplicates', file=sys.stderr)
        failures += 1
    for error in duplicate_form_ids(paths):
        print(error, file=sys.stderr)
        failures += 1
    for path in paths:
        for error in validate(path, bindings):
            print(f'{path.relative_to(ROOT)}: {error}', file=sys.stderr)
            failures += 1
    if not failures:
        print(f'Validated {len(paths)} species packages in deterministic folder order.')
    return int(bool(failures))


if __name__ == '__main__':
    sys.exit(main())
