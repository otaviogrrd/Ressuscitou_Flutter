# Fontes de catálogo e áudio

## Catálogo

- Inicial embarcado: `assets/cantos.json`.
- Cache persistido: preferência `listCantos`; tem prioridade sobre o asset quando já existe.
- Atualização remota: https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/cantos.json
- Versão remota: https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/cantos_versao.txt
- A versão local inicial usada pela comparação é 56; a versão remota observada em 2026-11-03 foi 63. Em uma instalação nova com rede, o catálogo remoto pode substituir o asset revisado. Em instalações existentes, o cache pode manter dados antigos.
- Antes da publicação, alinhar asset, fonte remota, versão e atualização do cache. Este ajuste não troca o endpoint nem publica o catálogo em revisão.

## Numeração e busca preparadas

- O novo formato usa apenas `numero` para a numeração atual, mantendo `id` estável.
- Catálogos antigos são lidos na ordem: `nr_2026`, `nr_2019`, `numero`, escolhendo o primeiro valor não vazio.
- A serialização não grava `nr_2019`, `nr_2026` nem o índice compacto `conteudo`.
- O campo `conteudo` recebido de catálogos/cache antigos é ignorado. A letra continua nos HTMLs base64, de onde a busca extrai o texto preto.
- O campo `conteudo` de mensagens é independente e continua necessário.

## MP3

- Pasta: https://github.com/otaviogrrd/Ressuscitou_Android/tree/master/audios
- Endereço construído: `https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/audios/{html}.mp3`.
- `html` é a chave do nome do arquivo. Alterá-lo pode romper download e reconhecimento de áudios já baixados.
- `url` não fornece o endereço usado no download: funciona como marcador de disponibilidade. A página de download em lote filtra especificamente `url == "X"`; as demais telas usam valor não vazio.
- Os downloads usam o diretório de documentos do app, com nome `{html}.mp3`.
- `docs/audio_sources.json` contém a lista exportada de URLs e a comparação com os nomes reais no GitHub. Não comprova que cada gravação corresponde musicalmente ao canto, nem sua integridade ou disponibilidade HTTP.
- Para refazer após revisar o catálogo: `python tools/audit_audio_sources.py` (requer GitHub CLI autenticado).

## Versões antigas

Retirar uma versão da distribuição não desinstala nem bloqueia automaticamente cópias já instaladas. O código atual não tem um bloqueio remoto obrigatório por versão. A retirada da loja e eventual desativação de fontes antigas precisam ser planejadas junto à atualização; nenhuma foi executada aqui.

## Catálogo com índice dinâmico

O leitor aceita a raiz `{edicao, categorias, cantos}`. Os nomes e a ordem do índice vêm de `categorias` da raiz; os vínculos vêm de `categorias` de cada canto. `categoria` continua sendo a etapa/cor e não é sobrescrita pelo mapa legado quando a edição é explícita. O cache preserva o objeto completo. O formato antigo em lista continua legível com conversão dos booleanos para os dez grupos definidos para a migração, sem Laudes; essa conversão não comprova as 260 associações editoriais de 2026.

O app rejeita categorias sem ID/nome/ordem válidos, IDs ou ordens repetidos, vínculos duplicados e referências inexistentes. O total de 260 associações deve ser validado pelo gerador contra o índice revisado, não como restrição permanente do leitor. A URL do gerador ainda precisa ser definida; o endpoint remoto antigo não foi trocado.

## Fonte da próxima build

- JSON: https://raw.githubusercontent.com/otaviogrrd/ressucitou_geradorjson/main/cantos.json
- Versão: https://raw.githubusercontent.com/otaviogrrd/ressucitou_geradorjson/main/cantos_versao.txt
- `cantos_versao.txt` deve conter um inteiro não negativo, incrementado a cada publicação do catálogo.
- Na primeira conexão à nova fonte, o app baixa o catálogo independentemente do número salvo da fonte antiga. Só registra a nova fonte após validar e persistir o catálogo. Sem rede ou se a atualização falhar, mantém o catálogo local disponível.
- A mudança não transfere os MP3s: os endereços de áudio permanecem no repositório Ressuscitou_Android.
- O endpoint deve estar publicado com o esquema novo antes da próxima build ser distribuída. A alteração no app não publica arquivos no gerador.
