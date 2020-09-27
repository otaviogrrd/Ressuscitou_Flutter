import "package:flutter/material.dart";
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import "package:ressuscitou/helpers/global.dart";

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  bool wfOnly = false;
  bool estendido = false;
  bool escalaAmericana = false;

  @override
  void initState() {
    wfOnly = globals.prefs.getBool("wfOnly") ?? false;
    estendido = globals.prefs.getBool("estendido") ?? true;
    escalaAmericana = globals.prefs.getBool("escalaAmericana") ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Opções"), centerTitle: false),
        body: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                Divider(color: Colors.black26, height: 2.0),
                SwitchListTile(
                    title: Text("Apenas WiFi"),
                    subtitle: Text("Não utilizar dados móveis"),
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
                Divider(color: Colors.black26, height: 2.0),
                ListTile(
                    title: Text("Apagar Transposições Salvas"),
                    onTap: () => deleteConfirm("Transposições Salvas", "TRANSP_", "Transposições apagadas")),
                Divider(color: Colors.black26, height: 2.0),
                ListTile(
                    title: Text("Apagar Capotrastes Salvos"),
                    onTap: () => deleteConfirm("Capotrastes Salvos", "CAPOT_", "Capotrastes apagados")),
                Divider(color: Colors.black26, height: 2.0),
                ListTile(
                    title: Text("Apagar Anotações Salvas"),
                    onTap: () => deleteConfirm("Anotações Salvas", "ANOT_", "Anotações apagadas")),
                Divider(color: Colors.black26, height: 2.0),
                SizedBox(height: 15),
                ListTile(
                  title: Text("Tamanho da Fonte"),
                  subtitle: Slider(
                    max: 44,
                    min: 2,
                    divisions: 10,
                    inactiveColor: Colors.grey,
                    activeColor: globals.darkRed,
                    value: (double.parse((globals.prefs.getInt("tamanhoFonte") ?? 15).toString())),
//                    label: globals.prefs.getInt("tamanhoFonte").toString(),
                    onChanged: (value) {
                      globals.prefs.setInt("tamanhoFonte", value.round());
                      setState(() {});
                    },
                  ),
                ),
              ]),
            )));
  }

  deleteConfirm(String message, String keyStr, String sucessMsg) {
    return Get.defaultDialog(
        title: "Apagar $message",
        radius: 4,
        content: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.6),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Tem certeza que deseja apagar?", textAlign: TextAlign.center),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Container(
                          margin: EdgeInsets.only(top: 8),
                          width: 100,
                          child: FlatButton(
                            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Cancelar")),
                            color: Colors.grey[200],
                            textColor: Colors.black,
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                          )),
                      Container(
                          margin: EdgeInsets.only(top: 8),
                          width: 100,
                          child: FlatButton(
                            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Apagar")),
                            color: globals.darkRed,
                            textColor: Colors.white,
                            onPressed: () async {
                              globals.cantosGlobal
                                  .forEach((element) => globals.prefs.remove(keyStr + element.id.toString()));
                              Navigator.of(context).pop();
                              snackBar(Get.overlayContext, sucessMsg);
                            },
                          )),
                    ],
                  ),
                ],
              ),
            )));
  }
}
