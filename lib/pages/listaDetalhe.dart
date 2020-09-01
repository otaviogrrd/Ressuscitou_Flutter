import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/model/cantoList.dart';
import 'package:ressuscitou/pages/home.dart';
import 'package:ressuscitou/pages/canto.dart';
import 'package:share/share.dart';

class ListaDetalhePage extends StatefulWidget {
  CantoList lista;

  ListaDetalhePage({Key key, @required this.lista}) : super(key: key);

  @override
  _ListaDetalhePageState createState() => new _ListaDetalhePageState();
}

class _ListaDetalhePageState extends State<ListaDetalhePage> {
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  String listaOld = "";
  CantoList listaNew = new CantoList(cantos: []);
  bool editMode = false;

  @override
  void initState() {
    globals.listaGlobal = [];
    if (widget.lista.titulo == "") {
      editMode = true;
    } else {
      listaOld = widget.lista.titulo;
      listaNew = widget.lista;
    }
    widget.lista.cantos.forEach((i) {
      globals.listaGlobal.add(globals.cantosGlobal.where((c) => (c.id == i)).toList().first);
    });
    globals.listaGlobal.forEach((element) {
      element.selected = true;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String share = '';
    globals.listaGlobal.forEach((element) {
      share = share + element.nr2019.padLeft(3,'0') + ' - ' + element.titulo + '\n';
    });
    return Scaffold(
        appBar: AppBar(elevation: 0.0, centerTitle: true, title: Text("Lista"), actions: [
          if (listaOld != '') IconButton(icon: Icon(Icons.delete), onPressed: () => deleteList()),
          (editMode)
              ? IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () => setState(() {
                        salvarLista();
                      }))
              : IconButton(icon: Icon(Icons.edit), onPressed: () => setState(() => editMode = !editMode)),
        ]),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.share),
            elevation: 1,
            onPressed: () {
              Share.share('Confira a lista *${listaNew.titulo}*, que criei no App *Ressucitou*:\n\n$share');
            }),
        body: Container(
            margin: EdgeInsets.symmetric(horizontal: 11),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: FormBuilder(
                    key: formKey,
                    readOnly: !editMode,
                    child: Column(children: <Widget>[
                      FormBuilderTextField(
                          cursorColor: globals.lightRed,
                          attribute: 'Título',
                          initialValue: listaOld,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 2,
                          textInputAction: TextInputAction.go,
                          onChanged: (value) {
                            listaNew.titulo = value;
                          },
                          validators: [FormBuilderValidators.required(errorText: 'Informe um título para lista!')],
                          decoration: InputDecoration(
                            labelText: "Título",
                          ))
                    ])),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Container(height: 1, color: (!editMode) ? globals.lightRed : Colors.transparent)),
              Container(height: 9),
              Expanded(child: listCantos()),
              Container(height: 11),
            ])));
  }

  Widget listCantos() {
    return Card(
        elevation: 2,
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2)),
        child: Column(mainAxisSize: MainAxisSize.max, children: [
          GestureDetector(
            onTap: (editMode) ? () => Get.to(HomePage(selectable: true)).then((result) => setState(() {})) : () {},
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                  color: globals.lightRed,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2))),
              child: Stack(children: <Widget>[
                Center(
                    child: Text(
                  'Cantos',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                )),
                if (editMode && globals.listaGlobal.length > 0)
                  Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.add, color: Colors.white, size: 25),
                      ))
              ]),
            ),
          ),
          Expanded(child: getCantos())
        ]));
  }

  getCantos() {
//    bool numeracao2015 = globals.prefs.getBool("numeracao2015") ?? false;
    if (globals.listaGlobal != null && globals.listaGlobal.length > 0)
      return Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: (!editMode)
            ? ListView(children: <Widget>[
                for (final item in globals.listaGlobal)
                  InkWell(
                      onTap: () => Get.to(CantoPage(canto: item)).then((value) => {setState(() {})}),
                      child: Stack(
                        children: <Widget>[
                          ListTile(
                            leading: ClipOval(
                                child: Material(
                                    color: getColorCateg(item.categoria), // button color
                                    child: Container(
                                        height: 40,
                                        width: 40,
                                        child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text(item.nr2019)))))),
                            title: Text(item.titulo),
                          ),
                          Divider(color: Colors.black26, height: 1)
                        ],
                      )),
              ])
            : ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  var temp = globals.listaGlobal[oldIndex];
                  globals.listaGlobal.removeAt(oldIndex);
                  if (oldIndex > newIndex) {
                    globals.listaGlobal.insert(newIndex, temp);
                  } else {
                    globals.listaGlobal.insert(newIndex - 1, temp);
                  }
                  setState(() {});
                },
                children: <Widget>[
                    for (final item in globals.listaGlobal)
                      Dismissible(
                        key: Key(item.id.toString()),
                        background: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Remover Canto', style: TextStyle(color: globals.darkRed)),
                            Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.delete, color: globals.darkRed)),
                          ],
                        ),
                        onDismissed: (direction) => setState(() {
                          globals.listaGlobal.removeWhere((element) => element.id == item.id);
                        }),
                        direction: DismissDirection.endToStart,
                        child: Stack(children: <Widget>[
                          ListTile(title: Text(item.titulo)),
                          Divider(color: Colors.black26, height: 1)
                        ]),
                      ),
                  ]),
      );
    else
      return InkWell(
          onTap: () => Get.to(HomePage(selectable: true)).then((result) => setState(() {
                editMode = true;
              })),
          child: Center(child: Padding(padding: EdgeInsets.all(10), child: Text('Adicionar Cantos'))));
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

  salvarLista() async {
    if (formKey.currentState.saveAndValidate()) {
      listaNew.cantos = [];
      globals.listaGlobal.forEach((element) {
        listaNew.cantos.add(element.id);
      });
      CantoListService().saveList(listaOld: listaOld, listaNew: listaNew);
      snackBar('Lista Salva');
      listaOld = listaNew.titulo;
    }
  }

  deleteList() {
    return Get.defaultDialog(
        title: 'Apagar Lista?',
        radius: 4,
        content: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.6),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(listaOld, textAlign: TextAlign.center),
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
                              CantoListService().saveList(listaOld: listaOld);
                              Navigator.of(context).pop();
                              Get.back();
                            },
                          )),
                    ],
                  ),
                ],
              ),
            )));
  }
}