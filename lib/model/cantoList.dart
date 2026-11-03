import "dart:convert";
import "../helpers/global.dart";

class CantoList {
  String titulo;
  List<int> cantos;

  CantoList({this.titulo = "", List<int>? cantos}) : cantos = cantos ?? [];

  factory CantoList.fromJson(Map<String, dynamic> json) {
    List<dynamic> body = json["cantos"] ?? [];
    var cantos = body.map((dynamic item) => item).toList();
    var canto = CantoList(titulo: json["titulo"] ?? "", cantos: []);
    cantos.forEach((element) {
      canto.cantos.add(element);
    });

    return canto;
  }

  Map<String, dynamic> toJson() => {
        "titulo": this.titulo,
        "cantos": cantos.toList(),
      };
}

class CantoListService {
  Future<void> saveList({String? listaOld, CantoList? listaNew}) async {
    List<CantoList> list = [];
    String str = globals.prefs.getString("Listas") ?? "";
    if (str.isNotEmpty) {
      List<dynamic> body = jsonDecode(str);
      list = body.map((dynamic item) => CantoList.fromJson(item)).toList();
    }
    list.removeWhere((element) => element.titulo == listaOld);
    if (listaNew != null) list.add(listaNew);
    str = jsonEncode(list);
    await globals.prefs.setString("Listas", str);
  }

  Future<List<CantoList>> getCantosList() async {
    String str = globals.prefs.getString("Listas") ?? "";
    if (str.isNotEmpty) {
      List<dynamic> body = jsonDecode(str);
      List<CantoList> list = body.map((dynamic item) => CantoList.fromJson(item)).toList();
      return list;
    }
    return [];
  }
}
