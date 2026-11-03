"""Validate the legacy HTML contract without normalizing or rewriting it."""
import argparse
import base64
from collections import defaultdict
import json
from pathlib import Path
import re
import sys


KNOWN_LEGACY_COLLISIONS = {227: {'A ESPADA', 'ALELUIA PASCAL II'}}


def validate_catalog(cantos, baseline=None):
    errors = []
    identifiers = defaultdict(list)
    filenames = set()
    previous = {song['html']: song for song in baseline or []}
    for song in cantos:
        name = song.get('html', '')
        identifier = song.get('id')
        if not name or name in filenames:
            errors.append(f'Invalid or duplicate audio/HTML key: {name!r}')
        filenames.add(name)
        identifiers[identifier].append(name)
        old = previous.get(name)
        if old is not None and identifier != old['id']:
            errors.append(f'{name}: existing ID changed; saved lists/notes need a migration')
        for field in ('html_base64', 'ext_base64'):
            try:
                html = base64.b64decode(song[field], validate=True).decode('utf-8')
            except (KeyError, ValueError, UnicodeError) as error:
                errors.append(f'{name}/{field}: invalid UTF-8/base64: {error}')
                continue
            if not re.search(r'font-family\s*:\s*monospace', html, re.I):
                errors.append(f'{name}/{field}: monospace font missing')
            if not re.search(r'white-space\s*:\s*pre\s*[;}]', html, re.I):
                errors.append(f'{name}/{field}: white-space:pre missing (pre-wrap is not equivalent)')
            for marker in ('@transp@', '@capot@'):
                if marker not in html:
                    errors.append(f'{name}/{field}: {marker} missing')
                if old is not None:
                    old_html = base64.b64decode(old[field]).decode('utf-8')
                    if html.count(marker) != old_html.count(marker):
                        errors.append(f'{name}/{field}: {marker} count changed')
            if re.search(r'<h1\b', html, re.I) and '<H1>' not in html:
                errors.append(f'{name}/{field}: title must retain the case-sensitive <H1> marker')
            if '#FF0000' not in html:
                errors.append(f'{name}/{field}: case-sensitive red chord marker #FF0000 missing')
            if 'font-size:12px' not in html:
                errors.append(f'{name}/{field}: font-size:12px hook missing')
            if old is not None:
                old_html = base64.b64decode(old[field]).decode('utf-8')
                if '\t' in old_html and '\t' not in html:
                    errors.append(f'{name}/{field}: all tabs removed; review alignment')
    for identifier, names in identifiers.items():
        if not isinstance(identifier, int) or isinstance(identifier, bool):
            errors.append(f'Invalid ID: {identifier!r}')
        if len(names) > 1 and set(names) != KNOWN_LEGACY_COLLISIONS.get(identifier):
            errors.append(f'New ID collision: {identifier}: {names}')
    removed = set(previous) - filenames
    if removed:
        errors.append(f'Existing songs removed without a saved-data migration: {sorted(removed)}')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('catalog', type=Path)
    parser.add_argument('--baseline', type=Path)
    args = parser.parse_args()
    data = json.loads(args.catalog.read_text(encoding='utf-8'))
    baseline = json.loads(args.baseline.read_text(encoding='utf-8')) if args.baseline else None
    errors = validate_catalog(data, baseline)
    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        return 1
    print(f'Validated {len(data)} songs and both HTML variants. No content rewritten.')
    if any(song['id'] == 227 for song in data):
        print('Known legacy ID 227 collision retained; do not renumber automatically.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
