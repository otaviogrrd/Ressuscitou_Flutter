import "package:flutter/material.dart";
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import "package:get/get.dart";

import "../helpers/global.dart";
import "../model/canto.dart";
import "../pages/canto.dart";

class LiturgicoPage extends StatefulWidget {
  @override
  _LiturgicoPageState createState() => _LiturgicoPageState();
}

class _LiturgicoPageState extends State<LiturgicoPage> {
  List<Canto> listCantos = [];
  List<bool> expanded = [false, false, false, false, false, false, false, false, false, false, false, false, false];

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Índice Litúrgico"), centerTitle: false),
      body: FutureBuilder(
          future: CantoService().getCantosLocal(),
          builder: (BuildContext cont, AsyncSnapshot<List<Canto>> snapshot) {
            if (snapshot.hasData) {
              listCantos = snapshot.data;
              return listaCantos();
            } else
              return Center(child: CircularProgressIndicator());
          }),
    );
  }

  listaCantos() {
    if (listCantos != null) {
      return SingleChildScrollView(
        child: TreeView(
          nodes: [
            getparent(0, "ADVENTO"),
            getparent(1, "LAUDES - VÉSPERAS"),
            getparent(2, "CANTOS DE ENTRADA"),
            getparent(3, "NATAL"),
            getparent(4, "QUARESMA"),
            getparent(5, "PÁSCOA"),
            getparent(6, "PENTECOSTES"),
            getparent(7, "CANTOS À VIRGEM"),
            getparent(6, "CANTOS PARA AS CRIANÇAS"),
            getparent(9, "PAZ - APRESENTAÇÃO DAS OFERENDAS"),
            getparent(10, "FRAÇÃO DO PÃO"),
            getparent(11, "COMUNHÃO"),
            getparent(12, "CANTO FINAL"),
          ],
        ),
      );
    }
    return Container();
  }

  getparent(int index, String text) {
    return TreeNode(

      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ListTile(
            dense: true,
            onTap: () => setState(() => expanded[index] = !expanded[index]),
            //leading: expanded[index]
            //    ? Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onBackground)
            //    : Icon(Icons.keyboard_arrow_up, color: Theme.of(context).colorScheme.onBackground),
            title: Text(text, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
      ),
      children: expanded[index] ? filtrar(index) : null,
    );
  }

  List<TreeNode> filtrar(int index) {
    List<TreeNode> widgets = [];

    List<Canto> filterListCantos = [];

    if (index == 0) filterListCantos = listCantos.where((c) => (c.adve)).toList();
    if (index == 1) filterListCantos = listCantos.where((c) => (c.laud)).toList();
    if (index == 2) filterListCantos = listCantos.where((c) => (c.entr)).toList();
    if (index == 3) filterListCantos = listCantos.where((c) => (c.nata)).toList();
    if (index == 4) filterListCantos = listCantos.where((c) => (c.quar)).toList();
    if (index == 5) filterListCantos = listCantos.where((c) => (c.pasc)).toList();
    if (index == 6) filterListCantos = listCantos.where((c) => (c.pent)).toList();
    if (index == 7) filterListCantos = listCantos.where((c) => (c.virg)).toList();
    if (index == 8) filterListCantos = listCantos.where((c) => (c.cria)).toList();
    if (index == 9) filterListCantos = listCantos.where((c) => (c.cpaz)).toList();
    if (index == 10) filterListCantos = listCantos.where((c) => (c.fpao)).toList();
    if (index == 11) filterListCantos = listCantos.where((c) => (c.comu)).toList();
    if (index == 12) filterListCantos = listCantos.where((c) => (c.cfin)).toList();
    filterListCantos.forEach((element) {
      widgets.add(
        TreeNode(
          content: InkWell(
            onTap: () => Get.to(() => CantoPage(canto: element)).then((value) => {setState(() {})}),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              child: ListTile(
                dense: true,
                //contentPadding: EdgeInsets.only(left: 16, right: 10),
                leading: ClipOval(
                    child: Material(
                  color: getColorCateg(element.categoria), // button color
                  child: SizedBox(
                    width: 35,
                    height: 35,
                    child: Center(
                        child: Text(
                      element.nr2019,
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    )),
                  ),
                )),
                title: Text(
                  element.titulo,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                trailing: geticon(element),
              ),
            ),
          ),
        ),
      );
    });
    return widgets;
  }

  geticon(Canto canto) {
    if (canto.url != "") {
      if (canto.downloaded != null && canto.downloaded)
        return Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary);
      else
        return Icon(Icons.music_note, color: Colors.grey);
    } else
      return Icon(Icons.music_note, color: Colors.transparent);
  }
}
