# Ressuscitou — candidata de pontuação, 2026-11-02

Estado: **pendente de comparação visual antes/depois; não incorporada ao app**.
Lote assumido: um canto, chave `html` **RESSUSCITOU**, duas variantes.
Base consultada: `58a9c86c3c5483d00f836cfbb711a01027e2aec5`.

## Evidência e alcance

Foi aberta e lida visualmente a ficha no painel esquerdo da
[evidência publicada](https://github.com/otaviogrrd/Ressuscitou_Flutter/blob/chore/portal-visual-evidence/docs/revisao/evidencias/6cf8508c732d54f0-pair.jpg),
blob `1df06c1a8f4bc4676e002da409bf468b7bb96ef9`.
É a cópia em escala ajustada da
[ficha oficial](https://d1f12s1rtcamoi.cloudfront.net/fichas/ressuscitou.png),
não uma nova coleta do portal. O painel direito contém o rascunho OCR e não
foi usado como substituto de um print do catálogo atual.

A ficha apresenta `Alegria,` e, na linha seguinte, `alegria, irmãos,`.
O HTML existente junta essas linhas como `Alegria, alegria irmãos,`.
A vírgula antes de `irmãos` é visível na ficha, confirmando a pendência já
descrita em `amostra_legado_b.json`. A candidata acrescenta essa vírgula em
uma ocorrência de cada variante, com proteção pelo hash do base64 original.

Os dois HTMLs foram extraídos sem normalização e lidos como texto. A
estendida conserva seus três retornos completos do refrão. Essa leitura
textual não constitui nova certificação visual de cifras, sílabas ou extensão.

## Validação executada

- `python tools/review_ressuscitou_candidate.py --output /workspace/review-ressuscitou --validate-only`: passou.
- `python tools/validate_catalog.py assets/cantos.json`: passou, 229 cantos e duas variantes.
- `PYTHONPATH=backend python -m unittest discover -s backend/tests -p test_corrections.py`: passou, um teste.

O verificador da candidata usa a mesma função de aplicação do backend e confere
idempotência, hashes de origem, contrato HTML, preservação exata dos espaços e
quebras e ausência de mudanças nos outros cantos/campos. Apenas duas vírgulas
são acrescentadas na cópia derivada. O catálogo-base, as regras ativas, as
preferências e o modo estendido padrão permanecem intactos.

## Bloqueio e próxima conferência

O ambiente desta retomada estava vazio. A recuperação pelo conector GitHub
funcionou; clone e acesso HTTP falharam porque o proxy local estava inacessível.
O Chromium instalado falhou ao iniciar com `Operation not permitted`, antes
de renderizar qualquer HTML. Uma tentativa de permissão adicional ficou
bloqueada e foi interrompida pelo usuário. **Nenhuma nova captura foi obtida**.

O script abaixo gera quatro HTMLs imutáveis e quatro capturas reais, com
JavaScript desativado, requisições externas bloqueadas e `page.set_content`.
Com `--source`, também gera os pares ficha/HTML. Geração não significa aprovação.

```sh
python tools/review_ressuscitou_candidate.py \
  --output /tmp/review-ressuscitou \
  --chromium /usr/bin/chromium \
  --source /caminho/ressuscitou.png
```

É preciso inspecionar as capturas antes/depois nas duas variantes, em especial
o ponto de entrada de Sol na região de `irmãos`: a vírgula acrescenta uma
coluna de texto, enquanto os espaços das cifras foram preservados na proposta.
Qualquer ajuste horizontal exige confirmação visual/musical. Também permanecem
pendentes a comparação integral de pontuação, todas as entradas de acordes,
ordem e repetições. Este registro não aprova globalmente o canto nem aumenta
a contagem anterior de HTMLs atuais certificados.

A proposta está em `candidata_ressuscitou_pontuacao.json`, fora de
`assets/reviewed_html_corrections.json`; não deve ser ativada antes dessa conferência.
