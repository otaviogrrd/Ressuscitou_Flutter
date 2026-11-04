import "dart:io";

import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import "package:get/get.dart";
import "package:url_launcher/url_launcher.dart" as launcher;

import "../helpers/global.dart";

class SobrePage extends StatefulWidget {
  @override
  _SobrePageState createState() => _SobrePageState();
}

class _SobrePageState extends State<SobrePage> {
  bool emailFail = false;

  @override
  Widget build(BuildContext context) {
    int cantosVersaoLocal = (globals.prefs.getInt("cantosVersao") ?? 0);
    return Scaffold(
        appBar: AppBar(title: Text("Sobre"), centerTitle: false),
        body: Container(
          margin: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(children: [
              Image.asset("assets/img/logo.png", width: MediaQuery.of(context).size.width * 0.6),
              SizedBox(height: 10),
              Text("Versão: ${globals.packInfo.version}+${globals.packInfo.buildNumber} [$cantosVersaoLocal]"),
              SizedBox(height: 30),
              Text("Este aplicativo NÃO deve ser utilizado em celebrações.", style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              SizedBox(height: 10),
              Text("Pode ser utilizado apenas como apoio aos salmistas para ensaios, consultas e preparações.",
                  style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              if (Platform.isAndroid) SizedBox(height: 30),
              if (Platform.isAndroid)
                InkWell(
                  onTap: () => launchUrl(),
                  child: Container(
                    height: 45,
                    width: 350,
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Deixe sua avaliação e cometário!",
                              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                        )),
                    decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(4)), color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              SizedBox(height: 50),
              Text("Desenvolvido por:", style: TextStyle(fontSize: 10), textAlign: TextAlign.center),
              if (!emailFail)
                InkWell(
                  onTap: () => launchEmail(),
                  child: Container(
                    height: 45,
                    width: 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Table(
                            columnWidths: {
                              0: IntrinsicColumnWidth(flex: 0.2),
                              1: IntrinsicColumnWidth(flex: 0.8),
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(children: [
                                Center(child: Icon(Icons.mail_outline)),
                                FittedBox(
                                    fit: BoxFit.scaleDown, child: Text("  Otávio Garrido Moraes", style: TextStyle(fontWeight: FontWeight.w500))),
                              ])
                            ],
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(4)), color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              if (emailFail)
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: "otavio.grrd@gmail.com"));
                        snackBar(Get.overlayContext, "E-mail copiado");
                      },
                      child: Container(
                        height: 45,
                        width: 250,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Table(
                                columnWidths: {
                                  0: IntrinsicColumnWidth(flex: 0.8),
                                  1: IntrinsicColumnWidth(flex: 0.2),
                                },
                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                children: [
                                  TableRow(children: [
                                    Column(
                                      children: [
                                        FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "Otávio Garrido Moraes",
                                              style: TextStyle(fontWeight: FontWeight.w500),
                                            )),
                                        FittedBox(fit: BoxFit.scaleDown, child: Text("otavio.grrd@gmail.com")),
                                      ],
                                    ),
                                    Center(child: Icon(Icons.content_copy)),
                                  ])
                                ],
                              ),
                            ),
                          ],
                        ),
                        decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(4)), color: Theme.of(context).colorScheme.secondary),
                      ),
                    )
                  ],
                ),
              SizedBox(height: 50),
              InkWell(
                onTap: () => Get.to(() => LicensePage(
                      applicationLegalese: 'Cantos e direitos autorais\n\n'
                          'Conforme a Nota da Oitava Edição do livro Ressuscitou, os cantos de autoria de Kiko Argüello '
                          'estão registrados na Sociedade Italiana de Autores e Editores, com cobertura mundial, '
                          'para garantir seu livre uso pelos irmãos nas liturgias do Caminho Neocatecumenal '
                          'e preservar sua autenticidade e finalidade própria.\n\n'
                          'O livro Ressuscitou do Caminho Neocatecumenal no Brasil está registrado em nome da '
                          'Associação Virgem do Terceiro Milênio para a Evangelização Itinerante, '
                          'ISBN 978-65-84381-00-1. A nota informa a proibição de venda em lojas ou empresas comerciais '
                          'e orienta a preservar os cantos e as catequeses, evitando alterações, lucro '
                          'e publicação em plataformas além das oficiais.\n\n'
                          'A disponibilização gratuita não equivale à ausência de direitos autorais '
                          'nem constitui autorização geral de reprodução ou redistribuição.\n\n'
                          'Este aplicativo é uma ferramenta de apoio aos salmistas para ensaios, consultas '
                          'e preparações; não deve ser utilizado em celebrações. '
                          'Esta declaração não atribui caráter oficial ao aplicativo nem declara autorização dos titulares.',
                    )),
                child: Container(
                  height: 45,
                  width: 150,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text("Licenças", style: TextStyle(fontWeight: FontWeight.bold))),
                  decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(4)), color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ]),
          ),
        ));
  }

  launchUrl() async {
    const url = "https://play.google.com/store/apps/details?id=br.org.cn.ressuscitou&hl=pt_BR";
    launcher.launchUrl(Uri.parse(url)).then(
      (bool isLaunch) {
        if (!isLaunch) {
          snackBar(Get.overlayContext, "Erro ao abrir navegador");
        }
      },
      onError: (e) {
        snackBar(Get.overlayContext, "Erro ao abrir navegador");
      },
    ).catchError(
      (ex) {
        snackBar(Get.overlayContext, "Erro ao abrir navegador");
      },
    );
  }

  launchEmail() async {
    const url = "mailto:otavio.grrd@gmail.com?subject=Ressuscitou";
    launcher.launchUrl(Uri.parse(url)).then(
      (bool isLaunch) {
        if (isLaunch) {
          emailFail = false;
        } else {
          snackBar(Get.overlayContext, "Erro ao iniciar aplicativo de e-mail");
          emailFail = true;
          setState(() {});
        }
      },
      onError: (e) {
        snackBar(Get.overlayContext, "Erro ao iniciar aplicativo de e-mail");
        emailFail = true;
        setState(() {});
      },
    ).catchError(
      (ex) {
        snackBar(Get.overlayContext, "Erro ao iniciar aplicativo de e-mail");
        emailFail = true;
        setState(() {});
      },
    );
  }
}
