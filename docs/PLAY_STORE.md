# Atualizar o app existente na Google Play

O pacote continua sendo `br.org.cn.ressuscitou`. Usar AAB não cria outro app: a Play gera os APKs adequados aos aparelhos.

## Antes do primeiro envio

1. Na Play Console, conferir o maior versionCode de todos os APKs e bundles já enviados, inclusive testes e variantes por arquitetura. O número fornecido ao workflow deve ser maior que todos eles. Não usar automaticamente 29 nem a contagem do GitHub.
2. Em Integridade do app / Assinatura de apps, conferir se o Google Play App Signing está ativo. Se não estiver, seguir a adesão apresentada pela Play Console antes de migrar para AAB.
3. Conferir o certificado de upload registrado na Play Console. O keystore usado pelo workflow precisa corresponder a esse certificado (ou à chave original, conforme o processo de adesão). Não criar uma chave substituta sem regularizar a troca na Play Console.
4. Manter uma cópia segura da chave e senhas.

## GitHub Actions secrets

Em Settings → Secrets and variables → Actions → New repository secret, cadastrar:

- `ANDROID_KEYSTORE_BASE64`: conteúdo do keystore convertido em base64.
- `ANDROID_KEY_ALIAS`: alias da chave.
- `ANDROID_KEY_PASSWORD`: senha da chave.
- `ANDROID_STORE_PASSWORD`: senha do keystore.

Converter localmente, sem enviar a chave ou as senhas em chats ou commits:

Linux: `base64 -w 0 upload.jks > upload-base64.txt`

macOS: `base64 -i upload.jks -o upload-base64.txt`

PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload.jks")) | Set-Content upload-base64.txt`

Copiar o conteúdo do arquivo para o secret e depois remover o arquivo temporário. Base64 não protege o conteúdo.

## Gerar e validar

O workflow é `.github/workflows/android-play-bundle.yml`, **Android App Bundle for Play Store**. É manual, não publica na loja e não usa assinatura de debug.

O GitHub só habilita workflow_dispatch quando o arquivo existe na branch padrão. Enquanto estiver apenas na branch de migração, ele pode não aparecer em Actions. Após integrar o workflow à branch padrão, usar Run workflow, selecionar a branch desejada e preencher `build_number`.

O workflow analisa, testa, restaura temporariamente a chave, gera o AAB assinado, verifica a assinatura e salva apenas o AAB como artefato. Remove os arquivos de assinatura ao terminar. A variável opcional `SEARCH_API_URL` pode ser cadastrada em Actions variables para ativar o serviço de busca.

Baixar o artefato e enviar `app-release.aab` primeiro para **Testes internos** na Play Console. Validar a instalação e atualização sobre a versão publicada, áudios, busca e WebView. A aceitação pela Play também verifica requisitos atuais, incluindo target API e bibliotecas nativas de 16 KB; a compilação local por si só não comprova aprovação.

Depois da validação, preparar a versão de produção na Play Console. Nenhum envio ou lançamento automático está configurado.
