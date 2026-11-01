import "dart:async";

import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:intl/intl.dart";
import "package:url_launcher/url_launcher.dart" as launcher;

import "../helpers/global.dart";
import "../helpers/canto_search.dart";
import "../widgets/canto_search_results.dart";
import "../model/canto.dart";
import '../model/mensagem.dart';
import "../pages/audios.dart";
import '../pages/canto.dart';
import "../pages/imageViewer.dart";
import "../pages/listas.dart";
import "../pages/liturgico.dart";
import '../pages/mensagens.dart';
import "../pages/settings.dart";
import "sobre.dart";

class HomePage extends StatefulWidget {
  final bool selectable;

  HomePage({Key? key, required this.selectable}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Canto> listCantos = [];
  late Future<List<Canto>> _cantosFuture;
  CantoSearchIndex _searchIndex = CantoSearchIndex([]);
  List<Canto> filterListCantos = [];
  Map<Canto, CantoSearchResult> _searchResults = {};
  int selectedCateg = 0;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String searchField = "";
  bool showSearch = false;
  bool requestFocus = false;
  FocusNode searchFocus = FocusNode();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cantosFuture = CantoService().getCantosLocal();
    Timer.run(() { if (mounted) getTermo(); });
  }

  void _refreshCantos() {
    if (!mounted) return;
    setState(() {
      _cantosFuture = CantoService().getCantosLocal();
    });
  }

  @override
  void dispose() {
    searchFocus.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    globals.tablet = isTablet(MediaQuery.of(context));
    return Scaffold(
      appBar: AppBar(title: Image.asset("assets/img/logo.png", color: Colors.white, height: 30), actions: [
        if (!showSearch) IconButton(icon: Icon(Icons.search, size: 25), onPressed: () => setState(() => showSearch = requestFocus = true)),
      ]),
      drawer: (globals.tablet)
          ? null
          : (widget.selectable)
              ? null
              : Drawer(child: getMenuLateral()),
      body: getCantosLocal(),
    );
  }

  getTermo() async {
    var termos = globals.prefs.getBool("TermosIniciaisLidos") ?? false;
    if (!termos)
      Get.defaultDialog(
        title: "Atenção",
        radius: 4,
        content: Column(
          children: [
            Container(
              constraints: BoxConstraints(minHeight: 100, maxHeight: MediaQuery.of(context).size.height * 0.3),
              child: SingleChildScrollView(
                child: Table(
                  children: [
                    TableRow(children: [
                      Text("Este aplicativo NÃO deve ser utilizado em celebrações.", style: TextStyle(fontSize: 16), textAlign: TextAlign.center)
                    ]),
                    TableRow(children: [SizedBox(height: 15)]),
                    TableRow(children: [
                      Text("Pode ser utilizado apenas como apoio aos salmistas para ensaios, consultas e preparações.", textAlign: TextAlign.center)
                    ]),
                    TableRow(children: [SizedBox(height: 15)]),
                  ],
                ),
              ),
            ),
            Container(
              width: 100,
              child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text("Entendi")),
                  onPressed: () {
                    globals.prefs.setBool("TermosIniciaisLidos", true);
                    Navigator.pop(context);
                  }),
            ),
          ],
        ),
      );

    var msgTablet = globals.prefs.getBool("msgTabletLida") ?? false;
    var screenDiagonal = globals.prefs.getBool("screenDiagonal") ?? false;
    if (!msgTablet && screenDiagonal)
      Get.defaultDialog(
        title: "Modo tablet",
        radius: 4,
        content: Column(
          children: [
            Container(
              constraints: BoxConstraints(minHeight: 100, maxHeight: MediaQuery.of(context).size.height * 0.3),
              child: SingleChildScrollView(
                child: Table(
                  children: [
                    TableRow(children: [
                      Text("Identificamos que este aparelho é um Tablet.", style: TextStyle(fontSize: 16), textAlign: TextAlign.center)
                    ]),
                    TableRow(children: [
                      Text("Você pode desabilitar este modo de visualização no menu Opções.", textAlign: TextAlign.center)
                    ]),
                    TableRow(children: [SizedBox(height: 15)]),
                  ],
                ),
              ),
            ),
            Container(
              width: 100,
              child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text("Entendi")),
                  onPressed: () {
                    globals.prefs.setBool("msgTabletLida", true);
                    Navigator.pop(context);
                  }),
            ),
          ],
        ),
      );

    DateTime messageLida = DateTime.parse(globals.prefs.getString("MessageLida") ?? "1800-01-01");
    if (messageLida.isBefore(DateTime.parse(DateFormat("yyyy-MM-dd").format(DateTime.now())))) {
      getMessage(apenasHoje: true);
    }
  }

  getMessage({bool apenasHoje = false}) async {
    List<Mensagem> mensagens = await MensagemService().getMensagens(apenasHoje: apenasHoje);
    if (mensagens.isNotEmpty)
      Get.defaultDialog(
          title: "Mensagem",
          radius: 4,
          content: Column(children: [
            Container(
              constraints: BoxConstraints(minHeight: 100, maxHeight: MediaQuery.of(context).size.height * 0.3),
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  for (final item in mensagens)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(item.titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Text(item.conteudo, style: TextStyle(fontSize: 15)),
                        SizedBox(height: 30)
                      ],
                    ),
                ],
              )),
            ),
            Container(
              width: 100,
              child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text("Fechar")),
                  onPressed: () {
                    globals.prefs.setString("MessageLida", DateFormat("yyyy-MM-dd").format(DateTime.now()));
                    Navigator.pop(context);
                  }),
            ),
          ]));
  }

  listaCantos() {
    filtrar();
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.selectable)
                if (globals.tablet)
                  Container(
                    width: 275,
                    decoration: BoxDecoration(border: Border(right: BorderSide(width: 1, color: Theme.of(context).colorScheme.onSurface))),
                    child: getMenuLateral(),
                  ),
              Expanded(
                  child: Column(
                children: [
                  if (showSearch) searchInput(),
                  Expanded(
                    child: ListView.builder(
                        itemCount: filterListCantos.length,
                        itemBuilder: (context, index) {
                          final row = InkWell(
                            onTap: () => Get.to(() => CantoPage(canto: filterListCantos[index]))?.then((value) => _refreshCantos()),
                            child: (widget.selectable)
                                ? CheckboxListTile(
                                    subtitle: _searchSubtitle(filterListCantos[index]),
                                    dense: true,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (value) => setState(() {
                                      filterListCantos[index].selected = value ?? false;
                                      final canto = filterListCantos[index];
                                      if (value == true) {
                                        if (!globals.listaGlobal.any((item) => item.id == canto.id)) {
                                          globals.listaGlobal.add(canto);
                                        }
                                      } else {
                                        globals.listaGlobal.removeWhere((item) => item.id == canto.id);
                                      }
                                    }),
                                    checkColor: checkDarkMode(context) ? Theme.of(context).colorScheme.primary : null,
                                    activeColor:
                                        checkDarkMode(context) ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.primary,
                                    value: filterListCantos[index].selected,
                                    title: Row(
                                      children: [
                                        ClipOval(
                                            child: Material(
                                                color: getColorCateg(filterListCantos[index].categoria), // button color
                                                child: Container(
                                                    height: 40,
                                                    width: 40,
                                                    child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Padding(
                                                          padding: EdgeInsets.all(8),
                                                          child: Text(
                                                            filterListCantos[index].nr2019,
                                                            style: TextStyle(color: Colors.black),
                                                          ),
                                                        ))))),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Text(
                                              filterListCantos[index].titulo,
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListTile(
                                    subtitle: _searchSubtitle(filterListCantos[index]),
                                    dense: true,
                                    contentPadding: EdgeInsets.only(left: 16, right: 10),
                                    leading: ClipOval(
                                        child: Material(
                                            color: getColorCateg(filterListCantos[index].categoria), // button color
                                            child: Container(
                                                height: 40,
                                                width: 40,
                                                child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Padding(
                                                      padding: EdgeInsets.all(8),
                                                      child: Text(
                                                        filterListCantos[index].nr2019,
                                                        style: TextStyle(color: Colors.black),
                                                      ),
                                                    ))))),
                                    title: Text(
                                      filterListCantos[index].titulo,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    trailing: geticon(filterListCantos[index]),
                                  ),
                          );
                          return CantoSearchResultGroup(
                            result: _searchResults[filterListCantos[index]],
                            previousResult: index == 0 ? null : _searchResults[filterListCantos[index - 1]],
                            child: row,
                          );
                        }),
                  ),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }

  geticon(Canto canto) {
    if (canto.url != "") {
      if (canto.downloaded)
        return Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary);
      else
        return Icon(Icons.music_note, color: Colors.grey);
    } else
      return Icon(Icons.music_note, color: Colors.transparent);
  }

  getCantosLocal() {
    return FutureBuilder(
        future: _cantosFuture,
        builder: (BuildContext cont, AsyncSnapshot<List<Canto>> snapshot) {
          if (snapshot.hasData) {
            if (!identical(listCantos, snapshot.data)) {
              listCantos = snapshot.data!;
              _searchIndex = CantoSearchIndex(listCantos);
            }
            return listaCantos();
          } else
            return Center(child: CircularProgressIndicator());
        });
  }

  Widget divider() {
    return Padding(
      padding: EdgeInsets.fromLTRB(5, 2, 0, 2),
      child: Divider(color: Theme.of(context).colorScheme.onSurface, height: 2.0),
    );
  }

  getMenuLateral() {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        ListView(
          children: [
            if (!globals.tablet)
              Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Image.asset("assets/img/logo.png", height: 30),
              )),
            if (!globals.tablet) divider(),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(child: Text("Todos Cantos", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11))),
            ),
            ListTile(
                title: Text("Ordem Alfabética"),
                leading: Icon(Icons.sort_by_alpha, size: 25, color: Theme.of(context).colorScheme.primary),
                onTap: () => setState(() => selectCateg(0))),
//            ListTile(
//                title: Padding(
//                  padding: EdgeInsets.only(left: 40),
//                  child: Text("Ordem Alfabética", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                ),
//                onTap: () => setState(() => selectCateg(0))),
            ListTile(
                title: Text("Índice Litúrgico"),
                leading: Icon(Icons.account_tree, size: 25, color: Theme.of(context).colorScheme.primary),
//                title: Padding(
//                  padding: EdgeInsets.only(left: 40),
//                  child: Text("Índice Litúrgico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                ),
                onTap: () {
                  if (!globals.tablet) Navigator.of(context).pop();
                  Get.to(() => LiturgicoPage())?.then((value) => _refreshCantos());
                }),
            divider(),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(child: Text("Filtrar Etapa", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11))),
            ),
            ListTile(
                title: Text("Pré-Catecumenato"),
                leading: ClipOval(
                  child: Material(
                    color: getColorCateg(1), // button color
                    child: SizedBox(width: 25, height: 25),
                  ),
                ),
                onTap: () => setState(() => selectCateg(1))),
            ListTile(
                title: Text("Litúrgicos"),
                leading: ClipOval(
                  child: Material(
                    color: getColorCateg(4), // button color
                    child: SizedBox(width: 25, height: 25),
                  ),
                ),
                onTap: () => setState(() => selectCateg(4))),
            ListTile(
                title: Text("Catecumenato"),
                leading: ClipOval(
                  child: Material(
                    color: getColorCateg(2), // button color
                    child: SizedBox(width: 25, height: 25),
                  ),
                ),
                onTap: () => setState(() => selectCateg(2))),
            ListTile(
                title: Text("Eleição"),
                leading: ClipOval(
                  child: Material(
                    color: getColorCateg(3), // button color
                    child: SizedBox(width: 25, height: 25),
                  ),
                ),
                onTap: () => setState(() => selectCateg(3))),
            divider(),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(child: Text("Imagens", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11))),
            ),
            ListTile(
                leading: Icon(Icons.line_style, size: 25, color: Theme.of(context).colorScheme.primary),
                title: Text("Acordes"),
                onTap: () {
                  Get.to(() => ImageViwerPage(img: "assets/img/acordes.jpg", title: "Acordes"))?.then((value) => _refreshCantos());
                }),
            ListTile(
                title: Text("Arpejos"),
                leading: Icon(Icons.timeline, size: 25, color: Theme.of(context).colorScheme.primary),
                onTap: () {
                  Get.to(() => ImageViwerPage(img: "assets/img/arpejos.jpg", title: "Arpejos"))?.then((value) => _refreshCantos());
                }),
            divider(),
            ListTile(
                title: Text("Listas"),
                leading: Icon(Icons.list, size: 25, color: Theme.of(context).colorScheme.primary),
                onTap: () => Get.to(() => ListasPage())?.then((value) => _refreshCantos())),
            ListTile(
                title: Text("Áudios"),
                leading: Icon(Icons.music_note, size: 25, color: Theme.of(context).colorScheme.primary),
                onTap: () => Get.to(() => AudiosPage())?.then((value) => _refreshCantos())),
            ListTile(
                title: Text("Mensagens"),
                leading: Icon(Icons.message_outlined, size: 25, color: Theme.of(context).colorScheme.primary),
                onTap: () => Get.to(() => MensagensPage())),
            divider(),
            ListTile(
                title: Text("Descubra seu Tom"),
                leading: Icon(Icons.call_made, size: 25, color: Theme.of(context).colorScheme.primary),
                onTap: () => launchUrl()),
            divider(),
            ListTile(
                title: Text("Opções"),
                leading: Icon(Icons.settings, size: 25, color: Theme.of(context).colorScheme.primary),
                onTap: () => Get.to(() => SettingsPage())?.then((value) => _refreshCantos())),
            ListTile(
                title: Text("Sobre"),
                leading: Icon(Icons.info_outline, size: 25, color: Theme.of(context).colorScheme.primary),
                onTap: () => Get.to(() => SobrePage()))
          ],
        ),
        (globals.tablet)
            ? Container()
            : Container(height: statusBarHeight, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer)),
      ],
    );
  }

  selectCateg(int i) {
    selectedCateg = i;
    if (!globals.tablet) Navigator.of(context).pop();
  }

  searchInput() {
    Widget ret = Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Stack(
        children: [
          Form(
              key: formKey,
              child: Column(children: [
                TextFormField(
                    cursorColor: Theme.of(context).colorScheme.primary,

                    focusNode: searchFocus,
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.go,
                    controller: searchController,
                    onChanged: (value) {
                      setState(() => searchField = value);
                    },
                    decoration: InputDecoration(labelText: "Pesquisar"))
              ])),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                if (searchField != "") {
                  searchField = "";
                  searchController.text = "";
                } else
                  showSearch = false;
                setState(() {});
              },
              child: Container(
                  margin: EdgeInsets.all(5),
                  child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ))),
            ),
          ),
        ],
      ),
    );
    if (requestFocus) FocusScope.of(context).requestFocus(searchFocus);
    requestFocus = false;
    return ret;
  }

  Widget? _searchSubtitle(Canto canto) {
    final result = _searchResults[canto];
    return result?.snippet == null ? null : CantoSearchSnippet(result: result!, query: searchField);
  }

  void filtrar() {
    final results = _searchIndex.searchResults(searchField, category: selectedCateg);
    _searchResults = {for (final result in results) result.canto: result};
    filterListCantos = results.map((result) => result.canto).toList();
    if (widget.selectable) {
      final selectedIds = globals.listaGlobal.map((canto) => canto.id).toSet();
      for (final canto in filterListCantos) {
        canto.selected = selectedIds.contains(canto.id);
      }
    }
  }

  launchUrl() async {
    const url = "http://neo-transposer.com/";
    launcher.launchUrl(Uri.parse(url)).then(
      (bool isLaunch) {
        if (isLaunch) {
        } else {
          snackBar(Get.overlayContext, "Erro ao abrir navegador");
        }
      },
      onError: (e) {
        snackBar(Get.overlayContext, "Erro ao abrir navegador");
      },
    ).catchError(
      (ex) {
        snackBar(Get.overlayContext, "Erro ao abrir navegador");
      },
    );
  }
}
