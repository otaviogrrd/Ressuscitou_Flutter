import "dart:convert";
import "dart:io";

import "package:connectivity/connectivity.dart";
import 'package:flutter/services.dart';
import "package:http/http.dart";
import "package:path_provider/path_provider.dart";
import "package:ressuscitou/helpers/global.dart";

class Canto {
  int id;
  int categoria;
  bool adve;
  bool laud;
  bool entr;
  bool nata;
  bool quar;
  bool pasc;
  bool pent;
  bool virg;
  bool cria;
  bool cpaz;
  bool fpao;
  bool comu;
  bool cfin;
  String numero;
  String nr2019;
  String conteudo;
  String htmlBase64;
  String extBase64;
  String titulo;
  String html;
  String url;
  bool downloaded = false;
  bool selected = false;
  String fileSize;
  String filePath;
  double percentDownload = 0;
  bool playing;

  Canto({
    this.id,
    this.titulo,
    this.html,
    this.url,
    this.categoria,
    this.numero,
    this.nr2019,
    this.adve,
    this.laud,
    this.entr,
    this.nata,
    this.quar,
    this.pasc,
    this.pent,
    this.virg,
    this.cria,
    this.cpaz,
    this.fpao,
    this.comu,
    this.cfin,
    this.conteudo,
    this.htmlBase64,
    this.extBase64,
    this.downloaded,
    this.selected,
  });

  factory Canto.fromJson(Map<String, dynamic> json) {
    return Canto(
      id: json["id"],
      titulo: json["titulo"],
      html: json["html"],
      url: json["url"],
      categoria: json["categoria"],
      numero: json["numero"],
      nr2019: json["nr_2019"],
      adve: json["adve"],
      laud: json["laud"],
      entr: json["entr"],
      nata: json["nata"],
      quar: json["quar"],
      pasc: json["pasc"],
      pent: json["pent"],
      virg: json["virg"],
      cria: json["cria"],
      cpaz: json["cpaz"],
      fpao: json["fpao"],
      comu: json["comu"],
      cfin: json["cfin"],
      conteudo: json["conteudo"],
      htmlBase64: json["html_base64"],
      extBase64: json["ext_base64"],
      downloaded: json["downloaded"] ?? false,
      selected: false,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": this.id,
        "titulo": this.titulo,
        "html": this.html,
        "url": this.url,
        "categoria": this.categoria,
        "numero": this.numero,
        "nr_2019": this.nr2019,
        "adve": this.adve,
        "laud": this.laud,
        "entr": this.entr,
        "nata": this.nata,
        "quar": this.quar,
        "pasc": this.pasc,
        "pent": this.pent,
        "virg": this.virg,
        "cria": this.cria,
        "cpaz": this.cpaz,
        "fpao": this.fpao,
        "comu": this.comu,
        "cfin": this.cfin,
        "conteudo": this.conteudo,
        "html_base64": this.htmlBase64,
        "ext_base64": this.extBase64,
        "downloaded": this.downloaded,
      };

  mp3Downloaded() async {
    if (this.url != "X") {
      this.downloaded = false;
      return;
    }
    await getApplicationDocumentsDirectory().then((dir) {
      final file = File("${dir.path}/" + this.html + ".mp3");
      file.exists().then((value) {
        this.filePath = file.path;
        this.downloaded = value;
        if (value) this.fileSize = (file.lengthSync() / 1000000).toStringAsFixed(2) + "mb";
      });
    });
  }

  mp3Delete() async {
    final file = File(this.filePath);
    file.exists().then((value) {
      file.delete();
    });
  }
}

class CantoService {
  final String urlCantos = "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/cantos.json";
  final String urlCantosVersao =
      "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/cantos_versao.txt";

  Future<List<Canto>> getCantos() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      globals.cantosGlobal = await getCantosLocal();
      return globals.cantosGlobal;
    }

    try {
      Response response = await get(urlCantosVersao);
      if (response.statusCode == 200) {
        int cantosVersaoLocal = (globals.prefs.getInt("cantosVersao") ?? 50);
        int cantosVersao = int.parse(response.body);
        if (cantosVersaoLocal < cantosVersao) {
          Response res = await get(urlCantos);
          if (res.statusCode == 200) {
            List<dynamic> body = jsonDecode(res.body);
            List<Canto> list = body.map((dynamic item) => Canto.fromJson(item)).toList();
            for (var i = 0; i < list.length; i++) {
              await list[i].mp3Downloaded();
            }
            globals.cantosGlobal = list;
            globals.prefs.setInt("cantosVersao", cantosVersao);
            globals.prefs.setString("listCantos", jsonEncode(list.map((i) => i.toJson()).toList()).toString());
            return list;
          }
        }
      }
    } catch (Exception) {
      globals.cantosGlobal = await getCantosLocal();
      return globals.cantosGlobal;
    }
    return [];
  }

  Future<List<Canto>> getCantosLocal() async {
    String str = globals.prefs.getString("listCantos");

    if (str == null) str = await rootBundle.loadString('assets/cantos.json');

    List<dynamic> body = jsonDecode(str);
    List<Canto> list = body.map((dynamic item) => Canto.fromJson(item)).toList();
    for (var i = 0; i < list.length; i++) {
      await list[i].mp3Downloaded();
    }
    globals.cantosGlobal = list;
    return list;
  }
}
