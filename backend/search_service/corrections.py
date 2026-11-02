"""Use the same hash-guarded, reviewed HTML fragments as the mobile client."""
import base64
import hashlib


def apply_corrections(songs, rules):
    for song in songs:
        corrections = rules.get(song.get('html'), {})
        for field in ('html_base64', 'ext_base64'):
            rule = corrections.get(field)
            encoded = song.get(field, '')
            if not rule or hashlib.sha256(encoded.encode()).hexdigest() != rule['sourceSha256']:
                continue
            try:
                text = base64.b64decode(encoded, validate=True).decode('utf-8')
                for patch in rule['patches']:
                    if not patch['old'] or text.count(patch['old']) != 1:
                        break
                    text = text.replace(patch['old'], patch['new'], 1)
                else:
                    song[field] = base64.b64encode(text.encode('utf-8')).decode()
            except (ValueError, UnicodeError):
                continue
