"""Render immutable HTML copies and pair screenshots with original portal sheets."""
import argparse
import base64
import hashlib
from html import escape
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw
from playwright.sync_api import sync_playwright


def inside(root, value):
    path = (root / value).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError('Review path escapes source artifact')
    return path


def content(image):
    image = image.convert('RGBA')
    white = Image.new('RGBA', image.size, 'white')
    white.alpha_composite(image)
    rgb = white.convert('RGB')
    mask = ImageChops.difference(rgb, Image.new('RGB', rgb.size, 'white')).convert('L')
    bbox = mask.point(lambda value: 255 if value > 25 else 0).getbbox()
    if bbox:
        x1, y1, x2, y2 = bbox
        return rgb.crop((max(0, x1-12), max(0, y1-12), min(rgb.width, x2+12), min(rgb.height, y2+12)))
    return rgb


def pair(source, screenshot, target):
    panels = []
    for path in [source, screenshot]:
        with Image.open(path) as raw:
            panel = content(raw)
            panel = panel.resize((1000, max(1, round(panel.height * 1000 / panel.width))))
            panels.append(panel)
    canvas = Image.new('RGB', (2024, max(panel.height for panel in panels) + 42), 'white')
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 12), 'FICHA OFICIAL (escala ajustada)', fill='black')
    draw.text((1024, 12), 'HTML RENDERIZADO (escala ajustada)', fill='black')
    draw.line((1012, 0, 1012, canvas.height), fill='#888888', width=2)
    for index, panel in enumerate(panels):
        canvas.paste(panel, (index * 1012 + 6, 36))
    canvas.save(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--review', type=Path, default=Path('portal-review'))
    parser.add_argument('--catalog', type=Path, default=Path('assets/cantos.json'))
    parser.add_argument('--limit', type=int, default=0)
    parser.add_argument('--chromium', help='Optional system Chromium executable')
    args = parser.parse_args()
    root = args.review.resolve()
    output = root / 'visual-review'
    output.mkdir(parents=True, exist_ok=True)
    report = json.loads((root / 'report.json').read_text(encoding='utf-8'))
    catalog = json.loads(args.catalog.read_text(encoding='utf-8')) if args.catalog.exists() else []
    by_key = {song['html']: song for song in catalog}
    entries = []
    browser_options = {'headless': True}
    if args.chromium:
        browser_options['executable_path'] = args.chromium
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(**browser_options)
        context = browser.new_context(viewport={'width': 1100, 'height': 900},
                                      device_scale_factor=2, java_script_enabled=False,
                                      color_scheme='light')
        context.route('**/*', lambda route: route.continue_() if route.request.url.startswith('file:') else route.abort())
        page = context.new_page()

        def capture(path, target):
            page.goto(path.as_uri(), wait_until='load', timeout=15000)
            page.screenshot(path=str(target), full_page=True, animations='disabled', timeout=30000)

        legacy_cache = {}
        for record in report['pages']:
            for sheet in record['sheets']:
                if args.limit and len(entries) >= args.limit:
                    break
                item = {'title': record['title'], 'page': record['page'], 'sourceUrl': sheet['url'],
                        'status': 'pending_visual_review', 'legacy': []}
                try:
                    source = inside(root, sheet['image'])
                    draft = inside(root, sheet['draft'])
                    key = draft.parent.name
                    screenshot = output / f'{key}-draft.png'
                    paired = output / f'{key}-pair.png'
                    capture(draft, screenshot)
                    pair(source, screenshot, paired)
                    item.update({'key': key, 'image': '../' + sheet['image'], 'draft': '../' + sheet['draft'],
                                 'screenshot': screenshot.name, 'pair': paired.name,
                                 'meanConfidence': sheet.get('meanConfidence'),
                                 'columnCollisions': sheet.get('columnCollisions')})
                    for match in record.get('legacyMatches', []):
                        song = by_key.get(match['html'])
                        if song is None:
                            continue
                        if song['html'] not in legacy_cache:
                            legacy = {'html': song['html'], 'id': song['id']}
                            token = hashlib.sha256(song['html'].encode()).hexdigest()[:16]
                            for field, label in [('html_base64', 'normal'), ('ext_base64', 'extended')]:
                                html_path = output / f'current-{token}-{label}.html'
                                image_path = output / f'current-{token}-{label}.png'
                                # Decode into a separate evidence file, without rewriting whitespace,
                                # markers, colors, IDs, or either variant of the catalog.
                                data = base64.b64decode(song.get(field, ''), validate=True)
                                if data:
                                    html_path.write_bytes(data)
                                    capture(html_path, image_path)
                                    legacy[label] = image_path.name
                            legacy_cache[song['html']] = legacy
                        item['legacy'].append(legacy_cache[song['html']])
                except Exception as error:
                    item['error'] = str(error)
                entries.append(item)
                print(f"Rendered {len(entries)}: {item.get('key', 'failed')}; error={item.get('error', 'none')}", flush=True)
        browser.close()
    manifest = {'reviewRequired': True, 'catalogModified': False, 'extendedDefaultPreserved': True,
                'renderer': 'Chromium, CSS monospace, 1100 CSS px, device scale 2; not a physical-device screenshot',
                'entries': entries}
    (output / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    cards = []
    for item in entries:
        links = [f'<a href="{escape(item[field])}">{label}</a>' for field, label in
                 [('image', 'Ficha original'), ('draft', 'Rascunho HTML'), ('screenshot', 'Print do rascunho'), ('pair', 'Comparação lado a lado')]
                 if field in item]
        for legacy in item['legacy']:
            for field, label in [('normal', 'HTML atual normal'), ('extended', 'HTML atual estendido')]:
                if field in legacy:
                    links.append(f'<a href="{escape(legacy[field])}">{label}: {escape(legacy["html"])}</a>')
        picture = f'<img loading="lazy" src="{escape(item["pair"])}" alt="Ficha e captura do HTML">' if 'pair' in item else ''
        cards.append(f'<article><h2>{escape(item["title"])}</h2><p>Pendente de revisão visual. '
                     f'<a href="{escape(item["page"])}">Página oficial</a></p><nav>{" | ".join(links)}</nav>'
                     f'<p>{escape(item.get("error", ""))}</p>{picture}</article>')
    html = '''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Revisão visual dos cantos</title><style>body{font:16px system-ui;margin:24px;background:#f4f4f4;color:#222}
article{background:white;padding:16px;margin:24px 0;border:1px solid #bbb}img{width:100%;height:auto}a{color:#124c91}
nav{line-height:2}input{font:inherit;padding:8px;width:min(90%,600px)}</style>
<h1>Revisão visual dos cantos</h1><p>Prints gerados para comparação. A captura não aprova letras, cifras ou alinhamento automaticamente.</p>
<p>A versão estendida atual permanece preservada e ativada por padrão: repetições por extenso, sem barra de bis.
As diferenças intencionais da versão estendida não são erros de OCR.</p><p>Confira letra, acidentes, acordes, posição das cifras e repetições.
Os HTMLs e imagens originais permanecem inalterados.</p><input id="filter" placeholder="Filtrar por título" aria-label="Filtrar por título">
''' + ''.join(cards) + '''<script>document.querySelector('#filter').addEventListener('input',event=>{
const key=event.target.value.toLocaleLowerCase('pt-BR');document.querySelectorAll('article').forEach(card=>{
card.hidden=!card.querySelector('h2').textContent.toLocaleLowerCase('pt-BR').includes(key);});});</script></html>'''
    (output / 'index.html').write_text(html, encoding='utf-8')
    summary = {'rendered': sum('screenshot' in item for item in entries),
               'errors': sum('error' in item for item in entries), 'visuallyApproved': 0, 'catalogModified': False}
    print('VISUAL_REVIEW_SUMMARY=' + json.dumps(summary), flush=True)
    if not summary['rendered']:
        raise SystemExit('No HTML screenshots produced')


if __name__ == '__main__':
    main()
