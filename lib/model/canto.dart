import "dart:convert";
import "dart:io";

import "package:connectivity_plus/connectivity_plus.dart";
import 'package:flutter/services.dart';
import "package:http/http.dart";
import "package:path_provider/path_provider.dart";
import "../helpers/global.dart";
import "../helpers/catalog_corrections.dart";

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
  String conteudo;
  String htmlBase64;
  String extBase64;
  String titulo;
  String html;
  String url;
  bool downloaded;
  bool selected;
  String fileSize = "";
  String filePath = "";
  double percentDownload = 0;
  bool playing = false;

  Canto({
    this.id = 0,
    this.titulo = "",
    this.html = "",
    this.url = "",
    this.categoria = 0,
    this.numero = "",
    this.adve = false,
    this.laud = false,
    this.entr = false,
    this.nata = false,
    this.quar = false,
    this.pasc = false,
    this.pent = false,
    this.virg = false,
    this.cria = false,
    this.cpaz = false,
    this.fpao = false,
    this.comu = false,
    this.cfin = false,
    this.conteudo = "",
    this.htmlBase64 = "",
    this.extBase64 = "",
    this.downloaded = false,
    this.selected = false,
  });

  static String _readNumber(Map<String, dynamic> json) {
    for (final key in ['nr_2026', 'nr_2019', 'numero']) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  factory Canto.fromJson(Map<String, dynamic> json) {
    return Canto(
      id: json["id"] ?? 0,
      titulo: json["titulo"] ?? "",
      html: json["html"] ?? "",
      url: json["url"] ?? "",
      categoria: json["categoria"] ?? 0,
      // Legacy catalogs used numero for the old edition. Prefer the newest
      // edition field when present; new catalogs only need numero.
      numero: _readNumber(json),
      adve: json["adve"] ?? false,
      laud: json["laud"] ?? false,
      entr: json["entr"] ?? false,
      nata: json["nata"] ?? false,
      quar: json["quar"] ?? false,
      pasc: json["pasc"] ?? false,
      pent: json["pent"] ?? false,
      virg: json["virg"] ?? false,
      cria: json["cria"] ?? false,
      cpaz: json["cpaz"] ?? false,
      fpao: json["fpao"] ?? false,
      comu: json["comu"] ?? false,
      cfin: json["cfin"] ?? false,
      conteudo: json["conteudo"] ?? "",
      htmlBase64: json["html_base64"] ?? "",
      extBase64: json["ext_base64"] ?? "",
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

  Future<void> mp3Downloaded() async {
    downloaded = false;
    if (url != "X") return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$html.mp3");
    filePath = file.path;
    downloaded = await file.exists();
    if (downloaded) fileSize = "${((await file.length()) / 1000000).toStringAsFixed(2)}mb";
  }

  Future<void> mp3Delete() async {
    if (filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) await file.delete();
    downloaded = false;
  }
}

class CantoService {
  static Future<Map<String, int>>? _portalCategories;
  static Future<Map<String, dynamic>>? _reviewedHtml;

  static void applyReviewedHtmlCorrections(List<Canto> cantos, Map<String, dynamic> songs) {
    for (final canto in cantos) {
      final rules = songs[canto.html];
      if (rules is! Map<String, dynamic>) continue;
      final normal = rules['html_base64'];
      final extended = rules['ext_base64'];
      if (normal is Map<String, dynamic>) canto.htmlBase64 = applyReviewedHtmlPatches(canto.htmlBase64, normal);
      if (extended is Map<String, dynamic>) canto.extBase64 = applyReviewedHtmlPatches(canto.extBase64, extended);
    }
  }


  static void applyPortalCategories(List<Canto> cantos, Map<String, int> categories) {
    for (final canto in cantos) {
      final category = categories[canto.html];
      if (category != null && category >= 1 && category <= 4) canto.categoria = category;
    }
  }

  Future<void> _applyPortalCategories(List<Canto> cantos) async {
    final categories = await (_portalCategories ??= rootBundle
        .loadString('assets/portal_metadata.json')
        .then((text) {
          final data = jsonDecode(text) as Map<String, dynamic>;
          return (data['categoryOverrides'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value as int));
        }));
    applyPortalCategories(cantos, categories);
    final reviewed = await (_reviewedHtml ??= rootBundle
        .loadString('assets/reviewed_html_corrections.json')
        .then((text) => (jsonDecode(text) as Map<String, dynamic>)['songs'] as Map<String, dynamic>));
    applyReviewedHtmlCorrections(cantos, reviewed);
  }

  final String urlCantos = "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/cantos.json";
  final String urlCantosVersao =
      "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/cantos_versao.txt";

  Future<List<Canto>> getCantos() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        globals.cantosGlobal = await getCantosLocal();
        return globals.cantosGlobal;
      }
      Response response = await get(Uri.parse(urlCantosVersao)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        int cantosVersaoLocal = (globals.prefs.getInt("cantosVersao") ?? 56);
        int cantosVersao = int.parse(response.body);
        if (cantosVersaoLocal < cantosVersao) {
          Response res = await get(Uri.parse(urlCantos)).timeout(const Duration(seconds: 30));
          if (res.statusCode == 200) {
            List<dynamic> body = jsonDecode(res.body);
            List<Canto> list = body.map((dynamic item) => Canto.fromJson(item)).toList();
    await _applyPortalCategories(list);
            for (var i = 0; i < list.length; i++) {
              await list[i].mp3Downloaded();
            }
            globals.cantosGlobal = list;
            globals.prefs.setInt("cantosVersao", cantosVersao);
            globals.prefs.setString("listCantos", jsonEncode(list.map((i) => i.toJson()).toList()).toString());
            return list;
          }
        }else{
          globals.prefs.setInt("cantosVersao", cantosVersaoLocal);
        }
      }
    } catch (_) {
      globals.cantosGlobal = await getCantosLocal();
      return globals.cantosGlobal;
    }
    globals.cantosGlobal = await getCantosLocal();
    return globals.cantosGlobal;
  }

  Future<List<Canto>> getCantosLocal() async {
    String str = globals.prefs.getString("listCantos") ?? await rootBundle.loadString("assets/cantos.json");


    List<dynamic> body = jsonDecode(str);
    List<Canto> list = body.map((dynamic item) => Canto.fromJson(item)).toList();
    await _applyPortalCategories(list);
    for (var i = 0; i < list.length; i++) {
      await list[i].mp3Downloaded();
    }
    globals.cantosGlobal = list;
    return list;
  }
}
