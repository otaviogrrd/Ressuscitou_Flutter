import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:ressuscitou/helpers/global.dart";
import "package:ressuscitou/model/cantoList.dart";
import "package:ressuscitou/pages/listaDetalhe.dart";

class ListasPage extends StatefulWidget {
  int select;

  ListasPage({Key key, this.select}) : super(key: key);

  @override
  _ListasPageState createState() => _ListasPageState();
}

class _ListasPageState extends State<ListasPage> {
  bool listasLoaded = false;
  List<CantoList> listCantos = [];

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Listas"), centerTitle: false),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          elevation: 1,
          onPressed: () => Get.to(ListaDetalhePage(
                lista: CantoList(titulo: "", cantos: (widget.select != null) ? [widget.select] : []),
              )).then((value) => setState(() => listasLoaded = false))),
      body: getBody(),
    );
  }

  getBody() {
    if (listasLoaded)
      return listaCantos();
    else
      return FutureBuilder(
          future: CantoListService().getCantosList(),
          builder: (BuildContext cont, AsyncSnapshot<List<CantoList>> snapshot) {
            if (snapshot.hasData) {
              listCantos = snapshot.data;
              listasLoaded = true;
              return listaCantos();
            } else
              return Center(child: CircularProgressIndicator());
          });
  }

  listaCantos() {
    if (listCantos != null && listCantos.isNotEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                  itemCount: listCantos.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        if (widget.select != null) {
                          listCantos[index].cantos.remove(widget.select);
                          listCantos[index].cantos.add(widget.select);
                          CantoListService().saveList(listaOld: listCantos[index].titulo, listaNew: listCantos[index]);
                          Get.back();
                          snackBar(Get.overlayContext, "Canto adicionado à lista");
                        } else {
                          Get.to(ListaDetalhePage(lista: listCantos[index]))
                              .then((value) => setState(() => listasLoaded = false));
                        }
                      },
                      child: Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(title: Text(listCantos[index].titulo))),
                    );
                  }),
            ),
          ],
        ),
      );
    }
    return Center(child: Text("Não há Listas salvas."));
  }
}
