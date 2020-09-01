import 'package:flutter/material.dart';
import 'package:ressuscitou/helpers/global.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool wfOnly = false;
  bool estendido = false;
  bool escalaAmericana = false;
//  bool numeracao2015 = false;

  @override
  void initState() {
    wfOnly = globals.prefs.getBool("wfOnly") ?? false;
    estendido = globals.prefs.getBool("estendido") ?? true;
    escalaAmericana = globals.prefs.getBool("escalaAmericana") ?? false;
//    numeracao2015 = globals.prefs.getBool("numeracao2015") ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Ressuscitou')),
        body: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                Divider(color: Colors.black26, height: 2.0),
                SwitchListTile(
                    title: Text("Apenas WiFi"),
                    subtitle: Text("Não utilzar dados móveis"),
                    value: wfOnly,
                    onChanged: (value) {
                      globals.prefs.setBool("wfOnly", value);
                      setState(() => wfOnly = value);
                    }),
                Divider(color: Colors.black26, height: 2.0),
                SwitchListTile(
                    title: Text("Modo Estendido"),
                    subtitle: Text("Exibe o canto completo, sem resumir o refrão"),
                    value: estendido,
                    onChanged: (value) {
                      globals.prefs.setBool("estendido", value);
                      setState(() => estendido = value);
                    }),
                Divider(color: Colors.black26, height: 2.0),
                SwitchListTile(
                    title: Text("Cifras Americanas"),
                    subtitle: Text("| C | D | E | F | G | A | B |"),
                    value: escalaAmericana,
                    onChanged: (value) {
                      globals.prefs.setBool("escalaAmericana", value);
                      setState(() => escalaAmericana = value);
                    }),
//                Divider(color: Colors.black26, height: 2.0),
//                SwitchListTile(
//                    title: Text("Numeração Antiga"),
//                    subtitle: Text("Conforme a Edição 2015 do livro"),
//                    value: numeracao2015,
//                    onChanged: (value) {
//                      globals.prefs.setBool("numeracao2015", value);
//                      setState(() => numeracao2015 = value);
//                    }),
                Divider(color: Colors.black26, height: 2.0),
                ListTile(
                    title: Text("Apagar Transposições Salvas"),
                    onTap: () {
                      globals.cantosGlobal.forEach((element) => globals.prefs.remove("TRANSP_" + element.id.toString()));
                      snackBar("Transposições apagadas");
                    }),
                Divider(color: Colors.black26, height: 2.0),
                ListTile(
                    title: Text("Apagar Capotrastes Salvos"),
                    onTap: () {
                      globals.cantosGlobal.forEach((element) => globals.prefs.remove("CAPOT_" + element.id.toString()));
                      snackBar("Capotrastes apagados");
                    }),
                Divider(color: Colors.black26, height: 2.0),
                ListTile(
                    title: Text("Apagar Anotações Salvas"),
                    onTap: () {
                      globals.cantosGlobal.forEach((element) => globals.prefs.remove("ANOT_" + element.id.toString()));
                      snackBar("Anotações apagadas");
                    }),
                Divider(color: Colors.black26, height: 2.0),
              ]),
            )));
  }
}
