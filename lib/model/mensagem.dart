import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import "package:intl/intl.dart";
import '../helpers/global.dart';

class Mensagem {
  String id;
  String plataforma;
  String titulo;
  String conteudo;
  String dataIni;
  String dataFim;
  int buildDe;
  int buildAte;
  late DateTime data_Ini;
  late DateTime data_Fim;

  Mensagem({
    this.id = "",
    this.plataforma = "",
    this.titulo = "",
    this.conteudo = "",
    this.dataIni = "",
    this.dataFim = "",
    this.buildDe = 0,
    this.buildAte = 0,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: json["id"] ?? "",
      plataforma: json["plataforma"] ?? "",
      titulo: json["titulo"] ?? "",
      conteudo: json["conteudo"] ?? "",
      dataIni: json["dataIni"] ?? "",
      dataFim: json["dataFim"] ?? "",
      buildDe: json["buildDe"] ?? 0,
      buildAte: json["buildAte"] ?? 0,
    );
  }
}

class MensagemService {
  final String urlMensagem = "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_flutter/master/mensagens.json";

  Future<List<Mensagem>> getMensagens({bool apenasHoje = false}) async {
    String str = "";
    str = globals.prefs.getString("Mensagens") ?? "";

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        final response = await get(Uri.parse(urlMensagem)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          str = response.body;
          await globals.prefs.setString("Mensagens", str);
        }
      }
    } catch (_) {
      // Keep the cached messages if the network is unavailable.
    }

    if (str != "") {
      List<dynamic> body = jsonDecode(str);
      List<Mensagem> list = body.map((dynamic item) => Mensagem.fromJson(item)).toList();

      String build = globals.packInfo.buildNumber;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        list.removeWhere((element) => element.plataforma == "Android");
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        list.removeWhere((element) => element.plataforma == "iOS");
        if (kReleaseMode) {
          if (build.length == 4) build = build.substring(1, 4); //em release temos as build 1???, 2???, e 4???: para cada tipo de android
        }
      }
      list.removeWhere((element) => element.buildDe > int.parse(build));
      list.removeWhere((element) => element.buildAte < int.parse(build));

      list.forEach((element) {
        element.data_Ini = DateFormat("yyyy-MM-dd").parse(element.dataIni);
        element.data_Fim = DateFormat("yyyy-MM-dd").parse(element.dataFim);
        element.conteudo = element.conteudo.replaceAll('\\n', '\n');
      });

      if (apenasHoje) {
        list.removeWhere((element) => element.data_Fim.isBefore(DateTime.now()));
        list.removeWhere((element) => element.data_Ini.isAfter(DateTime.now()));
      }

      return list;
    }
    return [];
  }
}
