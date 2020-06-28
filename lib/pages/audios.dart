import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/model/canto.dart';
import 'package:ressuscitou/pages/canto.dart';
import 'package:ressuscitou/pages/settings.dart';
import '../helpers/global.dart';
import 'sobre.dart';

class AudiosPage extends StatefulWidget {
  @override
  _AudiosPageState createState() => _AudiosPageState();
}

class _AudiosPageState extends State<AudiosPage> {
  bool cantosLoaded = false;
  List<Canto> listCantos = [];

  navigateOption(String value) async {
    if (value == '1') {
      var listaMarcada = listCantos.where((c) => (c.selected != null && c.selected)).toList();
      for (var i = 0; i < listaMarcada.length; i++) {
        await listaMarcada[i].mp3Delete();
      }
      cantosLoaded = false;
      setState(() {});
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ressuscitou'), actions: [
        if (listCantos.where((c) => (c.selected != null && c.selected)).toList().isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              child: Icon(Icons.more_vert),
              onSelected: (value) => navigateOption(value),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(value: '1', child: Text('Excluir Audios')),
                  PopupMenuItem(value: '2', child: Text('Reproduzir'))
                ];
              },
            ),
          ),
      ]),
      body: getBody(),
    );
  }

  getBody() {
    if (cantosLoaded)
      return listaCantos();
    else
      return FutureBuilder(
          future: CantoService().getCantosLocal(),
          builder: (BuildContext cont, AsyncSnapshot<List<Canto>> snapshot) {
            if (snapshot.hasData) {
              listCantos = snapshot.data.where((c) => (c.downloaded != null && c.downloaded)).toList();
              cantosLoaded = true;
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
                  return CheckboxListTile(
                      value: listCantos[index].selected,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) => setState(() {
                            listCantos[index].selected = !listCantos[index].selected;
                          }),
                      title:
                          Text(listCantos[index].titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
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
          child: Text("Não há arquivos baixados"),
        )
      ],
    );
  }
}
