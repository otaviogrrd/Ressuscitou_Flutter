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
              Image.asset("assets/img/logocat.png", height: 80),
              SizedBox(height: 15),
              Image.asset("assets/img/logo.png", height: 30),
              SizedBox(height: 20),
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
              SizedBox(height: 50),
              Text('Este aplicativo NÃO deve ser utilizado em celebrações.',
                  style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              SizedBox(height: 10),
              Text('Pode ser utilizado apenas como apoio aos samistas para ensaios, consultas e preparações.',
                  textAlign: TextAlign.center),
              SizedBox(height: 50),
              InkWell(
                  onTap: () => launchUrl(),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                    Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Deixe sua avaliação e cometário!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: globals.darkRed),
                        )),
                    Icon(Icons.arrow_forward, color: globals.darkRed),
                  ])),
              SizedBox(height: 50),
              Text('Desenvolvido por:', textAlign: TextAlign.center),
              SizedBox(height: 5),
              InkWell(
                  onTap: () => launchEmail(),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          child: Icon(Icons.mail_outline, size: 14, color: globals.darkRed),
                        ),
                        TextSpan(
                          text: "  Otávio Garrido Moraes  ",
                        ),
                      ],
                      style: TextStyle(fontWeight: FontWeight.bold, color: globals.darkRed),
                    ),
                  )),
              SizedBox(height: 100),
              InkWell(
                onTap: () => Get.to(LicensePage(
                  applicationLegalese: 'Os Cantos do Livro Ressucitou, de Francisco José Gómez de Argüello Wirtz,'
                      'aqui distribuídos pelo Centro Neocatecumenal do Brasil (cn.org.br),'
                      'estão livres de restrições de direitos autorais '
                      'e de direitos conexos conhecidos.',
                )),
                child: Text("  Licenças  ", style: TextStyle(fontWeight: FontWeight.bold, color: globals.darkRed)),
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
