"""Validate/render an inactive review candidate, without modifying app assets."""
import argparse
import base64
import copy
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backend'))
from search_service.corrections import apply_corrections
from validate_catalog import validate_catalog


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--validate-only', action='store_true')
    parser.add_argument('--chromium')
    parser.add_argument('--source', type=Path, help='Official sheet image for comparison pairs')
    args = parser.parse_args()
    baseline = json.loads((ROOT / 'assets/cantos.json').read_text())
    proposal = json.loads((ROOT / 'docs/revisao/candidata_ressuscitou_pontuacao.json').read_text())
    candidate = copy.deepcopy(baseline)
    original = next(s for s in baseline if s['html'] == 'RESSUSCITOU')
    for field, rule in proposal['songs']['RESSUSCITOU'].items():
        if hashlib.sha256(original[field].encode()).hexdigest() != rule['sourceSha256']:
            raise ValueError('Catalog changed; re-review required')
    apply_corrections(candidate, proposal['songs'])
    errors = validate_catalog(candidate, baseline)
    if errors:
        raise ValueError(errors)
    revised = next(s for s in candidate if s['html'] == 'RESSUSCITOU')
    for before, after in zip(baseline, candidate):
        fields = {key for key in before if before[key] != after[key]}
        expected = {'html_base64', 'ext_base64'} if before['html'] == 'RESSUSCITOU' else set()
        if fields != expected:
            raise ValueError('Unexpected catalog change')
    for field in ('html_base64', 'ext_base64'):
        old = base64.b64decode(original[field]).decode()
        new = base64.b64decode(revised[field]).decode()
        if new.replace('Alegria, alegria, irmãos,', 'Alegria, alegria irmãos,', 1) != old:
            raise ValueError('Unexpected HTML difference')
        if ''.join(c for c in old if c.isspace()) != ''.join(c for c in new if c.isspace()):
            raise ValueError('Whitespace changed')
    second = copy.deepcopy(candidate)
    apply_corrections(second, proposal['songs'])
    if candidate != second:
        raise ValueError('Candidate is not idempotent')
    args.output.mkdir(parents=True, exist_ok=True)
    for field, label in [('html_base64', 'normal'), ('ext_base64', 'extended')]:
        for song, stage in [(original, 'before'), (revised, 'after')]:
            (args.output / f'{label}-{stage}.html').write_bytes(base64.b64decode(song[field]))
    print(f'Validated {len(candidate)} songs / both variants; only two candidate commas added.')
    print('App assets unchanged. Visual review still required.')
    if args.validate_only:
        return
    from playwright.sync_api import sync_playwright
    from render_portal_review import pair
    with sync_playwright() as p:
        options = {'headless': True}
        if args.chromium:
            options['executable_path'] = args.chromium
        browser = p.chromium.launch(**options)
        context = browser.new_context(viewport={'width': 1100, 'height': 900},
                                      device_scale_factor=2, java_script_enabled=False)
        context.route('**/*', lambda route: route.abort())
        page = context.new_page()
        for label in ('normal', 'extended'):
            for stage in ('before', 'after'):
                name = f'{label}-{stage}'
                page.set_content((args.output / f'{name}.html').read_bytes().decode(), wait_until='load')
                screenshot = args.output / f'{name}.png'
                page.screenshot(path=str(screenshot), full_page=True, animations='disabled')
                if args.source:
                    pair(args.source, screenshot, args.output / f'{name}-pair.jpg')
        browser.close()
    print('Screenshots generated; they require human/agent visual inspection before promotion.')


if __name__ == '__main__':
    main()
