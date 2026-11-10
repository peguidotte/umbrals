"""Presentation contract on top of immutable asset releases; no gameplay catalog copy."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

from jsonschema import Draft202012Validator
from PIL import Image

from asset_pipeline import AssetError, ROOT, digest, inside, load_releases, read_json
from harness_lib.executor import environment

BINDING = 'ui/power-card-system'
SCHEMA = 'assets/schemas/card-presentation-v1.schema.json'


def snapshot(root: Path = ROOT, compatibility: bool = True) -> dict:
    command = ['godot', '--headless', '--path', str(root), '--script', str(root / 'tools/card_visual_snapshot.gd')]
    if compatibility:
        command += ['--', '--compatibility']
    result = subprocess.run(command, cwd=root, env=environment(root), capture_output=True, text=True, timeout=60)
    output = result.stdout + result.stderr
    if result.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
        raise AssetError('Card demand exporter failed: ' + output[-5000:])
    return next(json.loads(line) for line in result.stdout.splitlines() if line.startswith('{'))


def reference_key(ref: dict) -> str:
    return f"{ref['id']}@{ref['version']}:{ref['role']}"


def load_presentation(root: Path, release: tuple, releases: dict) -> tuple[dict, dict]:
    if release not in releases:
        raise AssetError(f'Unknown card presentation release: {release}')
    path, module = releases[release]
    record = module['files'].get('presentation', {})
    if record.get('kind') != 'data':
        raise AssetError('Card presentation must be a data role of its asset module')
    data_path = inside(path.parent, record['path'])
    if digest(data_path) != record['sha256'] or data_path.stat().st_size != record['bytes']:
        raise AssetError('Card presentation integrity mismatch')
    data = read_json(data_path)
    errors = sorted(Draft202012Validator(read_json(root / SCHEMA)).iter_errors(data), key=lambda error: str(error.path))
    if errors:
        raise AssetError('Invalid card presentation: ' + str(list(errors[0].path)) + ': ' + errors[0].message)
    return data, module


def validate_presentation(root: Path, release: tuple, demand: dict, mode: str = 'development', releases: dict | None = None) -> dict:
    releases = load_releases(root) if releases is None else releases
    data, module = load_presentation(root, release, releases)
    production = mode == 'production'
    for name in ('art_region', 'safe_region'):
        region = data['layout'][name]
        if region[0] + region[2] > 1 or region[1] + region[3] > 1:
            raise AssetError('Card layout region escapes normalized bounds: ' + name)
    issues, used, art_users, rows = [], set(), {}, []
    allowed = {(dep['id'], dep['version']) for dep in module['dependencies']} | {release}

    def issue(kind, key, reason):
        entry = {'kind': kind, 'key': key, 'reason': reason}
        if entry not in issues:
            issues.append(entry)

    def asset(entry, kind, key, alpha=False, inspect_only=False):
        if not entry or entry.get('asset') is None:
            if not inspect_only:
                issue(kind, key, 'missing_asset')
            return False
        ref = entry['asset']
        ref_key = reference_key(ref)
        used.add(ref_key)
        pair = (ref['id'], ref['version'])
        if pair not in allowed or pair not in releases:
            raise AssetError(f'Card reference lacks an exact declared dependency: {ref_key}')
        path, owner = releases[pair]
        record = owner['files'].get(ref['role'], {})
        if record.get('kind') != 'texture':
            raise AssetError(f'Card reference is not a texture role: {ref_key}')
        texture = inside(path.parent, record['path'])
        if not texture.is_file() or digest(texture) != record['sha256'] or texture.stat().st_size != record['bytes']:
            raise AssetError(f'Card texture integrity mismatch: {ref_key}')
        # Actual pixel readability/alpha is checked, not metadata claims alone.
        try:
            with Image.open(texture) as image:
                image.load()
                technical = record.get('technical', {})
                if technical.get('dimensions') != list(image.size) or technical.get('mode') != image.mode or technical.get('alpha') != ('A' in image.getbands() or 'transparency' in image.info):
                    raise AssetError('Card texture metadata differs from decoded pixels: ' + ref_key)
                if max(image.size) > 4096 or record['bytes'] > 16 * 1024**2:
                    raise AssetError('Card texture exceeds existing budgets: ' + ref_key)
                if alpha and ('A' not in image.getbands() or image.getchannel('A').getextrema()[0] != 0):
                    raise AssetError('Card frame/ornament needs real transparent pixels: ' + ref_key)
        except AssetError:
            raise
        except (OSError, ValueError) as error:
            raise AssetError('Card texture cannot be decoded: ' + ref_key) from error
        if entry['status'] != 'approved' or not entry['review'].strip() or owner['status'] != 'production':
            if inspect_only and production:
                raise AssetError('Production card reference uses unapproved art: ' + key)
            if not inspect_only:
                issue(kind, key, 'not_approved')
        return True

    def inspect_all(value, path=()):
        if isinstance(value, dict):
            if value.get('asset') is not None:
                alpha = any(part in {'default_frame', 'form_overrides', 'art_border', 'title_plate', 'owner_plate'} for part in path)
                asset(value, 'reference', '/'.join(path), alpha=alpha, inspect_only=True)
            for key, child in value.items():
                inspect_all(child, (*path, key))
        elif isinstance(value, list):
            for index, child in enumerate(value):
                inspect_all(child, (*path, str(index)))

    # Even an unused default/override/demo must not hide a dangling or draft reference.
    inspect_all(data)

    expected = {(row['species_id'], row['form_id'], row['power_id']) for row in demand['entries']}
    demos = {(row['species_id'], row['form_id'], row['power_id']) for row in data['coverage']['demonstrations']}
    for species, family in data['families'].items():
        known = {form for form, info in demand['forms'].items() if info['species_id'] == species}
        if not known or set(family['reuse_default_for_forms']) | set(family['form_overrides']) != known:
            raise AssetError('Every family form must explicitly select default or override: ' + species)
        if set(family['reuse_default_for_forms']) & set(family['form_overrides']):
            raise AssetError('A form cannot select both default and override: ' + species)
    for nature in data['power_styles']:
        if nature not in demand['natures']:
            raise AssetError('Unknown card power nature: ' + nature)
    for species, by_form in data['illustrations'].items():
        for form, by_power in by_form.items():
            if demand['forms'].get(form, {}).get('species_id') != species:
                raise AssetError('Card illustration has unknown species/form: ' + species + '/' + form)
            for power, entry in by_power.items():
                key = (species, form, power)
                if key not in expected | demos:
                    raise AssetError('Undeclared nonplayable illustration: ' + '/'.join(key))
                if entry['asset']:
                    art_users.setdefault(reference_key(entry['asset']), []).append((key, entry))
                if key in demos and key not in expected:
                    asset(entry, 'demonstration', '/'.join(key))
    for users in art_users.values():
        if len(users) > 1 and any(not entry.get('reuse', {}).get('reason', '').strip() or not entry.get('reuse', {}).get('review', '').strip() for _, entry in users):
            raise AssetError('Shared illustration requires an explicit identity-preserving reuse review')
    for row in demand['entries']:
        species, form, power = row['species_id'], row['form_id'], row['power_id']
        key = '/'.join([species, form, power])
        family = data['families'].get(species, {})
        frame = family.get('form_overrides', {}).get(form) if form in family.get('form_overrides', {}) else family.get('default_frame') if form in family.get('reuse_default_for_forms', []) else None
        asset(frame, 'frame', species + '/' + form, alpha=True)
        style = data['power_styles'].get(row['nature'], {})
        for role in ['art_border', 'title_plate', 'owner_plate']:
            asset(style.get(role), role, row['nature'], alpha=True)
        if style and style.get('tokens'):
            def luminance(color):
                components = [int(color[index:index + 2], 16) / 255 for index in (1, 3, 5)]
                linear = [value / 12.92 if value <= .04045 else ((value + .055) / 1.055) ** 2.4 for value in components]
                return sum(a * b for a, b in zip(linear, [.2126, .7152, .0722]))
            colors = [luminance(style['tokens'][name]) for name in ['background', 'foreground']]
            if (max(colors) + .05) / (min(colors) + .05) < 4.5:
                raise AssetError('Card plate text contrast below 4.5: ' + row['nature'])
        else:
            issue('tokens', row['nature'], 'missing_tokens')
        entry = data['illustrations'].get(species, {}).get(form, {}).get(power)
        covered = asset(entry, 'illustration', key)
        approved = covered and entry['status'] == 'approved' and bool(entry['review'].strip()) and releases[(entry['asset']['id'], entry['asset']['version'])][1]['status'] == 'production'
        rows.append({**row, 'covered': covered, 'approved': approved})
    for kind, required in [('target_portraits', demand['forms']), ('enemy_portraits', demand['enemy_portraits'])]:
        if set(data[kind]) - set(required):
            raise AssetError('Unknown portrait identity in ' + kind)
        for key in required:
            entry = data[kind].get(key)
            if entry:
                x, y, w, h = entry['crop']
                fx, fy = entry['focal_point']
                if x + w > 1 or y + h > 1 or not (x <= fx <= x + w and y <= fy <= y + h):
                    raise AssetError('Portrait crop/focal point escapes normalized bounds: ' + key)
            asset(entry, kind, key)
    pending = sorted(item['kind'] + ':' + item['key'] for item in issues)
    if set(data['coverage']['pending']) != set(pending):
        raise AssetError('Development pending inventory is stale; refresh it from coverage diagnostics')
    if module['status'] != 'production':
        issue('presentation', '@'.join(release), 'not_production')
    if data['coverage']['scope'] != 'catalog':
        issue('scope', '@'.join(release), 'not_complete_catalog')
    if production and (not data['layout']['review'].strip() or any(ref['availability'] != 'inspected' for ref in data['visual_references'])):
        issue('visual_review', '@'.join(release), 'not_inspected')
    declared = {reference_key({'id': owner['id'], 'version': owner['version'], 'role': role}) for pair, (_, owner) in releases.items() if pair in allowed - {release} for role, record in owner['files'].items() if record['kind'] == 'texture'}
    return {'schema_version': 1, 'mode': mode, 'release': '@'.join(release), 'ready': not issues, 'failed': len(issues) if production else 0, 'required': len(rows), 'covered': sum(row['covered'] for row in rows), 'approved': sum(row['approved'] for row in rows), 'rows': rows, 'missing_entries': issues, 'pending': pending, 'demonstrations': data['coverage']['demonstrations'], 'orphan_texture_roles': sorted(declared - used), 'compatibility_fixtures': demand.get('compatibility_fixtures', [])}


def export_gate(root: Path = ROOT) -> dict:
    pin = read_json(root / 'assets/runtime-lock.json')['bindings'].get(BINDING)
    if not pin:
        return {'enabled': False, 'reason': 'legacy presentation; new system is not promoted'}
    # Preserve the existing pipeline's hashes, cycles, generated files and pin rules.
    from asset_pipeline import validate
    validate(root)
    report = validate_presentation(root, (pin['id'], pin['version']), snapshot(root), 'production')
    if report['failed']:
        raise AssetError(f"Card production gate failed: {report['failed']} missing/unapproved entries")
    return report
