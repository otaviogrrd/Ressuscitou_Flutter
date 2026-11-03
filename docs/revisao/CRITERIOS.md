# Critérios da revisão visual dos cantos

A revisão compara a imagem oficial com uma captura real do HTML renderizado
pelo Chromium. Confiança do OCR, diferenças de pixels e validação das tags
não substituem a inspeção visual. A captura de Chromium não é uma captura de
aparelho físico; a escala ajustada dos painéis também pode diferir da ficha.

Cada registro deve identificar título, URL da ficha, arquivos das evidências,
variantes inspecionadas e discrepâncias observadas. Aprovar um canto exige
conferir todas as suas páginas, letra, acentos, cifras/acidentes, alinhamento
das cifras em relação à letra, ordem das estrofes e repetições. Quando a
imagem não permitir ler um ponto com segurança, registrá-lo como pendente.

Estados usados:

- **Reprovado:** existe discrepância visual concreta que impede incorporação.
- **Pendente:** a evidência não foi inspecionada por completo ou exige decisão.
- **Conferido visualmente:** as duas evidências foram lidas por completo sem
  discrepância observada, limitado à variante e à captura identificadas.

A versão estendida existente é a variante preferencial do usuário e permanece
ativada por padrão. Ela escreve as repetições por extenso e não deve receber
novamente barras de bis. Diferenças intencionais entre a ficha abreviada e a
versão estendida devem ser tratadas como expansão editorial, não como falha de
OCR. Uma revisão do rascunho normal não aprova automaticamente a expansão.

Nenhuma correção deve substituir automaticamente `html_base64` ou `ext_base64`.
Na incorporação, preservar as duas variantes e os hooks da WebView, a fonte
monoespaçada, os espaços de alinhamento, `<H1>`, `#FF0000`, `@transp@` e
`@capot@`. Alterações ficam fora do catálogo até conferência e validação.

A conversão de cifras A–G para nomes europeus é intencional e necessária à
transposição do app: A=La, B=Si, C=Do, D=Re, E=Mi, F=Fa e G=Sol. Essa mudança
de notação não é falha quando preserva a altura. Conferir separadamente
sustenidos/bemóis, qualidade maior/menor, extensões e nota do baixo. Uma cifra
reconhecida como palavra ou instrução não deve ser tratada como acorde válido.

Quando uma discrepância já reprovar a ficha, registrar a evidência concreta e
indicar se a exatidão integral da transcrição ainda não foi exaurida. Não
converter esse diagnóstico em aprovação das linhas restantes.
