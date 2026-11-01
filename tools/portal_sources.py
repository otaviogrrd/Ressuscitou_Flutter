"""Download official sheets and prepare review drafts; never overwrite the app catalog."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import csv
import hashlib
from html import escape
from html.parser import HTMLParser
import io
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import threading
import time
import unicodedata
from urllib.parse import urljoin, urlsplit, urlunsplit
from urllib.request import Request, urlopen


ROOT = 'https://cn.org.br/portal/'
INDEXES = {
    1: 'ressuscitou-pre-catecumenato/',
    2: 'ressuscitou-catecumenato/',
    3: 'ressuscitou-eleicao/',
    4: 'ressuscitou-liturgia/',
}
IMAGE_HOST = 'd1f12s1rtcamoi.cloudfront.net'
ALLOWED_HOSTS = {'cn.org.br', 'www.cn.org.br', IMAGE_HOST}
VOID = {'img', 'br', 'meta', 'link', 'input', 'hr', 'source', 'area', 'wbr'}
_request_lock = threading.Lock()
_last_request = 0.0


def normalize(text):
    text = unicodedata.normalize('NFD', text.casefold())
    return re.sub(r'[^a-z0-9]', '', ''.join(c for c in text if not unicodedata.combining(c)))


class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.links = []
        self.images = []
        self.content_images = []
        self.anchor = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        inside = any('entry-content' in classes for _, classes in self.stack)
        if tag == 'a' and attrs.get('href'):
            self.anchor = {'href': attrs['href'], 'text': '', 'content': inside}
        if tag == 'img':
            for key in ('src', 'data-src', 'data-lazy-src'):
                if attrs.get(key):
                    self.images.append(attrs[key])
                    if inside:
                        self.content_images.append(attrs[key])
            for candidate in (attrs.get('srcset') or '').split(','):
                if candidate.strip():
                    self.images.append(candidate.strip().split()[0])
                    if inside:
                        self.content_images.append(candidate.strip().split()[0])
        if tag not in VOID:
            self.stack.append((tag, (attrs.get('class') or '').split()))

    def handle_endtag(self, tag):
        if tag == 'a' and self.anchor:
            self.links.append(self.anchor)
            self.anchor = None
        for index in range(len(self.stack) - 1, -1, -1):
            if self.stack[index][0] == tag:
                del self.stack[index:]
                break

    def handle_data(self, data):
        if self.anchor is not None:
            self.anchor['text'] += data


def checked_url(url):
    parsed = urlsplit(url)
    if parsed.scheme != 'https' or parsed.hostname not in ALLOWED_HOSTS:
        raise ValueError(f'Unexpected source URL: {url}')
    return url


def fetch(url, max_bytes=15_000_000):
    global _last_request
    checked_url(url)
    with _request_lock:
        delay = 0.25 - (time.monotonic() - _last_request)
        if delay > 0:
            time.sleep(delay)
        _last_request = time.monotonic()
    request = Request(url, headers={'User-Agent': 'RessuscitouCatalogReview/1.0 (+https://github.com/otaviogrrd/Ressuscitou_Flutter)'})
    with urlopen(request, timeout=40) as response:
        checked_url(response.geturl())
        data = response.read(max_bytes + 1)
    if len(data) > max_bytes:
        raise ValueError(f'Source exceeds size limit: {url}')
    return data


def parse_page(data):
    page = Page()
    page.feed(data.decode('utf-8'))
    return page


def discover():
    records = {}
    excluded = {urljoin(ROOT, value) for value in INDEXES.values()} | {ROOT, urljoin(ROOT, 'ressuscitou/')}
    for category, path in INDEXES.items():
        page = parse_page(fetch(urljoin(ROOT, path)))
        links = [link for link in page.links if link['content']] or page.links
        for link in links:
            url = urljoin(ROOT, link['href'])
            parsed = urlsplit(url)
            url = urlunsplit((parsed.scheme, parsed.netloc, parsed.path, '', ''))
            if parsed.hostname not in {'cn.org.br', 'www.cn.org.br'} or url in excluded:
                continue
            if not re.fullmatch(r'/portal/[^/]+/', parsed.path) or not link['text'].strip():
                continue
            if url not in records:
                records[url] = {'page': url, 'title': link['text'].strip(), 'categories': []}
            if category not in records[url]['categories']:
                records[url]['categories'].append(category)
    if len(records) < 100:
        raise ValueError(f'Only {len(records)} pages discovered; portal structure may have changed')
    return list(records.values())


def sheet_urls(page):
    urls = page.images + [link['href'] for link in page.links]
    result = []
    for value in urls:
        url = urljoin(ROOT, value)
        parsed = urlsplit(url)
        official_cdn = parsed.hostname == IMAGE_HOST and parsed.path.startswith('/fichas/')
        portal_upload = (parsed.hostname in {'cn.org.br', 'www.cn.org.br'}
                         and parsed.path.startswith('/portal/wp-content/uploads/')
                         and value in page.content_images)
        if parsed.scheme == 'https' and (official_cdn or portal_upload) and parsed.path.lower().endswith(('.png', '.jpg', '.jpeg')):
            if url not in result:
                result.append(url)
    return result


def tsv_words(image_path):
    command = ['tesseract', str(image_path), 'stdout', '-l', 'por+eng', '--psm', '6', 'tsv']
    result = subprocess.run(command, check=True, text=True, capture_output=True,
                            timeout=90, env={**os.environ, 'OMP_THREAD_LIMIT': '1'})
    words = []
    for row in csv.DictReader(io.StringIO(result.stdout), delimiter='\t'):
        text = (row.get('text') or '').strip()
        if text and float(row.get('conf', '-1')) >= 0:
            words.append({**{key: int(row[key]) for key in ('left', 'top', 'width', 'height')},
                          'text': text, 'confidence': float(row['conf'])})
    return words


def ocr_planes(image_path, work):
    from PIL import Image
    source = Image.open(image_path).convert('RGBA')
    canvas = Image.new('RGBA', source.size, 'white')
    canvas.alpha_composite(source)
    image = canvas.convert('RGB')
    if image.width < 1800:
        image = image.resize((image.width * 2, image.height * 2))
    ink = Image.new('L', image.size, 255)
    chords = Image.new('L', image.size, 255)
    red_pixels = []
    black_pixels = []
    for r, g, b in image.getdata():
        red = r > 100 and r > g * 1.35 and r > b * 1.35 and r - min(g, b) > 40
        black = max(r, g, b) < 180 and not red
        red_pixels.append(0 if red else 255)
        black_pixels.append(0 if black else 255)
    chords.putdata(red_pixels)
    ink.putdata(black_pixels)
    ink_path, red_path = work / 'text.png', work / 'chords.png'
    ink.save(ink_path)
    chords.save(red_path)
    words = []
    for path, kind in [(ink_path, 'text'), (red_path, 'red')]:
        words.extend({**word, 'kind': kind} for word in tsv_words(path))
    return words


def lines_from_words(words):
    if not words:
        return [], 0, 0
    widths = [word['width'] / len(word['text']) for word in words if len(word['text']) >= 3]
    cell = statistics.median(widths) if widths else 12
    origin = min(word['left'] for word in words)
    rows = []
    for word in sorted(words, key=lambda item: (item['top'] + item['height'] / 2, item['left'])):
        center = word['top'] + word['height'] / 2
        candidates = [row for row in rows if row['kind'] == word['kind'] and abs(row['center'] - center) < max(6, word['height'] * 0.4)]
        if candidates:
            candidates[-1]['words'].append(word)
        else:
            rows.append({'center': center, 'kind': word['kind'], 'words': [word]})
    overlaps = 0
    for row in rows:
        tokens = [word['text'] for word in row['words']]
        chord_line = row['kind'] == 'red' and sum(bool(CHORD.fullmatch(token)) for token in tokens) >= len(tokens) / 2
        text = ''
        for word in sorted(row['words'], key=lambda item: item['left']):
            column = max(0, round((word['left'] - origin) / cell))
            if column < len(text):
                overlaps += 1
                column = len(text) + 1
            label = normalize_chord(word['text']) if chord_line else word['text']
            text += ' ' * (column - len(text)) + label
        row['text'] = text
    return sorted(rows, key=lambda row: row['center']), cell, overlaps


NOTE = r'(?:Do|Dó|Re|Ré|Mi|Fa|Fá|Sol|La|Lá|Si|[A-G])'
CHORD = re.compile(rf'^{NOTE}(?:[#b♯♭]|m|M|maj|dim|sus|add|[0-9()+\-º°])*(?:/{NOTE}[#b♯♭]?)?$')


def normalize_chord(text):
    if not CHORD.fullmatch(text):
        return text
    names = {'C': 'Do', 'D': 'Re', 'E': 'Mi', 'F': 'Fa', 'G': 'Sol', 'A': 'La', 'B': 'Si',
             'Dó': 'Do', 'Ré': 'Re', 'Fá': 'Fa', 'Lá': 'La'}
    text = re.sub(rf'(^|/)({NOTE})', lambda match: match[1] + names.get(match[2], match[2]), text)
    return text.replace('♯', '#').replace('♭', 'b')


def draft_html(title, rows):
    rendered = []
    chord_rows = 0
    for row in rows:
        text = row['text']
        if normalize(text) == normalize(title):
            continue
        color = '#000000'
        if row['kind'] == 'red':
            tokens = text.split()
            matched = sum(bool(CHORD.fullmatch(token)) for token in tokens)
            if tokens and matched / len(tokens) >= 0.5:
                color = '#FF0000'
                chord_rows += 1
            else:
                color = '#B71C1C'
        rendered.append(f'<FONT COLOR="{color}">{escape(text)}</FONT>')
    # Both rendering and transposition hooks match the existing app's contract.
    body = '\n'.join(rendered)
    html = f'''<HTML><HEAD><meta charset="utf-8"><style>
body{{margin:0px}} .inv{{display:none}} h1{{margin:0px}}
.html_canto{{font-size:12px;padding-left:5px;white-space:pre;font-family:monospace;}}
</style></HEAD><BODY><div class="html_canto"><H1>{escape(title)}</H1>
<div class="inv">@transp@</div>
<div class="inv">@capot@</div>
{body}
</div></BODY></HTML>'''
    return html, chord_rows


def process(record, catalog, output, write_drafts):
    result = {**record, 'reviewRequired': True, 'sheets': []}
    try:
        page = parse_page(fetch(record['page']))
        urls = sheet_urls(page)
        if not urls:
            result['error'] = 'No official sheet image found; not treated as a song'
            return result
        matches = [song for song in catalog if normalize(song['titulo']) == normalize(record['title'])]
        result['legacyMatches'] = [{'id': song['id'], 'html': song['html']} for song in matches]
        for index, url in enumerate(urls):
            key = hashlib.sha256((record['page'] + url).encode()).hexdigest()[:16]
            work = output / 'sheets' / key
            work.mkdir(parents=True, exist_ok=True)
            data = fetch(url)
            if data.startswith(b'\x89PNG\r\n\x1a\n'):
                extension = 'png'
            elif data.startswith(b'\xff\xd8\xff'):
                extension = 'jpg'
            else:
                raise ValueError('The official image response is not PNG or JPEG')
            image_path = work / f'source.{extension}'
            image_path.write_bytes(data)
            words = ocr_planes(image_path, work)
            rows, cell, overlaps = lines_from_words(words)
            html, chord_rows = draft_html(record['title'], rows)
            confidences = [word['confidence'] for word in words]
            sheet = {'url': url, 'sha256': hashlib.sha256(data).hexdigest(),
                     'image': str(image_path.relative_to(output)), 'wordCount': len(words),
                     'meanConfidence': round(statistics.mean(confidences), 2) if confidences else 0,
                     'lowConfidenceWords': sum(value < 80 for value in confidences),
                     'estimatedCellWidth': round(cell, 2), 'columnCollisions': overlaps,
                     'chordRows': chord_rows, 'extendedVariantReviewRequired': True}
            if write_drafts:
                draft_path = work / 'draft.html'
                draft_path.write_text(html, encoding='utf-8')
                sheet['draft'] = str(draft_path.relative_to(output))
            result['sheets'].append(sheet)
    except Exception as error:
        result['error'] = str(error)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', type=Path, default=Path('assets/cantos.json'))
    parser.add_argument('--output', type=Path, default=Path('portal-review'))
    parser.add_argument('--limit', type=int, default=0)
    parser.add_argument('--drafts', action='store_true', help='Write unreviewed HTML drafts outside the app assets')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    catalog = json.loads(args.catalog.read_text(encoding='utf-8'))
    records = discover()
    if args.limit > 0:
        records = records[:args.limit]
    print(f'Discovered {len(records)} source pages.', flush=True)
    results = []
    with ThreadPoolExecutor(max_workers=2) as pool:
        for result in pool.map(lambda record: process(record, catalog, args.output, args.drafts), records):
            results.append(result)
            sheets = len(result['sheets'])
            print(f"Reviewed source {len(results)}/{len(records)}: {sheets} sheet(s); error={result.get('error', 'none')}", flush=True)
    report = {'source': urljoin(ROOT, 'ressuscitou/'), 'catalogModified': False,
              'reviewRequired': True, 'pages': results}
    (args.output / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    summary = {'pages': len(results), 'sheets': sum(len(row['sheets']) for row in results),
               'errors': sum('error' in row for row in results), 'catalogModified': False}
    print('PORTAL_SUMMARY=' + json.dumps(summary), flush=True)
    if not summary['sheets']:
        raise SystemExit('No sheets retrieved; app content has not been replaced.')


if __name__ == '__main__':
    main()
