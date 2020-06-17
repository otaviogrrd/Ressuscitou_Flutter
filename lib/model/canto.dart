import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Canto(
      {int id,
      String titulo,
      String html,
      String url,
      int categoria,
      String numero,
      String nr2019,
      bool adve,
      bool laud,
      bool entr,
      bool nata,
      bool quar,
      bool pasc,
      bool pent,
      bool virg,
      bool cria,
      bool cpaz,
      bool fpao,
      bool comu,
      bool cfin,
      String conteudo,
      String htmlBase64,
      String extBase64}) {
    this.id = id;
    this.titulo = titulo;
    this.html = html;
    this.url = url;
    this.categoria = categoria;
    this.numero = numero;
    this.nr2019 = nr2019;
    this.adve = adve;
    this.laud = laud;
    this.entr = entr;
    this.nata = nata;
    this.quar = quar;
    this.pasc = pasc;
    this.pent = pent;
    this.virg = virg;
    this.cria = cria;
    this.cpaz = cpaz;
    this.fpao = fpao;
    this.comu = comu;
    this.cfin = cfin;
    this.conteudo = conteudo;
    this.htmlBase64 = htmlBase64;
    this.extBase64 = extBase64;
  }

  factory Canto.fromJson(Map<String, dynamic> json) {
    return Canto(
      id: json['id'],
      categoria: json['categoria'],
      adve: json['adve'],
      laud: json['laud'],
      entr: json['entr'],
      nata: json['nata'],
      quar: json['quar'],
      pasc: json['pasc'],
      pent: json['pent'],
      virg: json['virg'],
      cria: json['cria'],
      cpaz: json['cpaz'],
      fpao: json['fpao'],
      comu: json['comu'],
      cfin: json['cfin'],
      numero: json['numero'],
      nr2019: json['nr_2019'],
      conteudo: json['conteudo'],
      htmlBase64: json['html_base64'],
      extBase64: json['ext_base64'],
      titulo: json['titulo'],
      html: json['html'],
      url: json['url'],
    );
  }
}

class CantoService {
  final String urlCantos = "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/cantos.json";

  Future<List<Canto>> getCantos() async {
    final prefs = await SharedPreferences.getInstance();
    Response res = await get(urlCantos);
    if (res.statusCode == 200) {
      prefs.setString('listCatos', res.body);
      List<dynamic> body = jsonDecode(res.body);
      List<Canto> list = body.map((dynamic item) => Canto.fromJson(item)).toList();
      return list;
    }
    throw 'Não retornou informações';
  }

  Future<List<Canto>> getCantosLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String str = prefs.getString('listCatos');
    if (str != null) {
      List<dynamic> body = jsonDecode(str);
      List<Canto> list = body.map((dynamic item) => Canto.fromJson(item)).toList();
      return list;
    }
    throw 'Não retornou informações';
  }
}
