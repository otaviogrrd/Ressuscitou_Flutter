# Revisão dos cantos

**[Abrir o relatório completo](RELATORIO.md)** · [Todos os achados](ACHADOS.md) · [Planilha CSV](relatorio.csv)

A revisão compara a imagem oficial com o print do HTML renderizado. Foram
inspecionadas 330 imagens de 250 páginas; inclui fichas em resoluções alternativas
e material técnico. Os 330 rascunhos OCR foram reprovados para importação.
Os relatórios registram exemplos concretos, não uma transcrição corrigida integral.

O modo estendido permanece ativado por padrão, com as repetições escritas por
extenso, sem substituir a versão existente por um rascunho compactado do portal.
A inspeção de seis cantos atuais nas duas variantes está nos arquivos
`amostra_legado_b.*` e `amostra_legado_c.*`; isso não certifica todos os 229 HTMLs.

Após duas conferências independentes, foram confirmadas e implementadas correções
pontuais nos dois HTMLs de Não está aqui, ressuscitou; Virgem da maravilha; e Credo.
As capturas [antes/depois](correcoes_aplicadas.json) documentam as mudanças.
A aplicação é protegida pelo hash do original e também funciona para o catálogo
antigo salvo no aparelho. Não regrava o catálogo-base nem as preferências do usuário.

## Painel e pacote para baixar

- Baixe [revisao-cantos.zip](revisao-cantos.zip), extraia e abra `painel.html` no navegador.
- O painel permite filtrar por título e ampliar cada par; usa internet para carregar
  as imagens públicas da branch `chore/portal-visual-evidence`.
- O ZIP contém os relatórios e os recortes antes/depois, não todas as imagens oficiais.
- As [evidências completas da captura original](https://github.com/otaviogrrd/Ressuscitou_Flutter/actions/runs/41376623162/artifacts/13111529667)
  incluem fichas, rascunhos, prints e HTMLs legados. O artefato é temporário; o relatório
  e os pares publicados na branch de evidências permanecem no repositório.

`manifest.json` identifica as capturas e seus estados após inspeção.
`relatorio.json` reúne os resultados normalizados; os arquivos `lote_*`,
`retomada_*` e `recuperada_329.*` guardam os registros por lote.
As capturas usam Chromium, não um print de um aparelho físico.

Nenhum rascunho reprovado foi promovido ao app. Para atualizar o restante do conteúdo,
é necessário corrigir/transcrever os pontos registrados e repetir a comparação,
validando a versão estendida e a posição das cifras antes de publicar.
