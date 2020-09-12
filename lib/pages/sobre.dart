import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info/package_info.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:url_launcher/url_launcher.dart';

class SobrePage extends StatefulWidget {
  @override
  _SobrePageState createState() => _SobrePageState();
}

class _SobrePageState extends State<SobrePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Ressuscitou')),
        body: Container(
          margin: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(children: <Widget>[
              Image.asset("assets/img/logo.png", width: MediaQuery.of(context).size.width * 0.6),
              SizedBox(height: 10),
              FutureBuilder(
                  future: PackageInfo.fromPlatform(),
                  builder: (BuildContext cont, AsyncSnapshot<PackageInfo> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return CircularProgressIndicator();
                      case ConnectionState.done:
                        return Text(
                          'Versão: ${snapshot.data.version}+${snapshot.data.buildNumber}',
                        );
                      default:
                        return Container();
                    }
                  }),
              SizedBox(height: 30),
              Text('Este aplicativo NÃO deve ser utilizado em celebrações.',
                  style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              SizedBox(height: 10),
              Text('Pode ser utilizado apenas como apoio aos salmistas para ensaios, consultas e preparações.',
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
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )),
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(4)), color: globals.darkRed),
                  ),
                ),
              SizedBox(height: 50),
              Text('Desenvolvido por:', style: TextStyle(fontSize: 10), textAlign: TextAlign.center),
              InkWell(
                onTap: () => launchEmail(),
                child: Container(
                  height: 45,
                  width: 250,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
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
                                  fit: BoxFit.scaleDown,
                                  child: Text("  Otávio Garrido Moraes",
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500))),
                            ])
                          ],
                        ),
                      ),
                    ],
                  ),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(4)), color: Colors.grey[200]),
                ),
              ),
              SizedBox(height: 50),
              InkWell(
                onTap: () => Get.to(LicensePage(
                  applicationLegalese: 'Os Cantos do Livro Ressuscitou, de Francisco José Gómez de Argüello Wirtz,'
                      'distribuídos em português(BR) pelo Centro Neocatecumenal do Brasil (neocatechumenaleiter.org),'
                      'estão livres de restrições de direitos autorais e de direitos conexos conhecidos.',
                )),
                child: Container(
                  height: 45,
                  width: 150,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("Licenças", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(4)), color: Colors.black45),
                ),
              ),
            ]),
          ),
        ));
  }

  launchUrl() async {
    const url = 'https://play.google.com/store/apps/details?id=br.org.cn.ressuscitou&hl=pt_BR';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      snackBar('Erro ao abrir navegador');
    }
  }

  launchEmail() async {
    const url = 'mailto:otavio.grrd@gmail.com?subject=App Ressuscitou';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      snackBar('Erro ao iniciar e-mail');
    }
  }
}
