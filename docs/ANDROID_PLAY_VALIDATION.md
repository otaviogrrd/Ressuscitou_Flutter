# Validação Android para testes internos

Build candidato: `3.2.0`, versionCode `4029`. Não é uma autorização de produção.
A revisão editorial de `assets/cantos.json` continua em paralelo.

## Requisitos e evidências

- `compileSdk` e `targetSdk`: 36, definidos explicitamente no Gradle.
- AndroidX Activity: 1.13.0; Fragment: 1.9.1. Conferir as versões resolvidas no relatório de dependências do workflow.
- O layout usa a área segura inferior e lateral; AppBar continua responsável pelo recuo superior.
- O workflow verifica os segmentos ELF de todas as bibliotecas nativas de 64 bits do AAB para alinhamento de 16 KB. A aceitação e os APKs gerados pela Play ainda precisam ser validados.
- O APK da migração exige Android API 24; aparelhos abaixo dessa versão não recebem a atualização.
- Os avisos da versão antiga em produção podem continuar visíveis durante o teste interno. Não declarar a política de produção resolvida apenas por enviar um teste.

## Falhas históricas ainda sem correção comprovada

- ANR `MessageQueue.nativePollOnce`, APK 2028 (3.1.0): ocorrência informada sem stack trace, em Android 12, 16 e 17. Causa não identificada.
- SIGABRT em `libhwui`, `GlesErrorCheckWrapper::assertNoErrors` → `Caches::flush` → `Bridge_destroyHardwareResources`: falha na liberação de recursos gráficos nativos. A pilha fornecida não identifica código Dart nem comprova relação com o catálogo. Obter modelo, versão Android e log anterior ao abort para aprofundar.
- Não desativar aceleração gráfica ou trocar o renderizador globalmente sem evidência e reprodução.

## Teste antes de produção

1. Confirmar a assinatura de upload e o target SDK no AAB aceito pela Play.
2. Instalar pela faixa interna sobre a versão publicada, preservando listas, preferências e áudios baixados.
3. Em Android 15, 16 e 17, testar gestos e navegação por três botões: início, busca, menu, cantos, transposição, capotraste, listas, áudios e player; verificar recuos em retrato/paisagem e temas claro/escuro.
4. Abrir e fechar cantos repetidamente, alternar entre segundo e primeiro plano, bloquear/desbloquear e testar reprodução durante essas transições.
5. Conferir relatório de pré-lançamento, avisos de SDK e de APIs de ponta a ponta na Play. Avisos vindos do engine/plugins exigem identificação pelo relatório do novo AAB.
6. Comparar falhas e ANRs do novo versionCode; teste interno sem ocorrências não prova eliminação de falhas raras.
7. Finalizar revisão dos cantos e gerar outro versionCode para o candidato de produção, mediante instrução do responsável.
