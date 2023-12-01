import 'dart:convert';
import "dart:io";

import 'package:file_picker/file_picker.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import "package:intl/intl.dart";
import 'package:path_provider/path_provider.dart';

import "../helpers/global.dart";
import '../model/cantoList.dart';
import '../model/configuracoes.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  bool wfOnly = false;
  bool estendido = false;
  bool escalaAmericana = false;
  bool tablet = false;

  @override
  void initState() {
    wfOnly = globals.prefs.getBool("wfOnly") ?? false;
    estendido = globals.prefs.getBool("estendido") ?? true;
    escalaAmericana = globals.prefs.getBool("escalaAmericana") ?? false;
    tablet = globals.prefs.getBool("tablet") ?? true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Opções"), centerTitle: false),
        body: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(children: [
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                SwitchListTile(
                    activeColor: Theme.of(context).colorScheme.primary,
                    title: Text("Apenas WiFi"),
                    subtitle: Text("Não utilizar dados móveis"),
                    value: wfOnly,
                    onChanged: (value) {
                      globals.prefs.setBool("wfOnly", value);
                      setState(() => wfOnly = value);
                    }),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                SwitchListTile(
                    activeColor: Theme.of(context).colorScheme.primary,
                    title: Text("Modo Estendido"),
                    subtitle: Text("Exibe o canto completo, sem resumir o refrão"),
                    value: estendido,
                    onChanged: (value) {
                      globals.prefs.setBool("estendido", value);
                      setState(() => estendido = value);
                    }),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                SwitchListTile(
                    activeColor: Theme.of(context).colorScheme.primary,
                    title: Text("Cifras Americanas"),
                    subtitle: Text("| C | D | E | F | G | A | B |"),
                    value: escalaAmericana,
                    onChanged: (value) {
                      globals.prefs.setBool("escalaAmericana", value);
                      setState(() => escalaAmericana = value);
                    }),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                ListTile(
                    title: Text("Apagar Transposições Salvas"),
                    onTap: () => deleteConfirm("Transposições Salvas", "TRANSP_", "Transposições apagadas")),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                ListTile(
                    title: Text("Apagar Capotrastes Salvos"), onTap: () => deleteConfirm("Capotrastes Salvos", "CAPOT_", "Capotrastes apagados")),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                ListTile(title: Text("Apagar Anotações Salvas"), onTap: () => deleteConfirm("Anotações Salvas", "ANOT_", "Anotações apagadas")),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                SizedBox(height: 15),
                ListTile(
                  title: Text("Tamanho da Fonte"),
                  subtitle: Slider(
                    max: 44,
                    min: 2,
                    divisions: 10,
                    inactiveColor: Colors.grey,
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: (double.parse((globals.prefs.getInt("tamanhoFonte") ?? 15).toString())),
//                    label: globals.prefs.getInt("tamanhoFonte").toString(),
                    onChanged: (value) {
                      globals.prefs.setInt("tamanhoFonte", value.round());
                      setState(() {});
                    },
                  ),
                ),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                SwitchListTile(
                    activeColor: Theme.of(context).colorScheme.primary,
                    title: Text("Modo Tablet"),
                    value: tablet,
                    onChanged: (value) {
                      globals.prefs.setBool("tablet", value);
                      setState(() => tablet = value);
                    }),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                ListTile(title: Text("Exportar Dados Salvos"), onTap: () => exportarDados()),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
                ListTile(title: Text("Importar Dados"), onTap: () => importarDados()),
                Divider(color: Theme.of(context).colorScheme.onBackground, height: 2.0),
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
              children: [
                Text("Tem certeza que deseja apagar?", textAlign: TextAlign.center),
              ],
            ),
          )),
      confirm: Container(
          margin: EdgeInsets.only(top: 8),
          width: 100,
          child: FlatButton(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Apagar")),
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () async {
              globals.cantosGlobal.forEach((element) => globals.prefs.remove(keyStr + element.id.toString()));
              Navigator.of(context).pop();
              snackBar(Get.overlayContext, sucessMsg);
            },
          )),
      cancel: Container(
          margin: EdgeInsets.only(top: 8),
          width: 100,
          child: FlatButton(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Cancelar")),
            color: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () async {
              Navigator.of(context).pop();
            },
          )),
    );
  }

  exportarDados() async {
    int trans = 0;
    int capot = 0;
    String anota = "";
    List<CantoList> listas = [];

    Configuracoes configuracoes = new Configuracoes(cantos: [], listas: []);
    configuracoes.listas = await CantoListService().getCantosList();

    for (var i = 0; i < globals.cantosGlobal.length; i++) {
      trans = globals.prefs.getInt("TRANSP_" + globals.cantosGlobal[i].id.toString()) ?? 0;
      capot = globals.prefs.getInt("CAPOT_" + globals.cantosGlobal[i].id.toString()) ?? 0;
      anota = globals.prefs.getString("ANOT_" + globals.cantosGlobal[i].id.toString()) ?? "";
      if (trans > 0 || capot > 0 || anota != "") {
        CantosConfig item = new CantosConfig(cantoId: globals.cantosGlobal[i].id, trans: trans, capot: capot, anota: anota);
        configuracoes.cantos.add(item);
      }
    }
    if (configuracoes.listas.isEmpty && configuracoes.cantos.isEmpty) {
      snackBar(Get.overlayContext, "Nada para exportar.");
      return;
    }

    var datetime = DateFormat("yyyyMMdd-HHmmss").format(DateTime.now()).toString();
    String filename = "Ressuscitou_Dados_$datetime.json";

    try {
      String dir = "";
      if (Platform.isAndroid) {
        dir = "/storage/emulated/0/Download/";
      } else if (Platform.isIOS) {
        dir = (await getDownloadsDirectory()).path;
      }
      final String path = "$dir/" + filename;
      final File file = File(path);
      file.writeAsStringSync(getPrettyJSONString(configuracoes));
      snackBar(Get.overlayContext, "Arquivo salvo em:\n$dir");
    } on Exception catch (e) {
      snackBar(Get.overlayContext, e.toString());
    }
  }

  importarDados() async {
    try {
      var _paths = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['json'],
      ))
          ?.files;
      if (_paths != null) if (_paths.isNotEmpty) {
        var myFile = File(_paths.first.path);

        List<String> content = myFile.readAsLinesSync();
        String str = content.join("");
        Configuracoes configuracoes = new Configuracoes.fromJson(jsonDecode(str));

        configuracoes.cantos.forEach((element) {
          if (element.trans > 0) globals.prefs.setInt("TRANSP_" + element.cantoId.toString(), element.trans);
          if (element.capot > 0) globals.prefs.setInt("CAPOT_" + element.cantoId.toString(), element.capot);
          if (element.anota != "") globals.prefs.setString("ANOT_" + element.cantoId.toString(), element.anota);
        });

        configuracoes.listas.forEach((element) {
          CantoListService().saveList(listaOld: element.titulo, listaNew: element);
        });

        snackBar(Get.overlayContext, "Dados importados com sucesso.");
      }
    } on PlatformException catch (e) {
      snackBar(Get.overlayContext, 'Erro: ' + e.toString());
    } catch (e) {
      snackBar(Get.overlayContext, e.toString());
    }
  }
}
