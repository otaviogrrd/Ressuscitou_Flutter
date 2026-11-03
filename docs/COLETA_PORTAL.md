# Obter as fichas pela URL

O workflow **Official portal source review** percorre os quatro índices do
portal, abre as páginas encontradas e baixa apenas imagens PNG observadas
nas páginas, hospedadas no diretório oficial `/fichas/`. Não adivinha nomes
de arquivos nem acessa áreas autenticadas.

Fonte inicial: https://cn.org.br/portal/ressuscitou/

O processo separa os pixels vermelhos das cifras e os pixels escuros da
letra e executa Tesseract com português e inglês em cada camada. As
posições horizontais são projetadas numa grade monoespaçada comum. Os
rascunhos mantêm o contrato do WebView: `.html_canto`, `white-space:pre`,
fonte monoespaçada, `<H1>`, linhas de cifras em `#FF0000`, `@transp@`,
`@capot@` e o hook `font-size:12px`.

O artefato `official-portal-review` contém:

- Imagens originais e camadas separadas por cor.
- `draft.html` de cada ficha, com espaços e posições estimados pelo OCR.
- `report.json` com URLs, hashes, correspondências por título, confiança,
  colisões de colunas e quantidade de linhas de cifras reconhecidas.

**São rascunhos para conferência, não conteúdo publicado.** OCR pode trocar
acentos, notas, acidentes e números. A imagem pode usar fonte proporcional,
ter várias colunas ou instruções que precisem de tratamento específico.
O relatório aponta incertezas, mas não comprova correção musical.

As duas variantes do catálogo existente permanecem intactas. A variante
estendida exige revisão específica de estrofes e repetições; não é criada
silenciosamente como cópia da versão normal. IDs, nomes de arquivos de
áudio, anotações e listas também não são alterados pela coleta.

Para executar localmente, instalar Pillow, Tesseract e os idiomas português
e inglês, e usar:

```sh
python3 -m unittest discover -s tools -p 'test_*.py'
python3 tools/portal_sources.py --drafts --output portal-review
```

É possível usar `--limit 3` para um ensaio pequeno. Sem `--drafts`, o
processo guarda as imagens e o relatório, sem escrever HTML transcrito.

Depois da conferência, as alterações de texto devem ser incorporadas às
variantes normal e estendida do canto correto, preservando sua chave
`html` e seu ID. O validador do catálogo e os testes do app devem passar
antes da publicação.
