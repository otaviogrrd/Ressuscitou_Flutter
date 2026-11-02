"""Capture before/after reviewed HTML variants without changing the base catalog."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageDraw
from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'backend'))
from search_service.corrections import apply_corrections


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=Path('docs/revisao/correcoes'))
    parser.add_argument('--chromium', default='/usr/bin/chromium')
    args = parser.parse_args()
    source = json.loads(args.catalog.read_text(encoding='utf-8'))
    songs = json.loads(args.catalog.read_text(encoding='utf-8'))
    rules = json.loads(Path('assets/reviewed_html_corrections.json').read_text(encoding='utf-8'))['songs']
    apply_corrections(songs, rules)
    args.output.mkdir(parents=True, exist_ok=True)
    evidence = []
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=args.chromium)
        context = browser.new_context(viewport={'width': 1100, 'height': 900}, device_scale_factor=2, java_script_enabled=False)
        context.route('**/*', lambda route: route.abort())
        page = context.new_page()
        for old, updated in zip(source, songs):
            if old['html'] not in rules: continue
            for field, label in [('html_base64', 'normal'), ('ext_base64', 'extended')]:
                if old[field] == updated[field]: continue
                token = hashlib.sha256(old['html'].encode()).hexdigest()[:12] + '-' + label
                paths = []
                for which, value in [('before', old[field]), ('after', updated[field])]:
                    path = args.output / f'{token}-{which}.png'
                    page.set_content(base64.b64decode(value).decode('utf-8'), wait_until='load')
                    page.screenshot(path=str(path), full_page=True)
                    paths.append(path)
                with Image.open(paths[0]) as a, Image.open(paths[1]) as b:
                    before, after = a.convert('RGB'), b.convert('RGB')
                    assert before.size == after.size, 'Unexpected screenshot dimensions change'
                    box = ImageChops.difference(before, after).getbbox()
                    assert box, 'Reviewed replacement has no visible effect'
                    # Keep evidence focused on the changed region; source full
                    # screenshots remain available for checking repetitions.
                    x1,y1,x2,y2 = box
                    crop = (max(0,x1-180),max(0,y1-70),min(before.width,x2+180),min(before.height,y2+70))
                    left,right=before.crop(crop),after.crop(crop)
                    canvas=Image.new('RGB',(left.width*2+16,left.height+36),'white')
                    draw=ImageDraw.Draw(canvas);draw.text((8,8),'ANTES',fill='black');draw.text((left.width+16,8),'DEPOIS',fill='black')
                    canvas.paste(left,(0,32));canvas.paste(right,(left.width+16,32))
                    pair=args.output/f'{token}-pair.jpg';canvas.save(pair,quality=94,optimize=True)
                evidence.append({'html':old['html'],'variant':label,'pair':str(pair),'before':str(paths[0]),'after':str(paths[1]),'diffBox':box,
                                 'sourceHash':hashlib.sha256(old[field].encode()).hexdigest(),
                                 'correctedHash':hashlib.sha256(updated[field].encode()).hexdigest()})
        browser.close()
    Path('docs/revisao/correcoes_aplicadas.json').write_text(json.dumps({'catalogOriginalUnchanged':True,'mode':'hash-guarded runtime overlay, normal and extended','evidence':evidence},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Captured corrected variants:',len(evidence))


if __name__ == '__main__':
    main()
