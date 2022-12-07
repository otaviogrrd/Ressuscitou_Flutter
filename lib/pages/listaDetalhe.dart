import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:get/get.dart";
import "package:ressuscitou/helpers/global.dart";
import "package:ressuscitou/model/cantoList.dart";
import "package:ressuscitou/pages/canto.dart";
import "package:ressuscitou/pages/home.dart";
import "package:share/share.dart";

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

  navigateOption(String value) {
    if (value == "1") setState(() => editMode = !editMode);
    if (value == "2") setState(() => salvarLista());
    if (value == "3") deleteList();
    if (value == "4") {
      String share = "";
      globals.listaGlobal.forEach((element) {
        share = share + element.nr2019.padLeft(3, "0") + " - " + element.titulo + "\n";
      });
      Share.share("Confira a lista *${listaNew.titulo}*, que criei no App *Ressucitou*:\n\n$share");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(elevation: 0.0, centerTitle: false, title: Text("Lista"), actions: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              child: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.secondary),
              onSelected: (value) => navigateOption(value),
              itemBuilder: (BuildContext context) {
                return [
                  if (!editMode) PopupMenuItem(value: "1", child: Text("Editar")),
                  if (editMode) PopupMenuItem(value: "2", child: Text("Salvar")),
                  PopupMenuItem(value: "3", child: Text("Excluir")),
                  PopupMenuItem(value: "4", child: Text("Compartilhar")),
                ];
              },
            ),
          ),
//          if (listaOld != "") IconButton(icon: Icon(Icons.delete), onPressed: () => deleteList()),
//          (editMode)
//              ? IconButton(
//                  icon: Icon(Icons.save),
//                  onPressed: () => setState(() {
//                        salvarLista();
//                      }))
//              : IconButton(icon: Icon(Icons.edit), onPressed: () => setState(() => editMode = !editMode)),
        ]),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.help, color: Theme.of(context).colorScheme.primary),
            mini: true,
            elevation: 1,
            onPressed: () {
              getHelp();
//              Share.share("Confira a lista *${listaNew.titulo}*, que criei no App *Ressucitou*:\n\n$share");
            }),
        body: Container(
            margin: EdgeInsets.symmetric(horizontal: 11),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: FormBuilder(
                    key: formKey,
                    enabled: editMode,
                    child: Column(children: [
                      FormBuilderTextField(
                          cursorColor: Theme.of(context).colorScheme.primary,
                          name: "Título",
                          initialValue: listaOld,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 2,
                          textInputAction: TextInputAction.go,
                          onChanged: (value) {
                            listaNew.titulo = value;
                          },
                          validator: FormBuilderValidators.required(context, errorText: "Informe um título para lista!"),
                          decoration: InputDecoration(
                            labelText: "Título",
                          ))
                    ])),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Container(height: 1, color: (!editMode) ? Theme.of(context).colorScheme.primary : Colors.transparent)),
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
            onTap: (editMode) ? () => Get.to(() => HomePage(selectable: true)).then((result) => setState(() {})) : () {},
            child: Container(
              height: 45,
              decoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2))),
              child: Stack(children: [
                Center(
                    child: Text(
                  "Cantos",
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w500),
                )),
                if (editMode && globals.listaGlobal.length > 0)
                  Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 25),
                      ))
              ]),
            ),
          ),
          Expanded(child: getCantos())
        ]));
  }

  getCantos() {
    if (globals.listaGlobal != null && globals.listaGlobal.length > 0)
      return Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: (!editMode)
            ? ListView(children: [
                for (final item in globals.listaGlobal)
                  InkWell(
                      onTap: () => Get.to(() => CantoPage(canto: item)).then((value) => {setState(() {})}),
                      child: Stack(
                        children: [
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
                                                child: Text(
                                                  item.nr2019,
                                                  style: TextStyle(color: Colors.black),
                                                )))))),
                            title: Text(item.titulo),
                          ),
                          Divider(color: Theme.of(context).colorScheme.onBackground, height: 1)
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
                children: [
                    for (final item in globals.listaGlobal)
                      Dismissible(
                        key: Key(item.id.toString()),
                        background: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("Remover Canto", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                        onDismissed: (direction) => setState(() {
                          globals.listaGlobal.removeWhere((element) => element.id == item.id);
                        }),
                        direction: DismissDirection.endToStart,
                        child: Stack(
                            children: [ListTile(title: Text(item.titulo)), Divider(color: Theme.of(context).colorScheme.onBackground, height: 1)]),
                      ),
                  ]),
      );
    else
      return InkWell(
          onTap: () => Get.to(() => HomePage(selectable: true)).then((result) => setState(() {
                editMode = true;
                if (globals.listaGlobal.isNotEmpty && (globals.prefs.getBool("mostraDicaLista") ?? true)) getHelp();
              })),
          child: Center(child: Padding(padding: EdgeInsets.all(10), child: Text("Adicionar Cantos"))));
  }

  salvarLista() async {
    if (formKey.currentState.saveAndValidate()) {
      listaNew.cantos = [];
      globals.listaGlobal.forEach((element) {
        listaNew.cantos.add(element.id);
      });
      CantoListService().saveList(listaOld: listaOld, listaNew: listaNew);
      Get.back();
      snackBar(Get.overlayContext, "Lista Salva");
      listaOld = listaNew.titulo;
    }
  }

  deleteList() {
    return Get.defaultDialog(
      title: "Apagar Lista?",
      radius: 4,
      content: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.6),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(listaOld, textAlign: TextAlign.center),
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
              CantoListService().saveList(listaOld: listaOld);
              Navigator.of(context).pop();
              Get.back();
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

  getHelp() async {
    globals.prefs.setBool("mostraDicaLista", false);
    Get.defaultDialog(
      title: "Dica",
      radius: 4,
      content: Column(children: [
        Container(
          constraints: BoxConstraints(minHeight: 100, maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: SingleChildScrollView(
              child: Column(
            children: [
              Text("No modo de edição:"),
              SizedBox(height: 15),
              Text("Você pode remover um canto da lista arrastando-o para o lado.\n"
                  "E também reordenar a lista segurando e movendo para cima ou para baixo."),
            ],
          )),
        ),
      ]),
      confirm: Container(
        width: 100,
        child: FlatButton(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Fechar")),
            color: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
    );
  }
}
