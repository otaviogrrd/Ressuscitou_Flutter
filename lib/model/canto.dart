import "dart:convert";
import "dart:io";

import "package:connectivity_plus/connectivity_plus.dart";
import 'package:flutter/services.dart';
import "package:http/http.dart";
import "package:path_provider/path_provider.dart";
import "../helpers/global.dart";
import "../helpers/catalog_corrections.dart";

class CategoriaLiturgica {
  final String id;
  final String nome;
  final int ordem;
  const CategoriaLiturgica(this.id, this.nome, this.ordem);

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'ordem': ordem};
}

class Catalogo {
  final int? edicao;
  final List<CategoriaLiturgica> categorias;
  final List<Canto> cantos;
  Catalogo(this.edicao, this.categorias, this.cantos);

  // Fallback for the old bundled asset/cache only. New catalogs supply all labels.
  static const legadas = [
    CategoriaLiturgica('advento-natal', 'Advento - Natal', 1),
    CategoriaLiturgica('quaresma', 'Quaresma', 2),
    CategoriaLiturgica('pascoa-pentecostes', 'Páscoa - Pentecostes', 3),
    CategoriaLiturgica('virgem', 'Cantos à Virgem', 4),
    CategoriaLiturgica('criancas', 'Cantos para as crianças', 5),
    CategoriaLiturgica('entrada', 'Cantos de entrada', 6),
    CategoriaLiturgica('paz-oferendas', 'Paz - Apresentação das oferendas', 7),
    CategoriaLiturgica('fracao-pao', 'Fração do pão', 8),
    CategoriaLiturgica('comunhao-calice', 'Comunhão com o cálice', 9),
    CategoriaLiturgica('final', 'Canto final', 10),
  ];
  static const _legacyLinks = {
    'adve': 'advento-natal', 'nata': 'advento-natal',
    'quar': 'quaresma', 'pasc': 'pascoa-pentecostes',
    'pent': 'pascoa-pentecostes', 'virg': 'virgem',
    'cria': 'criancas', 'entr': 'entrada', 'cpaz': 'paz-oferendas',
    'fpao': 'fracao-pao', 'comu': 'comunhao-calice', 'cfin': 'final',
  };

  static List<String> readLinks(Map<String, dynamic> song) {
    if (song.containsKey('categorias')) {
      final links = song['categorias'];
      if (links is! List || links.any((id) => id is! String || id.trim().isEmpty)) {
        throw const FormatException('Categorias do canto devem ser uma lista de IDs.');
      }
      final result = links.cast<String>();
      if (result.toSet().length != result.length) {
        throw const FormatException('Vínculos litúrgicos duplicados.');
      }
      return List<String>.from(result);
    }
    return _legacyLinks.entries.where((e) => song[e.key] == true)
        .map((e) => e.value).toSet().toList();
  }

  factory Catalogo.fromJson(dynamic data) {
    final legacy = data is List;
    if (!legacy && data is! Map<String, dynamic>) {
      throw const FormatException('Raiz do catálogo inválida.');
    }
    final List<CategoriaLiturgica> groups;
    final List<dynamic> songs;
    int? edition;
    if (legacy) {
      groups = List.of(legadas);
      songs = data;
    } else {
      final root = data as Map<String, dynamic>;
      if (root['edicao'] is! int || root['categorias'] is! List || root['cantos'] is! List) {
        throw const FormatException('Catálogo requer edicao, categorias e cantos.');
      }
      edition = root['edicao'] as int;
      groups = [];
      for (final item in root['categorias'] as List) {
        if (item is! Map<String, dynamic> || item['id'] is! String ||
            (item['id'] as String).trim().isEmpty || item['nome'] is! String ||
            (item['nome'] as String).trim().isEmpty || item['ordem'] is! int) {
          throw const FormatException('Definição de categoria inválida.');
        }
        groups.add(CategoriaLiturgica(item['id'], item['nome'], item['ordem']));
      }
      if (groups.map((g) => g.id).toSet().length != groups.length ||
          groups.map((g) => g.ordem).toSet().length != groups.length) {
        throw const FormatException('IDs ou ordens de categorias duplicados.');
      }
      groups.sort((a, b) => a.ordem.compareTo(b.ordem));
      songs = root['cantos'] as List;
    }
    final ids = groups.map((g) => g.id).toSet();
    final parsed = <Canto>[];
    for (final song in songs) {
      if (song is! Map<String, dynamic> || (!legacy && song['categorias'] is! List)) {
        throw const FormatException('Canto inválido ou sem categorias.');
      }
      final canto = Canto.fromJson(song);
      if (canto.categorias.any((id) => !ids.contains(id))) {
        throw const FormatException('Canto vinculado a categoria inexistente.');
      }
      parsed.add(canto);
    }
    return Catalogo(edition, groups, parsed);
  }

  Map<String, dynamic> toJson() => {
    // A legacy cache is migrated to the object format without claiming 2026 review.
    'edicao': edicao ?? 0,
    'categorias': categorias.map((g) => g.toJson()).toList(),
    'cantos': cantos.map((c) => c.toJson()).toList(),
  };
}

class Canto {
  int id;
  int categoria;
  List<String> categorias;
  String numero;
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
    this.categorias = const [],
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
      categorias: Catalogo.readLinks(json),
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
        "categorias": this.categorias,
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
  static Catalogo? catalogoAtual;
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

  Future<void> _applyPortalCategories(List<Canto> cantos, {bool legacy = true}) async {
    final categories = await (_portalCategories ??= rootBundle
        .loadString('assets/portal_metadata.json')
        .then((text) {
          final data = jsonDecode(text) as Map<String, dynamic>;
          return (data['categoryOverrides'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value as int));
        }));
    if (legacy) applyPortalCategories(cantos, categories);
    final reviewed = await (_reviewedHtml ??= rootBundle
        .loadString('assets/reviewed_html_corrections.json')
        .then((text) => (jsonDecode(text) as Map<String, dynamic>)['songs'] as Map<String, dynamic>));
    applyReviewedHtmlCorrections(cantos, reviewed);
  }

  final String urlCantos = "https://raw.githubusercontent.com/otaviogrrd/ressucitou_geradorjson/main/cantos.json";
  final String urlCantosVersao =
      "https://raw.githubusercontent.com/otaviogrrd/ressucitou_geradorjson/main/cantos_versao.txt";

  Future<List<Canto>> getCantos() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        globals.cantosGlobal = await getCantosLocal();
        return globals.cantosGlobal;
      }
      Response response = await get(Uri.parse(urlCantosVersao)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        // A new source has its own version sequence. Do not compare it with
        // the old repository's version (e.g. 63).
        final sameSource = globals.prefs.getString('cantosFonte') == urlCantos;
        final cantosVersaoLocal = globals.prefs.getInt("cantosVersao") ?? -1;
        int cantosVersao = int.parse(response.body.trim());
        if (cantosVersao < 0) throw const FormatException("Versão de catálogo inválida.");
        if (!sameSource || globals.prefs.getString("listCantos") == null || cantosVersaoLocal < cantosVersao) {
          Response res = await get(Uri.parse(urlCantos)).timeout(const Duration(seconds: 30));
          if (res.statusCode == 200) {
            final catalogo = Catalogo.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
            final list = catalogo.cantos;
    await _applyPortalCategories(list, legacy: catalogo.edicao == null || catalogo.edicao == 0);
            for (var i = 0; i < list.length; i++) {
              await list[i].mp3Downloaded();
            }
            catalogoAtual = catalogo;
            globals.cantosGlobal = list;
            // Save data first. Mark the source/version only after the validated
            // catalog has been persisted, so failures can be retried.
            if (!await globals.prefs.setString("listCantos", jsonEncode(catalogo.toJson()))) {
              throw StateError('Não foi possível salvar o catálogo.');
            }
            await globals.prefs.setInt("cantosVersao", cantosVersao);
            await globals.prefs.setString('cantosFonte', urlCantos);
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


    final catalogo = Catalogo.fromJson(jsonDecode(str));
    final list = catalogo.cantos;
    catalogoAtual = catalogo;
    await _applyPortalCategories(list, legacy: catalogo.edicao == null || catalogo.edicao == 0);
    for (var i = 0; i < list.length; i++) {
      await list[i].mp3Downloaded();
    }
    globals.cantosGlobal = list;
    return list;
  }
}
