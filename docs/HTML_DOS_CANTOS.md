# Contrato do HTML dos cantos

O HTML dos cantos é um formato de dados do WebView, não apenas uma página
visual. Não passar por formatadores, compactadores ou conversores que
alterem espaços, quebras de linha, capitalização das tags ou das cores.

- `.html_canto` mantém `font-family:monospace` e `white-space:pre`.
  Espaços e quebras de linha posicionam as cifras sobre a letra.
- `<H1>` deve permanecer nesse formato: o transpositor pula essas linhas.
- `#FF0000` identifica linhas de cifras. A capitalização é significativa
  para o transpositor atual. Não substituir as cifras por imagens ou spans
  genéricos sem migrar esse contrato e seus testes.
- `@transp@` e `@capot@` são pontos de inserção das informações salvas.
- `font-size:12px` é o ponto de ajuste do tamanho da fonte.
- `html_base64` e `ext_base64` guardam as variantes normal e estendida.
  Ambas precisam ser atualizadas e validadas.
- `id` liga o canto às listas, anotações, transposições e capotrastes salvos.
  `html` também identifica o arquivo de áudio. Não renumerar ou renomear
  esses campos ao corrigir o título ou a letra.

## Apresentação

`presentSongHtml` acrescenta CSS ao cabeçalho, sem alterar o corpo HTML.
Mantém fonte monoespaçada, espaços, alinhamento e rolagem horizontal;
desativa ligaduras e quebra automática de linhas no conteúdo dos cantos.
Os testes conferem as duas variantes de todos os cantos do catálogo, nos
dois temas, comparando o corpo original sem normalizar espaços.

As cores de categoria foram centralizadas: branco, azul, verde e amarelo,
com variantes escuras. O fundo do WebView e o do Scaffold usam a mesma
paleta. O CSS de apresentação é aplicado depois da transposição.

## Conferência com o portal em 2026-11-01

Fonte: https://cn.org.br/portal/ressuscitou/

O catálogo embarcado tem 229 registros. Nos índices do portal, 221 títulos
tiveram correspondência exata após normalizar apenas acentos e pontuação.
Foram identificadas 26 diferenças de categoria. Elas são aplicadas pelo
arquivo `assets/portal_metadata.json`, usando o campo `html` como chave
única. Letras e HTML base64 não são sobrescritos por esse arquivo.

O portal contém 250 entradas nos quatro índices, incluindo fichas,
tabelas, títulos novos e variantes de nomes. Não tratar todas como novos
cantos automaticamente. As pendências estão em `PORTAL_REVIEW.json`.

Há uma colisão anterior de ID: 227 pertence a A ESPADA e ALELUIA PASCAL II.
Ela foi documentada, sem renumeração automática que pudesse alterar dados
salvos. As atualizações de categoria usam a chave `html`, não esse ID.

## Atualização das letras e cifras

As páginas verificadas do portal disponibilizam fichas PNG. Elas não
fornecem HTML editável com os marcadores e o alinhamento usados pelo app.
Por isso, esta etapa **não declara as letras e cifras atualizadas** a partir
dessas imagens. É necessário obter um arquivo editável ou transcrever e
revisar as fichas antes de substituir o conteúdo funcional.

O HTML do repositório Ressuscitou_Android foi comparado pela chave `html`
e coincide com o embarcado. A diferença recente está em um áudio, não nas
letras. Não há ali uma versão textual mais nova para importar.

Para conferir um catálogo revisado sem reformatá-lo:

```sh
python3 tools/validate_catalog.py novo_catalogo.json --baseline assets/cantos.json
python3 -m unittest discover -s tools -p 'test_*.py'
flutter test test/song_presentation_test.dart test/portal_catalog_test.dart
```

O validador não reescreve o arquivo. Ele verifica fonte e espaços
pré-formatados, variantes, hooks de tamanho de fonte, cifras, marcadores,
IDs estáveis e colisões novas. Essa checagem estrutural não substitui a
revisão musical e textual contra a ficha oficial.
