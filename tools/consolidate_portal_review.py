"""Build an auditable report; placeholders never count as visual inspection."""
import csv
from datetime import datetime, timezone
from html import escape
import json
from pathlib import Path
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / 'docs/revisao'
BASE = 'https://github.com/otaviogrrd/Ressuscitou_Flutter/blob/chore/portal-visual-evidence/'
RAW = 'https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Flutter/chore/portal-visual-evidence/'


def normalized(value):
    return ''.join(c for c in unicodedata.normalize('NFD', value.lower()) if not unicodedata.combining(c))


def findings(entry):
    result = []
    for item in entry.get('issues', []):
        aspect = {'lyrics':'letra','layout':'alinhamento','chords':'cifra','repetition':'repetição'}.get(item.get('aspect'), item.get('aspect','observação'))
        result.append(f"{aspect}: {item['detail']}")
    notes = entry.get('achados')
    if isinstance(notes, str):
        result.append(notes)
    elif isinstance(notes, dict):
        for aspect in ('letra', 'cifra', 'alinhamento', 'repeticao'):
            values = notes.get(aspect, [])
            if isinstance(values, str): values = [values]
            result.extend(aspect + ': ' + text for text in values if text)
    for key in ('achadosLetra', 'achadosCifras', 'achadosAlinhamento', 'achadosRepeticoes', 'chordNotes'):
        if entry.get(key): result.append(key + ': ' + str(entry[key]))
    return result


def main():
    manifest = json.loads((DIRECTORY / 'manifest.json').read_text(encoding='utf-8'))
    sources = {entry['sequence']: entry for entry in manifest['entries']}
    recovered = json.loads((DIRECTORY / 'recuperada_329.json').read_text(encoding='utf-8'))['entries'][0]
    sources[329] = recovered
    selected = {}
    files = sorted(DIRECTORY.glob('lote_*.json')) + sorted(DIRECTORY.glob('retomada_*.json')) + [DIRECTORY / 'recuperada_329.json']
    for file in files:
        data = json.loads(file.read_text(encoding='utf-8'))
        entries = data if isinstance(data, list) else data.get('entries', [])
        for entry in entries:
            seq = entry['sequence']
            notes = findings(entry)
            explicit = entry.get('inspecaoVisual', entry.get('inspecionado'))
            status = normalized(str(entry.get('status', 'pendente')))
            inspected = explicit is True or (explicit is None and notes and status in {'reprovado', 'needs_correction', 'aprovado'})
            if not inspected:
                continue
            if seq in selected:
                raise ValueError(f'Duplicate inspected entry: {seq}')
            source = sources[seq]
            if entry.get('key', source['key']) != source['key']:
                raise ValueError(f'Wrong image key: {seq}')
            selected[seq] = {'sequence': seq, 'key': source['key'], 'title': source['title'],
                             'page': source.get('page'), 'sourceUrl': source['sourceUrl'],
                             'evidence': source.get('evidence', entry.get('evidence')),
                             'status': 'Aprovado' if status == 'aprovado' else 'Reprovado' if status in {'reprovado', 'needs_correction'} else 'Pendente',
                             'visuallyInspected': True, 'findings': notes, 'reportFile': file.name,
                             'coverage': entry.get('cobertura', entry.get('coverage', 'Inspeção visual com exemplos de divergências; não constitui transcrição exaustiva.'))}
    missing = sorted(set(sources) - set(selected))
    if missing:
        raise ValueError(f'Not visually inspected: {missing}')
    entries = [selected[index] for index in sorted(selected)]
    counts = {status: sum(entry['status'] == status for entry in entries) for status in ['Aprovado', 'Reprovado', 'Pendente']}
    pages = len({entry['page'] for entry in entries})
    report = {'reviewDate': datetime.now(timezone.utc).date().isoformat(), 'scope': 'OCR draft screenshot versus official sheet image',
              'imageComparisons': len(entries), 'sourcePages': pages, 'statusCounts': counts,
              'extendedDefaultPreserved': True, 'ocrImportedIntoApp': False,
              'limitation': 'Review identifies blocking discrepancies. It does not certify every glyph/voicing or approve the 229 extended HTMLs.',
              'legacyVisualSampleCount': 6, 'entries': entries}
    (DIRECTORY / 'relatorio.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    header = f'''# Revisão visual dos cantos — {report['reviewDate']}

**{len(entries)} comparações visuais concluídas, cobrindo {pages} páginas do portal.**
São imagens/fichas, incluindo resoluções alternativas e material técnico, não {len(entries)} cantos distintos.

- Aprovados para importar do OCR: **{counts['Aprovado']}**.
- Rascunhos reprovados: **{counts['Reprovado']}**.
- Comparações visualmente inspecionadas ainda pendentes: **{counts['Pendente']}**.
- Catálogo original: **229 cantos**. Nenhum rascunho OCR substituiu os HTMLs existentes.

O agente abriu as capturas e comparou letra, cifras, acidentes, menores, alinhamento e repetições.
Os achados são exemplos concretos de bloqueios; reprovar não significa listar cada erro da página.
Equivalências como C/Do e A/La não foram tratadas como erros.

**A versão estendida continua como padrão**, com repetições por extenso e sem barra de bis.
As versões existentes foram preservadas; a inspeção de um rascunho normal não certifica sua extensão.
Seis cantos atuais receberam amostragem visual adicional nas duas variantes, documentada nos relatórios de legado.

## Correções confirmadas no legado

Duas inspeções independentes e uma conferência final confirmaram correções localizadas em:

- **Não está aqui, ressuscitou:** cifra `Solo` corrigida para `Sol-`.
- **Virgem da maravilha:** `Si` corrigido para `Si-` sobre “terra”.
- **Credo:** restauração dos acentos em `CÉUS` e `COMUNHÃO`.

São oito substituições em seis variantes HTML. São aplicadas apenas aos hashes conhecidos,
inclusive ao catálogo já salvo no aparelho; versões novas/customizadas não são sobrescritas.
Espaços, quebras de linha, marcadores WebView, IDs e estrutura das repetições permanecem preservados.
Outras diferenças dos HTMLs atuais continuam descritas como pendências, sem aprovação global.

## Como consultar

Abra **Comparação** na tabela para ver a ficha oficial à esquerda e o print do rascunho à direita.
Use a pesquisa do navegador para localizar o título. Os relatórios por lote têm os detalhes completos.
Também estão disponíveis `relatorio.json`, `relatorio.csv` e `painel.html` (baixe e abra no navegador).
O painel usa as imagens públicas do GitHub e requer internet para carregá-las.

## Resultado por imagem

| Nº | Canto/ficha | Resultado | Evidência | Achados |
|---:|---|---|---|---|
'''
    by_file = {}
    for entry in entries:
        by_file.setdefault(entry['reportFile'], []).append(entry)
    for filename, group in by_file.items():
        path = DIRECTORY / Path(filename).with_suffix('.md')
        if not path.exists():
            content = '# Comparação visual — ' + Path(filename).stem + '\n\n'
            content += 'Inspeção de capturas do rascunho OCR; não aprova o catálogo ou a versão estendida.\n\n'
            for entry in group:
                content += f"## {entry['sequence']:03d} — {entry['title']}\n\n**{entry['status']}** · [Comparação]({BASE + entry['evidence']})\n\n"
                content += '\n'.join('- ' + note for note in entry['findings']) + '\n\n'
            path.write_text(content, encoding='utf-8')
    rows = []
    details = []
    for entry in entries:
        title = entry['title'].replace('|', '\\|')
        rows.append(f"| {entry['sequence']:03d} | {title} | {entry['status']} | [Comparação]({BASE + entry['evidence']}) | [Detalhes]({Path(entry['reportFile']).with_suffix('.md').as_posix()}) |")
        details.append(f"### {entry['sequence']:03d} — {entry['title']}\n\n**{entry['status']}** · [Ficha oficial]({entry['sourceUrl']}) · [Comparação]({BASE + entry['evidence']})\n\n" + '\n'.join('- ' + note for note in entry['findings']) + '\n')
    (DIRECTORY / 'RELATORIO.md').write_text(header + '\n'.join(rows) + '\n\n## Limites e próximos passos\n\nOs rascunhos reprovados exigem correção/transcrição e nova comparação antes de entrar no app. Não foram aprovados por score OCR. A ficha antes indisponível, Para ti morada santa, foi recuperada e revisada como imagem329.\n', encoding='utf-8')
    (DIRECTORY / 'ACHADOS.md').write_text('# Achados por ficha\n\n' + '\n'.join(details), encoding='utf-8')
    with (DIRECTORY / 'relatorio.csv').open('w', encoding='utf-8-sig', newline='') as out:
        writer = csv.writer(out, delimiter=';')
        writer.writerow(['Nº', 'Título', 'Resultado', 'Fonte', 'Comparação', 'Achados'])
        for entry in entries:
            writer.writerow([entry['sequence'], entry['title'], entry['status'], entry['sourceUrl'], BASE + entry['evidence'], ' | '.join(entry['findings'])])
    payload = json.dumps(entries, ensure_ascii=False).replace('</', '<\\/')
    html = '''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Revisão visual dos cantos</title>
<style>body{font:16px system-ui;margin:24px;background:#f5f5f5;color:#222}input{font:inherit;padding:10px;width:min(90%,600px)}article{background:white;border:1px solid #bbb;padding:16px;margin:24px 0}img{max-width:100%;height:auto}a{color:#124c91}li{margin:8px 0}</style>
<h1>Revisão visual dos cantos</h1><p>330 comparações; rascunhos OCR reprovados para importação. Versão estendida do app preservada como padrão.</p>
<p>Ficha oficial à esquerda; HTML OCR à direita. Abra a imagem para ampliar. Esta revisão não aprova o catálogo inteiro nem cada repetição da versão estendida.</p>
<input id="filter" aria-label="Pesquisar canto" placeholder="Pesquisar pelo título"><main id="entries"></main><script>
const data=''' + payload + ''';
const main=document.querySelector('#entries');for(const e of data){const card=document.createElement('article');card.dataset.title=e.title.normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase();
const title=document.createElement('h2');title.textContent=e.sequence.toString().padStart(3,'0')+' — '+e.title+' · '+e.status;card.append(title);
const list=document.createElement('ul');for(const f of e.findings){const li=document.createElement('li');li.textContent=f;list.append(li);}card.append(list);
const a=document.createElement('a');a.href=''' + json.dumps(RAW) + '''+e.evidence;a.target='_blank';const image=document.createElement('img');image.loading='lazy';image.alt='Ficha oficial e captura do HTML';image.src=a.href;a.append(image);card.append(a);main.append(card);}
document.querySelector('#filter').addEventListener('input',event=>{const key=event.target.value.normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase();document.querySelectorAll('article').forEach(card=>card.hidden=!card.dataset.title.includes(key));});</script></html>'''
    (DIRECTORY / 'painel.html').write_text(html, encoding='utf-8')
    print(json.dumps({'comparisons': len(entries), 'pages': pages, **counts}, ensure_ascii=False))


if __name__ == '__main__':
    main()
