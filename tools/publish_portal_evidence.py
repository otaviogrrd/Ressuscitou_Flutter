"""Publish bounded JPEG review evidence on an isolated branch, never master."""
import argparse
import base64
import json
import os
from pathlib import Path
import re
import time
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from PIL import Image

BRANCH = 'chore/portal-visual-evidence'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--review', type=Path, default=Path('portal-review/visual-review'))
    parser.add_argument('--batch', type=int, default=12)
    args = parser.parse_args()
    repository = os.environ['GITHUB_REPOSITORY']
    token = os.environ['GITHUB_TOKEN']
    source_sha = os.environ['SOURCE_SHA']
    if not re.fullmatch(r'[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+', repository) or not re.fullmatch(r'[a-f0-9]{40}', source_sha):
        raise ValueError('Unexpected repository or source SHA')
    endpoint = 'https://api.github.com/repos/' + repository
    previous_write = 0.0

    def api(path, payload=None, method=None):
        nonlocal previous_write
        if payload is not None:
            # Keep content writes below GitHub's secondary per-minute limit.
            delay = 1.05 - (time.monotonic() - previous_write)
            if delay > 0:
                time.sleep(delay)
            previous_write = time.monotonic()
        request = Request(endpoint + path,
                          data=json.dumps(payload).encode() if payload is not None else None,
                          method=method,
                          headers={'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json',
                                   'Content-Type': 'application/json', 'User-Agent': 'RessuscitouVisualReview'})
        with urlopen(request, timeout=45) as response:
            return json.load(response)

    try:
        parent = api('/git/ref/heads/' + BRANCH)['object']['sha']
        exists = True
    except HTTPError as error:
        if error.code != 404:
            raise
        parent = source_sha
        exists = False
    tree = api('/git/commits/' + parent)['tree']['sha']
    manifest = json.loads((args.review / 'manifest.json').read_text(encoding='utf-8'))
    manifest['sourceSha'] = source_sha
    manifest['sourceRun'] = os.environ.get('GITHUB_RUN_ID')
    manifest['evidenceBranch'] = BRANCH
    pending = []
    for index, item in enumerate(manifest['entries']):
        item['sequence'] = index
        item['published'] = False
        name = item.get('pair')
        if not name or Path(name).name != name or not (args.review / name).is_file():
            continue
        item['evidence'] = 'docs/revisao/evidencias/' + item['key'] + '-pair.jpg'
        pending.append(item)
    for offset in range(0, len(pending), args.batch):
        elements = []
        for item in pending[offset:offset + args.batch]:
            image_path = args.review / item['pair']
            jpeg_path = image_path.with_suffix('.jpg')
            with Image.open(image_path) as image:
                image.convert('RGB').save(jpeg_path, quality=92, optimize=True)
            blob = api('/git/blobs', {'content': base64.b64encode(jpeg_path.read_bytes()).decode(), 'encoding': 'base64'})
            elements.append({'path': item['evidence'], 'mode': '100644', 'type': 'blob', 'sha': blob['sha']})
            item['published'] = True
        data = json.dumps(manifest, ensure_ascii=False, indent=2).encode()
        blob = api('/git/blobs', {'content': base64.b64encode(data).decode(), 'encoding': 'base64'})
        elements.append({'path': 'docs/revisao/manifest.json', 'mode': '100644', 'type': 'blob', 'sha': blob['sha']})
        new_tree = api('/git/trees', {'base_tree': tree, 'tree': elements})['sha']
        commit = api('/git/commits', {'message': f'Review evidence: {min(offset + args.batch, len(pending))}/{len(pending)} sheets',
                                      'tree': new_tree, 'parents': [parent]})['sha']
        if exists:
            api('/git/refs/heads/' + BRANCH, {'sha': commit, 'force': False}, 'PATCH')
        else:
            api('/git/refs', {'ref': 'refs/heads/' + BRANCH, 'sha': commit})
            exists = True
        parent, tree = commit, new_tree
        print('EVIDENCE_BATCH=' + json.dumps({'published': min(offset + args.batch, len(pending)),
                                             'total': len(pending), 'branch': BRANCH}), flush=True)


if __name__ == '__main__':
    main()
