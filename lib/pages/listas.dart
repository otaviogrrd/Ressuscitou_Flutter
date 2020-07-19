import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/model/cantoList.dart';
import 'package:ressuscitou/pages/listaDetalhe.dart';

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
    return WillPopScope(
        onWillPop: () {
          Navigator.pop(context, false);
          return Future.value(false);
        },
        child: Scaffold(
          appBar: AppBar(title: Text('Listas'), centerTitle: false),
          floatingActionButton: FloatingActionButton(
              child: Icon(Icons.add),
              elevation: 1,
              onPressed: () => Get.to(ListaDetalhePage(
                    lista: CantoList(titulo: '', cantos: (widget.select != null) ? [widget.select] : []),
                  )).then((value) => setState(() => listasLoaded = false))),
          body: getBody(),
        ));
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
      return Column(
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
                        snackBar('Canto adicionado à lista');
                      } else {
                        Get.to(ListaDetalhePage(lista: listCantos[index]))
                            .then((value) => setState(() => listasLoaded = false));
                      }
                    },
                    child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(title: Text(listCantos[index].titulo))),
                  );
                }),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Não há Listas salvas."),
        )
      ],
    );
  }
}
