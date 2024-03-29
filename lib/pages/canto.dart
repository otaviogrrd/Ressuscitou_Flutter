import "dart:async";
import "dart:convert";
import "dart:io";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:dio/dio.dart";
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "package:get/get.dart";
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import "package:numberpicker/numberpicker.dart";
import "package:path_provider/path_provider.dart";
import 'package:percent_indicator/circular_percent_indicator.dart';
import "package:percent_indicator/linear_percent_indicator.dart";
import "../helpers/global.dart";
import "../helpers/player_widget.dart";
import "../model/canto.dart";
import "../pages/listas.dart";
import "package:wakelock/wakelock.dart";
import "package:webview_flutter/webview_flutter.dart";

class CantoPage extends StatefulWidget {
  final Canto canto;

  CantoPage({Key key, @required this.canto}) : super(key: key);

  @override
  _CantoPageState createState() => _CantoPageState();
}

class _CantoPageState extends State<CantoPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final ctrlAnotacoes = TextEditingController();
  WebViewController webViewController;
  bool exibePlayer = false;
  String localFilePath = "";
  String strCanto;
  int scroll = 0;
  int hasTransp = 0;
  int transSalv = 0;
  int capotSalv = 0;
  int capoSelected = 0;
  double percentDownload = 0;
  bool estendido = false;
  bool downloading = false;
  bool darktheme = false;
  int brightnessStage = 0;
  bool brightnessAuto = true;
  bool brightnessChange = false;
  Color back;

  @override
  void initState() {
    Wakelock.enable();
    estendido = globals.prefs.getBool("estendido") ?? true;
    super.initState();
  }

  navigateOption(String value) {
    if (value == "1") Get.to(() => ListasPage(select: widget.canto.id)).then((value) => setState(() {}));
    if (value == "2") anotacoes();
  }

  @override
  Widget build(BuildContext context) {
    if (brightnessAuto) {
      if (darktheme != checkDarkMode(context)) {
          if (webViewController != null)
            Timer(Duration(milliseconds: 10), () {
              transpor();
              webViewController.loadUrl(Uri.dataFromString(strCanto, mimeType: "text/html", encoding: Encoding.getByName("utf-8")).toString());
              brightnessChange = false;
              setState(() {});
            });
      }
      darktheme = checkDarkMode(context);
    } else {
      if (webViewController != null) {
        if (brightnessChange) {
          Timer(Duration(milliseconds: 10), () {
            transpor();
            webViewController.loadUrl(Uri.dataFromString(strCanto, mimeType: "text/html", encoding: Encoding.getByName("utf-8")).toString());
            brightnessChange = false;
            setState(() {});
          });
        }
      }
    }

    if (widget.canto.categoria == 1) back = darktheme ? hexToColor("#333333") : hexToColor("#ffffff");
    if (widget.canto.categoria == 2) back = darktheme ? hexToColor("#282b2e") : hexToColor("#c7d7e8");
    if (widget.canto.categoria == 3) back = darktheme ? hexToColor("#2b3325") : hexToColor("#d6ffba");
    if (widget.canto.categoria == 4) back = darktheme ? hexToColor("#33291f") : hexToColor("#FFCC99");

    transpor();

    return WillPopScope(
      onWillPop: () {
        Wakelock.disable();
        scroll = 0;
        Navigator.pop(context, false);
        return Future.value(false);
      },
      child: Scaffold(
          backgroundColor: back,
          appBar: AppBar(
              // elevation: 0,
              actions: (globals.tablet)
                  ? []
                  : [
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: PopupMenuButton<String>(
                          child: Icon(Icons.more_vert),
                          onSelected: (value) => navigateOption(value),
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem(value: "1", child: Text("Adicionar à lista")),
                              PopupMenuItem(value: "2", child: Text("Anotações")),
                            ];
                          },
                        ),
                      ),
                    ]),
          floatingActionButton: (globals.tablet)
              ? null
              : SpeedDial(
                  closeManually: true,
                  animatedIcon: AnimatedIcons.menu_close,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  elevation: 2,
                  curve: Curves.easeIn,
                  overlayOpacity: 0,
                  children: [
                      SpeedDialChild(
                          elevation: 2,
                          child: Center(
                              child: Container(
                            height: 40,
                            width: 40,
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("Transp", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary))),
                          )),
                          onTap: () => getTraspDialog(),
                          backgroundColor: Theme.of(context).colorScheme.secondary),
                      SpeedDialChild(
                        elevation: 2,
                        child: Center(
                            child: Container(
                          height: 40,
                          width: 40,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("Capo", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary))),
                        )),
                        onTap: () => getCapoDialog(),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                      SpeedDialChild(
                          elevation: 2,
                          child: Stack(
                            children: [
                              Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Center(child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSecondary))),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 2),
                                  child: Center(child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSecondary))),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 14),
                                  child: Center(child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSecondary))),
                              if (scroll > 0)
                                Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                        height: 15,
                                        width: 40,
                                        child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child:
                                                Text(scroll.toString() + "x", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary))))),
                            ],
                          ),
                          onTap: () async {
                            if (await webViewController.canScrollVertically()) setState(() => setTimer());
                          },
                          backgroundColor: Theme.of(context).colorScheme.secondary),
                      if (widget.canto.url != "")
                        SpeedDialChild(
                            elevation: 2,
                            child: (widget.canto.downloaded)
                                ? Icon(Icons.music_note, color: Theme.of(context).colorScheme.onSecondary)
                                : Stack(children: [
                                    Center(
                                        child: Padding(
                                      padding: EdgeInsets.only(bottom: 5, right: 10),
                                      child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.onSecondary),
                                    )),
                                    Center(
                                        child: Padding(
                                      padding: EdgeInsets.only(left: 10, top: 5),
                                      child: Icon(Icons.file_download, size: 20, color: Theme.of(context).colorScheme.onSecondary),
                                    )),
                                  ]),
                            onTap: () => _loadFile(),
                            backgroundColor: Theme.of(context).colorScheme.secondary),
                      SpeedDialChild(
                          elevation: 2,
                          child: brightnessAuto
                              ? Stack(children: [
                                  Center(
                                      child: Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: Icon(MdiIcons.themeLightDark, size: 18, color: Theme.of(context).colorScheme.onSecondary),
                                  )),
                                  Center(
                                      child: Padding(
                                    padding: EdgeInsets.only(top: 17),
                                    child: Text("Auto", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary)),
                                  )),
                                ])
                              : Icon((darktheme ? MdiIcons.brightness4 : MdiIcons.brightness5), color: Theme.of(context).colorScheme.onSecondary),
                          onTap: () {
                            if (brightnessStage == 2) {
                              brightnessAuto = true;
                              brightnessStage = 0;
                            } else {
                              if (brightnessStage == 0 || brightnessStage == 1) {
                                brightnessAuto = false;
                                brightnessStage++;
                              }
                            }
                            if (!brightnessAuto) {
                              darktheme = !darktheme;
                            }
                            brightnessChange = true;
                            setState(() {});
                          },
                          backgroundColor: Theme.of(context).colorScheme.secondary),
                    ]),
          body: getBody()),
    );
  }

  getBody() {
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: Container(
                margin: EdgeInsets.all(5),
                child: Column(
                  children: [
                    if (exibePlayer)
                      Card(
                          child: PlayerWidget(
                        url: localFilePath,
                        canto: widget.canto,
                      )),
                    if (percentDownload > 0 && percentDownload < 1 && !globals.tablet)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearPercentIndicator(
                          lineHeight: 20.0,
                          percent: percentDownload,
                          center: FittedBox(fit: BoxFit.scaleDown, child: Text("${(percentDownload * 100).toInt()}%")),
                          linearStrokeCap: LinearStrokeCap.butt,
                          progressColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    Expanded(
                      child: WebView(
                        onWebViewCreated: (WebViewController controller) {
                          webViewController = controller;
                        },
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                          new Factory<OneSequenceGestureRecognizer>(
                            () => new EagerGestureRecognizer(),
                          ),
                        ].toSet(),
                        initialUrl: Uri.dataFromString(strCanto, mimeType: "text/html", encoding: Encoding.getByName("utf-8")).toString(),
                        gestureNavigationEnabled: true,
                      ),
                    ),
                  ],
                ),
              )),
              if (globals.tablet)
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      border: Border(left: BorderSide(width: 1, color: Theme.of(context).colorScheme.onBackground))),
                  child: getMenuLateral(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget divider() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Divider(color: Theme.of(context).colorScheme.onBackground, height: 2),
    );
  }

  getMenuLateral() {
    return ListView(
      children: [
        InkWell(
          child: Container(
            height: 60,
            child: Icon(Icons.playlist_add, size: 25, color: Theme.of(context).colorScheme.onSecondary),
          ),
          onTap: () => navigateOption("1"),
        ),
        divider(),
        InkWell(
          child: Container(
            height: 60,
            child: Icon(MdiIcons.commentEditOutline, size: 25, color: Theme.of(context).colorScheme.onSecondary),
          ),
          onTap: () => navigateOption("2"),
        ),
        divider(),
        InkWell(
          child: Container(
            height: 60,
            child: FittedBox(
                fit: BoxFit.scaleDown, child: Text("Transposição", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary))),
          ),
          onTap: () => getTraspDialog(),
        ),
        divider(),
        InkWell(
          child: Container(
            height: 60,
            child: FittedBox(
                fit: BoxFit.scaleDown, child: Text("Capotraste", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary))),
          ),
          onTap: () => getCapoDialog(),
        ),
        divider(),
        InkWell(
          child: Container(
            height: 60,
            child: Stack(
              children: [
                Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSecondary))),
                Padding(
                    padding: EdgeInsets.all(0),
                    child: Center(child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSecondary))),
                Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSecondary))),
                if (scroll > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 24, left: 45),
                    child: Container(
                        height: 25,
                        width: 50,
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(scroll.toString() + "x", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)))),
                  ),
              ],
            ),
          ),
          onTap: () async {
            if (await webViewController.canScrollVertically()) setState(() => setTimer());
          },
        ),
        if (widget.canto.url != "") divider(),
        if (widget.canto.url != "")
          InkWell(
            onTap: () => _loadFile(),
            child: Container(
              height: 60,
              width: 60,
              child: (widget.canto.downloaded)
                  ? Icon(Icons.music_note, color: Theme.of(context).colorScheme.onSecondary)
                  : (percentDownload > 0 && percentDownload < 1)
                      ? Container(
                          height: 60,
                          width: 60,
                          child: CircularPercentIndicator(
                            radius: 30.0,
                            lineWidth: 2,
                            percent: percentDownload,
                            center: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                child: Text(
                                  "${(percentDownload * 100).toInt()}%",
                                ),
                              ),
                            ),
                            progressColor: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Stack(children: [
                          Center(
                              child: Padding(
                            padding: EdgeInsets.only(bottom: 5, right: 10),
                            child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.onSecondary),
                          )),
                          Center(
                              child: Padding(
                            padding: EdgeInsets.only(left: 10, top: 5),
                            child: Icon(Icons.file_download, size: 20, color: Theme.of(context).colorScheme.onSecondary),
                          )),
                        ]),
            ),
          ),
        divider(),
        InkWell(
          onTap: () {
            if (brightnessStage == 2) {
              brightnessAuto = true;
              brightnessStage = 0;
            } else {
              if (brightnessStage == 0 || brightnessStage == 1) {
                brightnessAuto = false;
                brightnessStage++;
              }
            }
            if (!brightnessAuto) {
              darktheme = !darktheme;
            }
            brightnessChange = true;
            setState(() {});
          },
          child: Container(
            height: 60,
            width: 60,
            child: brightnessAuto
                ? Stack(children: [
                    Center(
                        child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Icon(MdiIcons.themeLightDark, size: 18, color: Theme.of(context).colorScheme.onSecondary),
                    )),
                    Center(
                        child: Padding(
                      padding: EdgeInsets.only(top: 17),
                      child: Text("Auto", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary)),
                    )),
                  ])
                : Icon((darktheme ? MdiIcons.brightness4 : MdiIcons.brightness5), color: Theme.of(context).colorScheme.onSecondary),
          ),
        ),
        divider(),
      ],
    );
  }

  setTimer() {
    scroll++;
    Timer.periodic(Duration(milliseconds: 200), (timer) async {
      if (!(await webViewController.canScrollVertically())) {
        setState(() => scroll = 0);
        return;
      }
      if (scroll == 0) timer.cancel();
      webViewController.scrollBy(0, 1);
    });
  }

  void transpor() {
    LineSplitter ls = new LineSplitter();
    int numero = 0;

    transSalv = globals.prefs.getInt("TRANSP_" + widget.canto.id.toString()) ?? 0;
    capotSalv = globals.prefs.getInt("CAPOT_" + widget.canto.id.toString()) ?? 0;

    if (estendido)
      strCanto = utf8.decode(base64.decode(widget.canto.extBase64));
    else
      strCanto = utf8.decode(base64.decode(widget.canto.htmlBase64));

    List<String> content = ls.convert(strCanto);

    if (hasTransp != 0)
      numero = hasTransp;
    else
      numero = transSalv;

    List<String> escalaTmp = globals.escalaTmp;
    List<String> escalaEuropeia = globals.escalaEuropeia;
    List<String> escalaAmericana = globals.escalaAmericana;
    List<String> escalaMenos = globals.escalaMenos;
    List<String> escalaMenor = globals.escalaMenor;
    List<String> escala = escalaEuropeia;

    if (globals.prefs.getBool("escalaAmericana") ?? false) escala = escalaAmericana;

    int pri = 99;
    int dif = 0;

    for (var c = 0; c < content.length; c++) {
      if (content[c].contains("font-size:12px")) {
        int fonte = (globals.prefs.getInt("tamanhoFonte") ?? 15);
        if (Platform.isIOS) fonte = fonte + 8;
        content[c] = content[c].replaceAll("12px", " ${fonte}px !important");
      }

      if (darktheme) if (content[c].contains("background-color:")) {
        content[c] = content[c].replaceAll("background-color: #FFFFFF", " background-color: #333333");
        content[c] = content[c].replaceAll("background-color: #c7d7e8", " background-color: #282b2e");
        content[c] = content[c].replaceAll("background-color: #d6ffba", " background-color: #2b3325");
        content[c] = content[c].replaceAll("background-color: #FFCC99", " background-color: #33291f");
      }

      if (content[c].contains("<H1>")) {
        if (darktheme) if (content[c].contains("#FF0000")) {
          content[c] = content[c].replaceAll("#FF0000", "#ff6666");
        }
        continue;
      }

      if (darktheme) if (content[c].contains("#000000")) {
        content[c] = content[c].replaceAll("#000000", "#e6e6e6");
      }
      if (!content[c].contains("FF0000")) {
        if (content[c].contains("@transp@")) {
          if (transSalv != 0 || numero > 0) {
            if (darktheme) {
              if (transSalv != 0) content[c] = "<FONT COLOR=\"#e8ccf9\">Salvo Transposição: " + escalaTmp[transSalv] + "  </FONT>";
              if (numero > 0 && numero != transSalv) content[c] += "<FONT COLOR=\"#ccd5f9\">Transposição: " + escalaTmp[numero] + "  </FONT>";
            } else {
              if (transSalv != 0) content[c] = "<FONT COLOR=\"#8a00e0\">Salvo Transposição: " + escalaTmp[transSalv] + "  </FONT>";
              if (numero > 0 && numero != transSalv) content[c] += "<FONT COLOR=\"#002de0\">Transposição: " + escalaTmp[numero] + "  </FONT>";
            }

            pri = 98;
          } else {
            continue;
          }
        } else if (content[c].contains("@capot@")) {
          if (capotSalv != 0) {
            if (darktheme) {
              content[c] = "<FONT COLOR=\"#e8ccf9\">Salvo Capotraste: " + capotSalv.toString() + "ª</FONT>";
            } else {
              content[c] = "<FONT COLOR=\"#8a00e0\">Salvo Capotraste: " + capotSalv.toString() + "ª</FONT>";
            }
            pri = 98;
          } else {
            continue;
          }
        } else {
          continue;
        }
      }

      if (darktheme) if (content[c].contains("#FF0000")) {
        content[c] = content[c].replaceAll("#FF0000", "#ff6666");
      }

      content[c] = content[c].replaceAll("Do#", escalaTmp[2]).replaceAll("Fa#", escalaTmp[7]).replaceAll("Sol#", escalaTmp[9]);
      for (int i = 0; i < escalaTmp.length; i++) {
        content[c] = content[c].replaceAll(escalaEuropeia[i], escalaTmp[i]);
      }
      if (pri == 99) {
        String x = "@";
        for (int i = 0; i < content[c].length; i++) {
          if (content[c].codeUnitAt(i) == x.codeUnitAt(0)) {
            pri = int.parse(content[c].substring(i + 1, i + 3));
            if (numero != 0) {
              dif = (numero - pri).abs();
            }
            break;
          }
        }
      }
      if (pri == 99) {
        continue;
      }
      if (pri == 98) {
        pri = 99;
      }
      if ((pri > numero) && (!(dif == 0))) {
        for (int i = 12; i > 0; i--) {
          content[c] = content[c].replaceAll(escalaTmp[i], escala[(i + 12) - dif]);
        }
      }
      if ((pri < numero) && (!(dif == 0))) {
        for (int i = 0; i < escalaTmp.length; i++) {
          content[c] = content[c].replaceAll(escalaTmp[i], escala[i + dif]);
        }
      }
      if (((pri - numero) == 0) || (dif == 0)) {
        for (int i = 0; i < escalaTmp.length; i++) {
          content[c] = content[c].replaceAll(escalaTmp[i], escala[i]);
        }
      }
      for (int i = 0; i < escalaMenos.length; i++) {
        content[c] = content[c].replaceAll(escalaMenos[i], escalaMenor[i]);
      }
    }
    strCanto = "";
    content.forEach((c) {
      strCanto = strCanto + c + "\n";
    });
  }

  String getTextoNota(int i) {
    if (globals.prefs.getBool("escalaAmericana") ?? false)
      return globals.escalaAmericana[i];
    else
      return globals.escalaEuropeia[i];
  }

  getTraspDialog() {
    return Get.defaultDialog(
        title: "Transpor",
        radius: 4,
        content: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.6),
            child: Padding(
                padding: EdgeInsets.all(4),
                child: Table(children: [
                  TableRow(children: [
                    transporButton(01, getTextoNota(1)),
                    transporButton(02, getTextoNota(2)),
                  ]),
                  TableRow(children: [
                    transporButton(03, getTextoNota(3)),
                    transporButton(04, getTextoNota(4)),
                  ]),
                  TableRow(children: [
                    transporButton(05, getTextoNota(5)),
                    transporButton(06, getTextoNota(6)),
                  ]),
                  TableRow(children: [
                    transporButton(07, getTextoNota(7)),
                    transporButton(08, getTextoNota(8)),
                  ]),
                  TableRow(children: [
                    transporButton(09, getTextoNota(9)),
                    transporButton(10, getTextoNota(10)),
                  ]),
                  TableRow(children: [
                    transporButton(11, getTextoNota(11)),
                    transporButton(12, getTextoNota(12)),
                  ]),
                  if (hasTransp > 0 || transSalv > 0)
                    TableRow(children: [
                      (hasTransp > 0) ? transporSaveButton(hasTransp) : Container(),
                      transporSaveButton(0),
                    ])
                ]))));
  }

  Widget transporButton(int numero, String nota) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        width: 100,
        child: FlatButton(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(nota)),
            color: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () async {
              hasTransp = numero;
              transpor();
              //scroll = 0;
              webViewController.loadUrl(Uri.dataFromString(strCanto, mimeType: "text/html", encoding: Encoding.getByName("utf-8")).toString());
              setState(() {});
              Navigator.of(context).pop();
            }));
  }

  Widget transporSaveButton(int salvar) {
    return Container(
        margin: EdgeInsets.only(left: 8, right: 8, top: 20),
        width: 120,
        child: FlatButton(
            child: Icon((salvar > 0) ? Icons.save : Icons.delete, color: Theme.of(context).colorScheme.primary),
            color: Theme.of(context).colorScheme.secondary,
            onPressed: () async {
              (salvar > 0)
                  ? globals.prefs.setInt("TRANSP_" + widget.canto.id.toString(), salvar)
                  : globals.prefs.remove("TRANSP_" + widget.canto.id.toString());
              hasTransp = 0;
              transpor();
              //scroll = 0;
              webViewController.loadUrl(Uri.dataFromString(strCanto, mimeType: "text/html", encoding: Encoding.getByName("utf-8")).toString());
              setState(() {});
              Navigator.of(context).pop();
            }));
  }

  getCapoDialog() {
    int localSelection = capoSelected;
    return Get.defaultDialog(
        title: "Capotraste",
        radius: 4,
        content: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.6),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Align(
                          alignment: Alignment.center,
                          child: NumberPicker.integer(
                            initialValue: capoSelected,
                            highlightSelectedValue: false,
                            itemExtent: 45,
                            minValue: 0,
                            maxValue: 30,
                            onChanged: (value) {
                              if (value != localSelection) {
                                localSelection = value;
                              }
                            },
                          )),
                      Align(
                          alignment: Alignment.center,
                          child: Container(
                            margin: EdgeInsets.only(top: 57.5),
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.primary),
                            ),
                          )),
                    ],
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 12),
                      width: 100,
                      child: FlatButton(
                        child: FittedBox(fit: BoxFit.scaleDown, child: Text("Salvar")),
                        color: Theme.of(context).colorScheme.secondary,
                        textColor: Theme.of(context).colorScheme.onSecondary,
                        onPressed: () async {
                          await globals.prefs.setInt("CAPOT_" + widget.canto.id.toString(), localSelection);
                          capoSelected = localSelection;
                          transpor();
                          //scroll = 0;
                          webViewController
                              .loadUrl(Uri.dataFromString(strCanto, mimeType: "text/html", encoding: Encoding.getByName("utf-8")).toString());
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                      )),
                ],
              ),
            )));
  }

  Future _loadFile() async {
    if (exibePlayer) {
      exibePlayer = false;
      setState(() {});
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/" + widget.canto.html + ".mp3");
    if (await file.exists()) {
      setState(() {
        localFilePath = file.path;
      });
    }
    if (localFilePath != "") {
      exibePlayer = true;
      setState(() {});
      return;
    }

    bool wifiOnly = globals.prefs.getBool("wfOnly") ?? false;
    if (wifiOnly) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile) {
        snackBar(Get.overlayContext, "Uso de redes móveis não permitido nas configurações!");
        return;
      }
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      snackBar(Get.overlayContext, "Sem conexão de internet!");
      return;
    }
    if (!downloading) {
      downloading = true;
      snackBar(Get.overlayContext, "Iniciando download");
      var url = "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/audios/" + widget.canto.html + ".mp3";

      StreamController<int> progressStreamController = new StreamController();
      Dio dio = new Dio();
      dio.get(
        url,
        onReceiveProgress: (received, total) {
          progressStreamController.add(((received / total) * 100).round());
        },
        options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status < 500;
            }),
      ).then((response) async {
        file.writeAsBytes(response.data).then((value) {
          widget.canto.downloaded = true;
          localFilePath = file.path;
          exibePlayer = true;
          setState(() {});
        });
      }).whenComplete(() => progressStreamController.close());

      await for (int p in progressStreamController.stream) {
        setState(() {
          percentDownload = p / 100;
        });
      }
    }
  }

  anotacoes() {
    ctrlAnotacoes.text = globals.prefs.getString("ANOT_" + widget.canto.id.toString()) ?? "";
    Get.defaultDialog(
      title: "Anotações",
      radius: 4,
      middleText: "",
      content: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.6, maxHeight: MediaQuery.of(context).size.height * 0.3),
          child: Padding(
              padding: EdgeInsets.all(4),
              child: Column(children: [
                Expanded(
                  child: FormBuilder(
                    key: _formKey,
                    child: FormBuilderTextField(
                        cursorColor: Theme.of(context).colorScheme.primary,
                        name: "Anotacoes",
                        minLines: 10,
                        maxLines: 100,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.sentences,
                        controller: ctrlAnotacoes,
                        onSubmitted: (val) {
                          globals.prefs.setString("ANOT_" + widget.canto.id.toString(), ctrlAnotacoes.text);
                          Navigator.of(context).pop();
                        },
                        onChanged: (val) {
                          globals.prefs.setString("ANOT_" + widget.canto.id.toString(), ctrlAnotacoes.text);
                        }),
                  ),
                ),
              ]))),
      confirm: Container(
        margin: EdgeInsets.only(top: 15),
        width: 100,
        child: FlatButton(
            child: Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary),
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              globals.prefs.setString("ANOT_" + widget.canto.id.toString(), ctrlAnotacoes.text);
              Navigator.of(context).pop();
            }),
      ),
      cancel: Container(
        margin: EdgeInsets.only(top: 15),
        width: 100,
        child: FlatButton(
            child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onSecondary),
            color: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              globals.prefs.remove("ANOT_" + widget.canto.id.toString());
              Navigator.of(context).pop();
              snackBar(Get.overlayContext, "Anotação apagada!");
            }),
      ),
    );
  }
}
