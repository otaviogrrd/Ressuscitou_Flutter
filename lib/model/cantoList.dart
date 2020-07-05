import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ressuscitou/model/canto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CantoList {
  String titulo;
  List<int> cantos = [];

  CantoList({this.titulo, this.cantos});

  factory CantoList.fromJson(Map<String, dynamic> json) {
    List<dynamic> body = json['cantos'];
    var cantos = body.map((dynamic item) => item).toList();
    var canto = CantoList(titulo: json['titulo'], cantos: []);
    cantos.forEach((element) {
      canto.cantos.add(element);
    });

    return canto;
  }

  Map<String, dynamic> toJson() => {
        'titulo': this.titulo,
        "cantos": cantos.toList(),
      };
}

class CantoListService {
  saveList({String listaOld, CantoList listaNew}) async {
    final prefs = await SharedPreferences.getInstance();
    List<CantoList> list = [];
    String str = prefs.getString('Listas');
    if (str != null && str != "") {
      List<dynamic> body = jsonDecode(str);
      list = body.map((dynamic item) => CantoList.fromJson(item)).toList();
    }
    list.removeWhere((element) => element.titulo == listaOld);
    if (listaNew != null) list.add(listaNew);
    str = jsonEncode(list);
    prefs.setString('Listas', str);
  }

  Future<List<CantoList>> getCantosList() async {
    final prefs = await SharedPreferences.getInstance();
    String str = prefs.getString('Listas');
    if (str != null && str != "") {
      List<dynamic> body = jsonDecode(str);
      List<CantoList> list = body.map((dynamic item) => CantoList.fromJson(item)).toList();
      return list;
    }
    return [];
  }
}
