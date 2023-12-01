import 'dart:convert';

import 'package:ressuscitou/model/cantoList.dart';

class CantosConfig {
  int cantoId;
  int trans;
  int capot;
  String anota;

  CantosConfig({
    this.cantoId,
    this.trans,
    this.capot,
    this.anota,
  });

  factory CantosConfig.fromJson(Map<String, dynamic> json) {
    return CantosConfig(
      cantoId: json["cantoId"],
      trans: json["trans"],
      capot: json["capot"],
      anota: json["anota"],
    );
  }

  Map<String, dynamic> toJson() => {
        "cantoId": this.cantoId,
        "trans": this.trans,
        "capot": this.capot,
        "anota": this.anota,
      };
}

class Configuracoes {
  List<CantoList> listas = [];
  List<CantosConfig> cantos = [];

  Configuracoes({
    this.listas,
    this.cantos,
  });

  factory Configuracoes.fromJson(Map<String, dynamic> json) {
    List<dynamic> listas = json["listas"];
    List<dynamic> cantos = json["cantos"];

    var config = Configuracoes(listas: [], cantos: []);

    listas.forEach((element) {
      String encode = jsonEncode(element);
      CantoList lista = CantoList.fromJson(jsonDecode(encode));
      config.listas.add(lista);
    });

    cantos.forEach((element) {
      String encode = jsonEncode(element);
      CantosConfig cantoConf = CantosConfig.fromJson(jsonDecode(encode));
      config.cantos.add(cantoConf);
    });

    return config;
  }

  Map<String, dynamic> toJson() => {
        "listas": listas.toList(),
        "cantos": cantos.toList(),
      };
}
