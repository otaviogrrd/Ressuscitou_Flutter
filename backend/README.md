# Busca híbrida em português — pronta para hospedar

Este serviço combina BM25/índice invertido do SQLite FTS5, stemming Snowball
português e embeddings multilíngues MiniLM. Processa apenas o texto preto dos
HTMLs; não usa o índice compacto legado nem modifica letras/cifras. Os acentos
são preservados para o stemming (Unicode NFC), com normalização dos radicais
para comparar consultas acentuadas. Stemming não é lematização nem análise de
concordância: flexões regulares podem compartilhar radicais; verbos irregulares,
sinônimos e regionalismos não têm cobertura garantida.

A recuperação vetorial usa trechos curtos e o modelo
`sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` em CPU. Não usa uma
tabela fixa de sinônimos nem uma API de IA paga. Combina as duas listas por
Reciprocal Rank Fusion, limita sugestões e exige um limiar de similaridade
vetorial. Consultas de uma palavra usam a recuperação lexical, reduzindo ruído.
O app conserva os resultados locais primeiro e acrescenta sugestões verificadas.

## Hospedar

Na raiz do repositório, em um servidor com Docker:

```sh
docker compose -f backend/compose.yaml up --build -d
curl http://127.0.0.1:8080/healthz
curl http://127.0.0.1:8080/search -H 'Content-Type: application/json' \
  -d '{"query":"confiança no amanhã","category":0,"limit":6}'
```

O build baixa PyTorch CPU e o modelo público; pode levar vários minutos. O
modelo fica na imagem e a inicialização gera os vetores do catálogo. Reserve
inicialmente 2 CPUs, 3 GB de RAM e alguns GB de disco; dimensione medindo a
carga real. O serviço usa um worker e cache de até 256 consultas. `/healthz`
fica disponível depois de carregar modelo e índice.

O Compose expõe somente localhost. Coloque um proxy HTTPS (por exemplo, Caddy)
na frente de `127.0.0.1:8080`, com um domínio seu e limite de requisições. A API
limita consultas a 160 caracteres e no máximo oito sugestões. Não registre o
corpo das consultas no proxy. As consultas vão ao seu servidor; Hugging Face
é usado para baixar o modelo, não para inferência a cada pesquisa.

`SEMANTIC_THRESHOLD` (padrão 0.55) controla o mínimo vetorial; aumente se houver
sugestões pouco relacionadas. O modelo é genérico, não validado para todos os
cantos. Revise consultas reais antes de ampliar a distribuição. Para fixar uma
revisão dos pesos, configure `MODEL_REVISION` com o commit do modelo e use o
mesmo valor no pré-download/build; mudar modelo/revisão exige baixar os pesos.

## Ligar ao app

Depois de hospedar, use a URL HTTPS completa de `/search`:

```sh
flutter build apk --debug --dart-define=SEARCH_API_URL=https://busca.seudominio.com/search
```

No Codemagic, defina `environment.vars.SEARCH_API_URL` no `codemagic.yaml`
(há um valor vazio em cada workflow); o YAML já passa esse valor aos builds iOS. Sem URL, o app usa apenas a busca local.
Recompilar é necessário para mudar a URL. Não coloque chaves de provedores no
Flutter. O servidor precisa do mesmo catálogo da versão do app; o cliente
confere o hash dos HTMLs e se o trecho retornado realmente existe na letra.
Resultados incompatíveis, timeouts, falhas e respostas de buscas antigas são
ignorados. A busca é imediata localmente; a consulta online tem debounce e
prazo de quatro segundos.

O serviço está preparado para implantação, mas não foi hospedado nem recebeu
um domínio nesta alteração. Os APKs do CI não configuram um servidor inexistente.

## Validar

```sh
pip install -r backend/requirements-test.txt
PYTHONPATH=backend python -m unittest discover -s backend/tests -p 'test_*.py'
```

O workflow `Hybrid Portuguese search service` também carrega o modelo real,
verifica recuperação no catálogo, compara uma paráfrase portuguesa com texto
sem relação e constrói o container. Esses testes não substituem medir relevância
com consultas dos usuários. O catálogo deve ser reindexado ao atualizar o app.

Referências:

- https://snowballstem.org/algorithms/portuguese/stemmer.html
- https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2
- https://www.sbert.net/examples/sentence_transformer/applications/semantic-search/README.html
