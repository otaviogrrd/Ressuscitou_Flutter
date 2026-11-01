# Migração do Ressuscitou para Dart 3

## Estado da entrega

O código foi migrado para null safety e APIs atuais, com alvo Flutter 3.47.7
fixado em `.fvmrc` e no workflow. O projeto aceita Dart >=3.13.0 <4.0.0.
O Dart estável consultado foi 3.13.7; em um app Flutter deve-se usar o Dart
distribuído junto com o Flutter, sem trocar o SDK Dart interno manualmente.

**A migração ainda precisa passar por pub get, análise, testes, builds e
validação em aparelho. Não há APK validado nesta entrega.** O ambiente de
edição não dispõe de Flutter/Dart e o proxy para baixar o SDK está
indisponível. O workflow do GitHub Actions deve validar a branch antes
da integração na master.

## O que mudou

- Modelos, páginas e menu local migrados para null safety. Construtores e
  leitura de JSON tratam campos ausentes de backups antigos.
- Preferências e informações do pacote carregadas antes de abrir o app.
  A API SharedPreferences foi mantida para preservar o armazenamento usado
  pela versão anterior; as chaves não foram renomeadas.
- Bibliotecas atualizadas para versões estáveis consultadas no pub.dev.
  package_info, wakelock e share foram substituídos por package_info_plus,
  wakelock_plus e share_plus.
- FormBuilder foi substituído pelos formulários nativos do Flutter.
  O índice litúrgico usa ExpansionTile, retirando a árvore de terceiros.
  FlatButton foi substituído por TextButton com as cores existentes.
  Temas usam ColorScheme e InputDecorationThemeData atuais.
- O WebView antigo incluído no repositório foi removido e substituído por
  webview_flutter 4.14.1. A página usa WebViewController/WebViewWidget,
  carregamento de HTML, zoom e JavaScript para verificar a rolagem.
  A rolagem automática tem um único timer, cancelado ao sair da página.
- O menu flutter_speed_dial personalizado foi mantido e migrado, incluindo
  a opção de continuar aberto após selecionar uma ação.
- Áudio usa audioplayers 6.8.1, DeviceFileSource/UrlSource e eventos atuais.
  As assinaturas dos eventos são liberadas ao sair. A playlist trata lista
  vazia e o fim da última faixa, com aleatório e repetição.
- http usa Uri. connectivity_plus trata a lista de conexões atual.
  Downloads verificam o conteúdo recebido, aguardam a gravação e não
  marcam falhas como downloads concluídos.
- Exportação de dados usa o diálogo do sistema por FilePicker em vez de
  escrever diretamente no caminho público de Downloads. Importação
  preserva o formato JSON e aguarda a gravação das listas e preferências.
- Android usa plugins declarativos do Gradle, namespace explícito,
  Java 17, AGP 9.1.0, Kotlin 2.4.0 e Gradle 9.3.1, conforme o template
  stable consultado. As flags de compatibilidade de DSL/Kotlin estão no
  gradle.properties. A assinatura release continua exigindo a chave
  original e android/key.properties.
- iOS tem deployment target 13.0 no Podfile, Xcode e AppFrameworkInfo.plist.
  O Podfile.lock antigo foi removido para resolver os plugins atualizados.
- O override antigo de intl foi removido; flutter_localizations determina
  a versão. Dependências sem uso foram retiradas do pubspec.
- Testes cobrem o formato de backup, a serialização dos cantos, a
  preservação de listas e preferências, a leitura de cantos locais e
  o comportamento do menu personalizado.

## Busca dos cantos

A busca usa fuzzywuzzy 1.2.0 e diacritic 0.1.6. Números exatos têm
prioridade sobre números parciais, com suporte a zeros à esquerda e à
numeração antiga. Números não recebem comparação aproximada.

Para texto, a ordem é título exato, trecho do título, trecho do índice de
conteúdo e, por último, títulos semelhantes. A normalização ignora acentos,
maiúsculas, espaços repetidos e pontuação, sem alterar o texto salvo. O
índice compacto legado do campo conteudo continua pesquisável.

A aproximação compara títulos com weightedRatio, limite inicial de 80/100,
somente a partir de quatro caracteres. O filtro de categoria continua
valendo e os empates mantêm a ordem original do catálogo. Os textos são
normalizados uma vez por carga; digitar não recarrega o catálogo do disco.

O teste canto_search_test.dart cobre a prioridade dos resultados,
acentuação, erros de digitação, números, categorias e preservação dos
objetos originais. O limite de similaridade deve ser avaliado com buscas
reais depois da validação do app.

## Aplicar e validar

O patch é contra o commit
`377a174c22ee63b6d134039d5c266bac72d820d6` da master.
Use uma cópia limpa do repositório e aplique **somente este patch**, sem
aplicar primeiro o pacote de preparação entregue anteriormente.

```sh
git switch -c chore/dart-3-migration
git apply --check /caminho/ressuscitou-dart3.patch
git apply /caminho/ressuscitou-dart3.patch
git diff --check
```

Com Flutter 3.47.7 instalado (ou selecionado via FVM):

```sh
flutter --version
dart --version
flutter pub get
dart format lib test plugins/flutter_speed_dial/lib
flutter analyze --no-fatal-infos lib test
flutter test
flutter build apk --debug
```

Também executar pub get e analyze dentro de plugins/flutter_speed_dial.
No macOS, executar `flutter build ios --debug --no-codesign`.
Versionar pubspec.lock e ios/Podfile.lock depois de resolver e validar as
dependências. Não foi criado um lockfile artificial nesta entrega.

O workflow **Flutter stable compatibility** executa resolução, análise,
testes e build Android, além de build iOS sem assinatura. Guarda logs,
lockfiles e, se o build passar, o APK debug. As falhas não são ignoradas.
Ele pode ser iniciado manualmente na branch pelo GitHub Actions.

## Antes de publicar

Validar instalação sobre a versão anterior, cantos offline, transposição,
capotraste, notas, listas, importação/exportação, downloads, reprodução,
aleatório, repetição, zoom, rolagem, temas e modo tablet.

O suporte mínimo passa a Android 7 / API 24 e iOS 13. Testar em aparelhos
reais, especialmente pinch zoom e HTML no WebView, os diálogos de arquivos
e compartilhamento no iPad. A UI do player e das notificações internas
foi adaptada às APIs mantidas e precisa de revisão visual.

Após os checks, revisar exigências atuais das lojas, incrementar a versão
do app e validar os builds de produção usando a assinatura original.

## Referências verificadas

- https://github.com/dart-lang/sdk/blob/stable/tools/VERSION
- https://github.com/flutter/flutter/tree/3.47.7
- https://github.com/flutter/flutter/blob/stable/packages/flutter_tools/lib/src/android/gradle_utils.dart
- https://pub.dev/packages/webview_flutter
- https://pub.dev/packages/audioplayers
- https://pub.dev/packages/share_plus
- https://pub.dev/packages/package_info_plus
- https://pub.dev/packages/connectivity_plus
- https://pub.dev/packages/file_picker

- https://pub.dev/packages/fuzzywuzzy
- https://pub.dev/packages/diacritic
