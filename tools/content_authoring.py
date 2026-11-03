#!/usr/bin/env python3
"""Validate ordered power, item and encounter resource definitions."""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ID = re.compile(r'^[a-z][a-z0-9_]*$')


def load_catalog(domain):
    folder = ROOT / 'content' / domain
    manifest = (folder / 'catalog.tres').read_text(encoding='utf-8')
    resources = re.findall(rf'path="res://content/{domain}/([^/]+)\.tres" id="(\d+)"', manifest)
    names = [name for name, _ in resources]
    entries = re.search(r'entries = Array\[Resource\]\(\[(.*?)\]\)', manifest).group(1)
    order = re.findall(r'ExtResource\("(\d+)"\)', entries)
    if order != [str(i) for i in range(len(names))] or [index for _, index in resources] != order or len(names) != len(set(names)):
        raise ValueError(f'{domain}: invalid manifest order')
    if set(names) != {p.stem for p in folder.glob('*.tres') if p.stem != 'catalog'}:
        raise ValueError(f'{domain}: manifest and definitions differ')
    result = {}
    for name in names:
        text = (folder / (name + '.tres')).read_text(encoding='utf-8')
        values = {}
        for key, value in re.findall(r'^([a-z_]+) = (.+)$', text, re.M):
            if key != 'script': values[key] = json.loads(value)
        if values.get('id') != name or not ID.fullmatch(name):
            raise ValueError(f'{domain}: invalid ID {name}')
        result[name] = values
    return result


def validate():
    errors = []
    try:
        powers, items, encounters = (load_catalog(x) for x in ('powers', 'items', 'encounters'))
        bindings = json.loads((ROOT / 'assets/runtime-lock.json').read_text())['bindings']
        for id, p in powers.items():
            for field in ('cost', 'damage', 'block', 'heal', 'priority', 'order'):
                if type(p.get(field)) is not int or (field != 'priority' and p[field] < 0): errors.append(f'{id}: invalid {field}')
            if p.get('nature') not in ('fire', 'water', 'lightning', 'forest') or p.get('learning') not in ('nature', 'lineage', 'universal'): errors.append(f'{id}: invalid learning or nature')
            if p.get('target') not in ('self', 'ally', 'enemy') or p.get('scope') not in ('single', 'upper_pair', 'lower_pair', 'all'): errors.append(f'{id}: invalid target or scope')
            if not isinstance(p.get('conditions'), dict) or any(k not in ('seed', 'electrified', 'burn', 'wet', 'taunt') or type(v) is not int or v < 0 for k, v in p['conditions'].items()): errors.append(f'{id}: invalid conditions')
            if p.get('art') not in bindings: errors.append(f'{id}: unpinned art')
            if not p.get('name') or not p.get('description'): errors.append(f'{id}: missing text')
        registry = (ROOT / 'scripts/battle/item_effects/registry.gd').read_text(encoding='utf-8')
        handler_ids = set(re.findall(r'"([a-z_]+)"\s*:\s*preload\(', registry))
        match = re.search(r'^const PARAMETER_SCHEMAS = (.+)$', registry, re.M)
        schemas = json.loads(match.group(1)) if match else {}
        if set(schemas) != handler_ids: errors.append('item handler schemas do not match registry')
        for id, item in items.items():
            effect = item.get('effect_id')
            if effect not in handler_ids: errors.append(f'{id}: unknown item effect')
            if type(item.get('cost')) is not int or item['cost'] < 0: errors.append(f'{id}: invalid cost')
            params = item.get('effect_parameters')
            schema = schemas.get(effect, {})
            if not isinstance(params, dict) or set(params) != set(schema) or set(params) & {'name', 'cost'}:
                errors.append(f'{id}: invalid effect parameters')
            else:
                for key, rules in schema.items():
                    value = params[key]
                    valid_type = type(value) is int if rules.get('type') == 'integer' else type(value) in (int, float) if rules.get('type') == 'number' else False
                    if not valid_type or ('min_exclusive' in rules and value <= rules['min_exclusive']) or ('max_inclusive' in rules and value > rules['max_inclusive']):
                        errors.append(f'{id}: invalid effect parameter {key}')
            if not item.get('name') or not item.get('description'): errors.append(f'{id}: missing text')
        species = set(re.findall(r'path="res://content/species/([^/]+)/species.tres"', (ROOT / 'content/species/catalog.tres').read_text()))
        forms = {}
        for sid in species:
            source = (ROOT / 'content/species' / sid / 'species.tres').read_text()
            forms[sid] = set(re.findall(r'"id"\s*:\s*"([a-z_][a-z0-9_]*)"', source.split('evolutions = ')[0]))
        for id, e in encounters.items():
            if e.get('art') not in bindings: errors.append(f'{id}: unpinned art')
            lore = e.get('lore')
            if not e.get('name') or not e.get('subtitle') or not isinstance(lore, dict) or not lore.get('title') or not lore.get('text') or not e.get('enemies'): errors.append(f'{id}: missing content')
            if type(e.get('hp')) is not int or e['hp'] <= 0 or not isinstance(e.get('intents'), list) or not e['intents'] or any(type(x) is not int or x < 0 for x in e['intents']): errors.append(f'{id}: invalid summary')
            uids, slots = set(), set()
            for enemy in e.get('enemies', []):
                sid = enemy.get('species')
                if sid not in species or enemy.get('form_id') not in forms.get(sid, set()): errors.append(f'{id}: unknown enemy species or form')
                if enemy.get('art') not in bindings: errors.append(f'{id}: unpinned enemy art')
                for field in ('uid', 'max_hp', 'hp', 'attack', 'defense', 'speed', 'slot'):
                    value = enemy.get(field)
                    if type(value) is not int or value < (1 if field in ('uid', 'max_hp', 'hp') else 0): errors.append(f'{id}: invalid enemy {field}')
                if type(enemy.get('hp')) is int and type(enemy.get('max_hp')) is int and enemy['hp'] > enemy['max_hp']: errors.append(f'{id}: enemy hp exceeds maximum')
                if enemy.get('uid') in uids or enemy.get('slot') in slots or enemy.get('slot') not in (0, 1, 2): errors.append(f'{id}: duplicate or invalid enemy UID/slot')
                uids.add(enemy.get('uid'))
                slots.add(enemy.get('slot'))
                if not enemy.get('name') or not isinstance(enemy.get('pattern'), list) or not enemy['pattern']: errors.append(f'{id}: missing enemy name or pattern')
                for step in enemy.get('pattern', []):
                    if step.get('nature') not in ('fire', 'water', 'lightning', 'forest') or step.get('category') not in ('attack', 'defend', 'prepare') or step.get('scope') not in ('single', 'upper_pair', 'lower_pair', 'all') or step.get('target_policy', 'random') not in ('random', 'weakest'): errors.append(f'{id}: unknown enemy action reference')
                    if not isinstance(step.get('conditions'), dict) or any(k not in ('seed', 'electrified', 'burn', 'wet', 'taunt') or type(v) is not int or v < 0 for k, v in step['conditions'].items()): errors.append(f'{id}: invalid enemy conditions')
                    for field in ('damage', 'block', 'wet'):
                        if type(step.get(field)) is not int or step[field] < 0: errors.append(f'{id}: invalid enemy action {field}')
                    for field in ('charge', 'priority'):
                        if field in step and (type(step[field]) is not int or (field == 'charge' and step[field] < 0)): errors.append(f'{id}: invalid enemy action {field}')
    except (ValueError, KeyError, TypeError, AttributeError, json.JSONDecodeError) as exc:
        errors.append(str(exc))
    return errors


def author(domain, identifier, fallback):
    if not ID.fullmatch(identifier): raise ValueError('invalid stable ID')
    folder = ROOT / 'content' / domain
    source = folder / (fallback + '.tres')
    destination = folder / (identifier + '.tres')
    if not source.is_file() or fallback not in load_catalog(domain): raise ValueError('fallback is not in the manifest')
    if destination.exists(): raise ValueError('definition already exists')
    manifest_path = folder / 'catalog.tres'
    manifest = manifest_path.read_text(encoding='utf-8')
    names = load_catalog(domain)
    index = len(names)
    manifest = re.sub(r'load_steps=(\d+)', lambda m: f'load_steps={int(m[1]) + 1}', manifest, count=1)
    entry = f'[ext_resource type="Resource" path="res://content/{domain}/{identifier}.tres" id="{index}"]\n'
    manifest = manifest.replace('\n[resource]\n', '\n' + entry + '\n[resource]\n', 1)
    manifest = manifest.replace('])', f', ExtResource("{index}")])', 1)
    destination.write_text(source.read_text(encoding='utf-8').replace('id = ' + json.dumps(fallback), 'id = ' + json.dumps(identifier), 1), encoding='utf-8')
    manifest_path.write_text(manifest, encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('validate')
    make = sub.add_parser('author')
    make.add_argument('domain', choices=['powers', 'items', 'encounters'])
    make.add_argument('id')
    make.add_argument('--fallback', required=True)
    args = parser.parse_args()
    if args.command == 'author':
        try: author(args.domain, args.id, args.fallback)
        except ValueError as exc: parser.error(str(exc))
        print('Created and registered definition; review all fields and pinned art.')
        return 0
    errors = validate()
    for error in errors: print(error, file=sys.stderr)
    if not errors: print('Validated ordered power, item and encounter catalogs.')
    return bool(errors)


if __name__ == '__main__':
    sys.exit(main())
