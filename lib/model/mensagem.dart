import "dart:async";
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import "package:intl/intl.dart";
import 'package:ressuscitou/helpers/global.dart';

class Mensagem {
  String id;
  String plataforma;
  String titulo;
  String conteudo;
  String dataIni;
  String dataFim;
  int buildDe;
  int buildAte;
  DateTime data_Ini;
  DateTime data_Fim;

  Mensagem({
    this.id,
    this.plataforma,
    this.titulo,
    this.conteudo,
    this.dataIni,
    this.dataFim,
    this.buildDe,
    this.buildAte,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: json["id"],
      plataforma: json["plataforma"],
      titulo: json["titulo"],
      conteudo: json["conteudo"],
      dataIni: json["dataIni"],
      dataFim: json["dataFim"],
      buildDe: json["buildDe"],
      buildAte: json["buildAte"],
    );
  }
}

class MensagemService {
  final String urlMensagem = "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_flutter/master/mensagens.json";

  Future<List<Mensagem>> getMensagens({bool apenasHoje = false}) async {
    String str = "";
    str = globals.prefs.getString("Mensagens") ?? "";

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      Response res = await get(urlMensagem);
      if (res.statusCode == 200) {
        str = res.body;
        globals.prefs.setString("Mensagens", str);
      }
    }

    if (str != "") {
      List<dynamic> body = jsonDecode(str);
      List<Mensagem> list = body.map((dynamic item) => Mensagem.fromJson(item)).toList();

      if (Theme.of(Get.overlayContext).platform == TargetPlatform.iOS)
        list.removeWhere((element) => element.plataforma == "Android");
      else
        list.removeWhere((element) => element.plataforma == "iOS");

      list.forEach((element) {
        element.data_Ini = DateFormat("yyyy-MM-dd").parse(element.dataIni);
        element.data_Fim = DateFormat("yyyy-MM-dd").parse(element.dataFim);
        element.conteudo = element.conteudo.replaceAll('\\n', '\n');
      });

      if (apenasHoje) {
        list.removeWhere((element) => element.buildDe > int.parse(globals.packInfo.buildNumber));
        list.removeWhere((element) => element.buildAte < int.parse(globals.packInfo.buildNumber));

        list.removeWhere((element) => element.data_Fim.isBefore(DateTime.now()));
        list.removeWhere((element) => element.data_Ini.isAfter(DateTime.now()));
      }

      return list;
    }
    return [];
  }
}
