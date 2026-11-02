# Codemagic e testes no iOS

O arquivo `codemagic.yaml` na raiz usa Flutter 3.47.7, como o CI do GitHub.
Os workflows são manuais; conectar o repositório não publica o app.

## Novo aplicativo na nova conta Apple

Esta publicação é separada do aplicativo anterior “Ressuscitou BR”.
- Nome no aparelho: **Ressuscitou**.
- Bundle ID: **`br.com.otaviogrrd.ressuscitou`**, novo e diferente do anterior.
- A equipe Apple antiga foi removida do projeto; a assinatura será aplicada pelos perfis da nova conta.
- Na nova conta Apple Developer, registre um App ID explícito com esse Bundle ID.
- No App Store Connect da mesma conta, crie um novo app com esse Bundle ID e nome “Ressuscitou”, sujeito à disponibilidade na loja.
- Configure no Codemagic o certificado Apple Distribution e o perfil App Store dessa nova conta.

Os usuários do aplicativo anterior não recebem esta publicação separada como atualização automática.
O nome cadastrado na App Store é uma configuração do App Store Connect, independente do nome exibido no aparelho.

## Conectar e compilar

1. No Codemagic, adicione o repositório GitHub `otaviogrrd/Ressuscitou_Flutter`.
2. Selecione a branch `chore/dart-3-migration`, onde estão estas alterações.
3. Selecione a configuração YAML e procure `codemagic.yaml` nessa branch.
4. Execute `ios-simulator` para analisar, rodar os testes e compilar sem assinatura.
   O artefato `ressuscitou-simulator.zip` contém o aplicativo para simulador;
   ele não instala em um iPhone físico. Os testes Flutter rodam no host macOS,
   e a compilação para simulador é uma verificação separada.
5. Para gerar o IPA para TestFlight, cadastre no Codemagic o certificado Apple
   Distribution com sua chave privada e um perfil App Store para
   `br.com.otaviogrrd.ressuscitou`. Eles precisam pertencer à mesma equipe Apple Developer.
   Use a área de assinatura do Codemagic; não adicione chaves ao Git.
6. Execute `ios-ipa`. `xcode-project use-profiles` aplica o perfil cadastrado;
   o número da compilação usa `BUILD_NUMBER` do Codemagic. Se já existe uma
   compilação com número maior no App Store Connect, ajuste a sequência do
   Codemagic antes do primeiro envio.
7. Baixe o IPA e envie pelo Transporter/App Store Connect para disponibilizar
   no TestFlight. O workflow não faz upload nem publicação automaticamente.
   Um IPA App Store não pode ser instalado diretamente no iPhone.

Para distribuição direta a aparelhos registrados, altere a distribuição para
`ad_hoc` e cadastre um perfil Ad Hoc com os UDIDs dos aparelhos. O certificado
precisa corresponder ao perfil. Essa alternativa não usa TestFlight.

## Validar o crash da busca

A implementação antiga fazia substituições manuais incompletas de acentos.
A busca atual usa normalização compartilhada em Dart, sem chamada nativa para
comparar texto. Além dos acentos compostos, remove marcas combinantes Unicode
(como `a` seguido de til) antes de pesquisar. Os testes cobrem as duas formas,
maiúsculas, digitação e exclusão gradual, pontuação e trechos com acentos.
Esses testes rodam tanto no Linux quanto no macOS no GitHub Actions.

Isso ainda não comprova a causa nem a correção do crash original no aparelho.
No simulador/iPhone, testar:

- Digitar e apagar `coração`, `canção`, `manhã`, `É o Senhor` e `glória`.
- Repetir sem acentos e conferir os mesmos resultados.
- Usar o teclado português, texto colado, sugestões e correção do teclado.
- Alternar categorias e abrir os resultados; repetir ao selecionar cantos
  para uma lista e conferir os trechos abaixo dos títulos.
- Testar tema claro/escuro e voltar à busca depois de abrir um canto.

Se houver crash, registrar modelo, versão do iOS, texto digitado e log de
crash do Xcode/TestFlight. Um build bem-sucedido não substitui esse teste.

Referências:

- https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/
- https://docs.codemagic.io/yaml-code-signing/signing-ios/
