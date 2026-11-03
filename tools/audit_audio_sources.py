"""Export the audio URLs constructed by the app and compare GitHub filenames."""
import argparse
import json
from pathlib import Path
import subprocess
from urllib.parse import quote


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', default='assets/cantos.json')
    parser.add_argument('--output', default='docs/audio_sources.json')
    args = parser.parse_args()
    tree = json.loads(subprocess.check_output([
        'gh', 'api', 'repos/otaviogrrd/Ressuscitou_Android/git/trees/master?recursive=1',
    ], encoding='utf-8'))
    if tree.get('truncated'):
        raise SystemExit('GitHub returned an incomplete tree; audit aborted.')
    files = {item['path'] for item in tree['tree'] if item['type'] == 'blob'}
    songs = json.loads(Path(args.catalog).read_text(encoding='utf-8'))
    rows = []
    referenced = set()
    for song in songs:
        path = f"audios/{song.get('html', '')}.mp3"
        available = bool(song.get('url'))
        if available:
            referenced.add(path)
        rows.append({
            'id': song['id'], 'titulo': song['titulo'],
            'numero': song.get('nr_2026') or song.get('nr_2019') or song.get('numero', ''),
            'html': song.get('html', ''), 'audio_indicado_no_catalogo': available,
            'arquivo_existe_no_repositorio': path in files,
            'url_mp3': 'https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/' + quote(path, safe='/'),
        })
    report = {
        'catalogo_auditado': args.catalog,
        'repositorio_audios_commit': tree['sha'],
        'observacao': 'Auditoria de nomes de arquivos; nao testa HTTP, decodificacao ou correspondencia musical.',
        'total_cantos': len(rows),
        'audios_indicados': sum(row['audio_indicado_no_catalogo'] for row in rows),
        'indicados_sem_arquivo': [row['id'] for row in rows if row['audio_indicado_no_catalogo'] and not row['arquivo_existe_no_repositorio']],
        'arquivos_nao_referenciados': sorted(path for path in files if path.startswith('audios/') and path.lower().endswith('.mp3') and path not in referenced),
        'cantos': rows,
    }
    Path(args.output).write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: value for key, value in report.items() if key != 'cantos'}, ensure_ascii=True))


if __name__ == '__main__':
    main()
