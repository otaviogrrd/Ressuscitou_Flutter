import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/model/canto.dart';
import 'package:ressuscitou/pages/canto.dart';

import '../helpers/global.dart';
import 'sobre.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Canto> listCantos = [];

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Ressuscitou')),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              ListTile(
                  title: Text("Ajuda"),
                  leading: Icon(Icons.help_outline, color: globals.darkRed),
                  onTap: () {
                    Get.to(SobrePage());
                  }),
              ListTile(
                  title: Text("Sobre"),
                  leading: Icon(Icons.subdirectory_arrow_right, color: globals.darkRed),
                  onTap: () {
                    Get.to(SobrePage());
                  })
            ],
          ),
        ),
        body: getBody());
  }

  getBody() {
//    return Column(children: [
//      InkWell(
//          onTap: () {},
//          child: Container(
//            height: 50,
//            margin: EdgeInsets.only(top: 35, left: 8, right: 8),
//            child: Center(child: Text('Índice Alfabético')),
//            decoration:
//                BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(4)), color: Colors.black12),
//          ))
//    ]);
    return FutureBuilder(
        future: CantoService().getCantos(),
        builder: (BuildContext cont, AsyncSnapshot<List<Canto>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return getCantosLocal();
            case ConnectionState.done:
              if (snapshot.hasData) listCantos = snapshot.data;
              return getCantosLocal();
            default:
              if (snapshot.hasError) snackBar('Erro: ${snapshot.error}');
              return getCantosLocal();
          }
        });
  }

  listaCantos() {
    if (listCantos != null)
      return ListView.builder(
          itemCount: listCantos.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => Get.to(CantoPage(canto: listCantos[index])),
              child: Card(child: ListTile(title: Text(listCantos[index].titulo))),
            );
          });
    return Container();
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
}
