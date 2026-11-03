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
