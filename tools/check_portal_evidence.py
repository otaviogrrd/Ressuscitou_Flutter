"""Avoid regenerating an already published, unchanged visual review corpus."""
import base64
import json
import os
from pathlib import Path
import subprocess
from urllib.error import HTTPError
from urllib.request import Request, urlopen

repo = os.environ['GITHUB_REPOSITORY']
token = os.environ['GITHUB_TOKEN']


def get(path):
    request = Request('https://api.github.com/repos/' + repo + path,
                      headers={'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json'})
    with urlopen(request, timeout=30) as response:
        return json.load(response)


skip = False
try:
    data = get('/contents/docs/revisao/manifest.json?ref=chore%2Fportal-visual-evidence')
    manifest = json.loads(base64.b64decode(data['content']))
    if manifest.get('entries') and all(entry.get('published') for entry in manifest['entries']):
        prior = get('/contents/tools/render_portal_review.py?ref=' + manifest['sourceSha'])['sha']
        current = subprocess.check_output(['git', 'hash-object', 'tools/render_portal_review.py'], text=True).strip()
        skip = prior == current
except HTTPError as error:
    if error.code != 404:
        raise
if os.getenv('FORCE_RENDER', 'false').lower() == 'true' or os.getenv('SOURCE_RUN_ID', '41359420187') != '41359420187':
    skip = False
with Path(os.environ['GITHUB_OUTPUT']).open('a') as output:
    output.write('skip=' + ('true' if skip else 'false') + '\n')
print('Existing visual evidence is unchanged; preserved.' if skip else 'Visual evidence needs rendering.')
