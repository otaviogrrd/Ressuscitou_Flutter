import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/model/canto.dart';
import 'package:ressuscitou/pages/audios.dart';
import 'package:ressuscitou/pages/canto.dart';
import 'package:ressuscitou/pages/imageViewer.dart';
import 'package:ressuscitou/pages/listas.dart';
import 'package:ressuscitou/pages/liturgico.dart';
import 'package:ressuscitou/pages/settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'sobre.dart';

class HomePage extends StatefulWidget {
  bool selectable = false;

  HomePage({Key key, this.selectable}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Canto> listCantos = [];
  List<Canto> filterListCantos = [];
  int selectedCateg = 0;
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  String searchField = '';
  bool showSearch = false;
  bool numeracao2015 = false;

  @override
  void initState() {
    super.initState();
    Timer.run(() => getTermo());
  }

  @override
  Widget build(BuildContext context) {
    numeracao2015 = globals.prefs.getBool("numeracao2015") ?? false;
    return Scaffold(
      appBar: AppBar(title: Text('Ressuscitou'), actions: [
        if (!showSearch)
          IconButton(
              icon: Icon(Icons.search, size: 25, color: Colors.white),
              onPressed: () => setState(() => showSearch = true))
      ]),
      drawer: (widget.selectable != null && widget.selectable) ? null : Drawer(child: getMenuLateral()),
      body: getCantosLocal(),
    );
  }

  getTermo() async {
    var termos = globals.prefs.getBool("TermosIniciaisLidos") ?? false;
    if (!termos)
      Get.defaultDialog(
        title: 'Atenção',
        radius: 4,
        content: Column(
          children: <Widget>[
            Text('Este aplicativo NÃO deve ser utilizado em celebrações.',
                style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
            SizedBox(height: 10),
            Text('Pode ser utilizado apenas como apoio aos samistas para ensaios, consultas e preparações.',
                textAlign: TextAlign.center),
          ],
        ),
        confirm: Container(
          width: 100,
          child: FlatButton(
              child: FittedBox(fit: BoxFit.scaleDown, child: Text("Entendi")),
              color: globals.darkRed,
              textColor: Colors.white,
              onPressed: () {
                globals.prefs.setBool("TermosIniciaisLidos", true);
                Navigator.pop(context);
              }),
        ),
      );
  }

  listaCantos() {
    if (listCantos != null) {
      filtrar();
      return Column(
        children: <Widget>[
          if (showSearch) searchInput(),
          Expanded(
            child: ListView.builder(
                itemCount: filterListCantos.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => Get.to(CantoPage(canto: filterListCantos[index])).then((value) => {setState(() {})}),
                    child: (widget.selectable != null && widget.selectable)
                        ? CheckboxListTile(
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) => setState(() {
                              filterListCantos[index].selected = value;
                              (value)
                                  ? globals.listaGlobal.add(filterListCantos[index])
                                  : globals.listaGlobal.removeWhere((e) => e.id == filterListCantos[index].id);
                            }),
                            value: filterListCantos[index].selected,
                            title: Row(
                              children: <Widget>[
                                ClipOval(
                                    child: Material(
                                        color: getColorCateg(filterListCantos[index].categoria), // button color
                                        child: Container(
                                            height: 40,
                                            width: 40,
                                            child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: Text((numeracao2015)
                                                        ? filterListCantos[index].numero
                                                        : filterListCantos[index].nr2019)))))),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Text(
                                      filterListCantos[index].titulo,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.only(left: 16, right: 10),
                            leading: ClipOval(
                                child: Material(
                                    color: getColorCateg(filterListCantos[index].categoria), // button color
                                    child: Container(
                                        height: 40,
                                        width: 40,
                                        child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text((numeracao2015)
                                                    ? filterListCantos[index].numero
                                                    : filterListCantos[index].nr2019)))))),
                            title: Text(
                              filterListCantos[index].titulo,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            trailing: geticon(filterListCantos[index]),
                          ),
                  );
                }),
          ),
        ],
      );
    }
    return Container();
  }

  geticon(Canto canto) {
    if (canto.url != '') {
      if (canto.downloaded != null && canto.downloaded)
        return Icon(Icons.music_note, color: globals.darkRed);
      else
        return Icon(Icons.music_note, color: Colors.grey);
    } else
      return Icon(Icons.music_note, color: Colors.transparent);
  }

  getCantosLocal() {
    return FutureBuilder(
        future: CantoService().getCantosLocal(),
        builder: (BuildContext cont, AsyncSnapshot<List<Canto>> snapshot) {
          if (snapshot.hasData) {
            listCantos = snapshot.data;
            return listaCantos();
          } else
            return Center(child: CircularProgressIndicator());
        });
  }

  getColorCateg(int categoria) {
    switch (categoria) {
      case 2:
        return Colors.blue[200];
      case 3:
        return Colors.green[200];
      case 4:
        return Colors.orange[100];
      default:
        return Colors.grey[200];
    }
  }

  Widget divider() {
    return Padding(
      padding: EdgeInsets.all(5),
      child: Divider(color: Colors.black26, height: 2.0),
    );
  }

  getMenuLateral() {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Stack(
      children: <Widget>[
        ListView(
          children: <Widget>[
            Row(children: <Widget>[
              Padding(
                padding: EdgeInsets.all(20),
                child: Image.asset("assets/img/logocat.png", height: 80),
              ),
              Image.asset("assets/img/logo.png", height: 30),
            ]),
            divider(),
            ListTile(
                title: Padding(
                  padding: EdgeInsets.only(left: 40),
                  child: Text("Ordem Alfabética", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                onTap: () => setState(() => selectCateg(0))),
            ListTile(
                title: Padding(
                  padding: EdgeInsets.only(left: 40),
                  child: Text("Índice Litúrgico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Get.to(LiturgicoPage()).then((value) => setState(() {}));
                }),
            divider(),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(child: Text("Filtrar Etapa", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11))),
            ),
            ListTile(
                title: Text("Pré-Catecumentato"),
                leading: ClipOval(
                  child: Material(
                    color: getColorCateg(1), // button color
                    child: SizedBox(width: 25, height: 25),
                  ),
                ),
                onTap: () => setState(() => selectCateg(1))),
            ListTile(
                title: Text("Litúrgicos"),
                leading: ClipOval(
                  child: Material(
                    color: getColorCateg(4), // button color
                    child: SizedBox(width: 25, height: 25),
                  ),
                ),
                onTap: () => setState(() => selectCateg(4))),
            ListTile(
                title: Text("Catecumentato"),
                leading: ClipOval(
                  child: Material(
                    color: getColorCateg(2), // button color
                    child: SizedBox(width: 25, height: 25),
                  ),
                ),
                onTap: () => setState(() => selectCateg(2))),
            ListTile(
                title: Text("Eleição"),
                leading: ClipOval(
                  child: Material(
                    color: getColorCateg(3), // button color
                    child: SizedBox(width: 25, height: 25),
                  ),
                ),
                onTap: () => setState(() => selectCateg(3))),
            divider(),
            ListTile(
                leading: Icon(Icons.line_style, size: 25, color: globals.darkRed),
                title: Text("Acordes"),
                onTap: () {
                  Get.to(ImageViwerPage(img: "assets/img/acordes.jpg")).then((value) => setState(() {}));
                }),
            ListTile(
                title: Text("Arpejos"),
                leading: Icon(Icons.timeline, size: 25, color: globals.darkRed),
                onTap: () {
                  Get.to(ImageViwerPage(img: "assets/img/arpejos.jpg")).then((value) => setState(() {}));
                }),
            divider(),
            ListTile(
                title: Text("Listas"),
                leading: Icon(Icons.list, size: 25, color: globals.darkRed),
                onTap: () => Get.to(ListasPage()).then((value) => setState(() {}))),
            ListTile(
                title: Text("Audios"),
                leading: Icon(Icons.music_note, size: 25, color: globals.darkRed),
                onTap: () => Get.to(AudiosPage()).then((value) => setState(() {}))),
            ListTile(
                title: Text("Opções"),
                leading: Icon(Icons.settings, size: 25, color: globals.darkRed),
                onTap: () => Get.to(SettingsPage()).then((value) => setState(() {}))),
            ListTile(
                title: Text("Descubra seu Tom"),
                leading: Icon(Icons.call_made, size: 25, color: globals.darkRed),
                onTap: () => launchUrl()),
            ListTile(
                title: Text("Sobre"),
                leading: Icon(Icons.info_outline, size: 25, color: globals.darkRed),
                onTap: () => Get.to(SobrePage()))
          ],
        ),
        Container(height: statusBarHeight, decoration: BoxDecoration(color: globals.darkRedShadow)),
      ],
    );
  }

  selectCateg(int i) {
    selectedCateg = i;
    Navigator.of(context).pop();
  }

  searchInput() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Stack(
        children: <Widget>[
          FormBuilder(
              key: formKey,
              child: Column(children: <Widget>[
                FormBuilderTextField(
                    attribute: 'search',
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.go,
                    onChanged: (value) {
                      searchField = value;
                      setState(() {
                        filtrar();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Pesquisar",
                    ))
              ])),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                searchField = "";
                showSearch = false;
                setState(() {
                  filtrar();
                });
              },
              child: Container(
                  margin: EdgeInsets.all(5),
                  child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: globals.darkRed,
                      ))),
            ),
          ),
        ],
      ),
    );
  }

  filtrar() {
    List<Canto> list_tmp;
    filterListCantos = [];
    if (selectedCateg != 0) {
      list_tmp = listCantos.where((c) => (c.categoria == selectedCateg)).toList();
      filterListCantos.addAll(list_tmp);
    } else
      filterListCantos = listCantos;

    list_tmp = filterListCantos;

    searchField = searchField.replaceAll("ã", "a");
    searchField = searchField.replaceAll("õ", "o");
    searchField = searchField.replaceAll("á", "a");
    searchField = searchField.replaceAll("é", "é");
    searchField = searchField.replaceAll("í", "i");
    searchField = searchField.replaceAll("ó", "o");
    searchField = searchField.replaceAll("ú", "u");
    searchField = searchField.replaceAll("ç", "c");
    searchField = searchField.replaceAll(new RegExp(r'[^\w\s]+'), '');
    searchField = searchField.replaceAll(" ", "");

    if (searchField != '') {
      filterListCantos = list_tmp.where((p) => (p.conteudo.toLowerCase().contains(searchField.toLowerCase()))).toList();
    }

    if (widget.selectable != null && widget.selectable) {
      for (var c = 0; c < filterListCantos.length; c++) {
        globals.listaGlobal.forEach((element) {
          if (element.id == filterListCantos[c].id) filterListCantos[c].selected = element.selected;
        });
      }
    }
  }

  launchUrl() async {
    const url = 'http://neo-transposer.com/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      snackBar('Erro ao abrir navegador');
    }
  }
}
