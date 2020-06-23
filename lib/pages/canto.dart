import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:ressuscitou/model/canto.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../helpers/global.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../helpers/player_widget.dart';

class CantoPage extends StatefulWidget {
  final Canto canto;

  CantoPage({Key key, @required this.canto}) : super(key: key);

  @override
  _CantoPageState createState() => _CantoPageState();
}

class _CantoPageState extends State<CantoPage> {
  final GlobalKey<PlayerWidgetState> playerKey = GlobalKey<PlayerWidgetState>();
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  WebViewController webViewController;
  bool exibePlayer = false;
  String localFilePath = "";
  String strCanto;
  int scroll = 0;
  int transp = 0;
  double percentDownload = 0;

  Future _loadFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/' + widget.canto.html + '.mp3');
    if (await file.exists()) {
      setState(() {
        localFilePath = file.path;
      });
    }
    if (localFilePath == "") {
      snackBar('Iniciando download');
      var url = "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/audios/" +
          widget.canto.html +
          ".mp3";

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
      ).then((Response response) async {
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
    } else {
      exibePlayer = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    transpor(transp);
    return WillPopScope(
      onWillPop: () {
        scroll = 0;
        Navigator.pop(context, false);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(elevation: 0),
        floatingActionButton: SpeedDial(
            closeManually: true,
            animatedIcon: AnimatedIcons.menu_close,
            foregroundColor: globals.darkRed,
            backgroundColor: Colors.grey[100],
            elevation: 2,
            curve: Curves.easeIn,
            overlayOpacity: 0,
            children: [
              SpeedDialChild(
                  elevation: 2,
                  child: Center(child: Text('Tansp', style: TextStyle(fontSize: 12, color: globals.darkRed))),
                  onTap: () => getTraspDialog(),
                  backgroundColor: Colors.grey[100]),
              SpeedDialChild(
                  elevation: 2,
                  child: Stack(
                    children: <Widget>[
                      Center(child: Icon(Icons.arrow_downward, color: globals.darkRed)),
                      if (scroll > 0)
                        Positioned(
                            bottom: 2,
                            right: 5,
                            child: Text(scroll.toString() + 'x', style: TextStyle(color: globals.darkRed))),
                    ],
                  ),
                  onTap: () async {
                    if (await webViewController.canScrollVertically()) setState(() => setTimer());
                  },
                  backgroundColor: Colors.grey[100]),
              if (widget.canto.url != '')
                SpeedDialChild(
                    elevation: 2,
                    child: Center(child: Icon(Icons.music_note, color: globals.darkRed)),
                    onTap: () => _loadFile(),
                    backgroundColor: Colors.grey[100]),
            ]),
        body: Column(
          children: <Widget>[
            if (exibePlayer)
              PlayerWidget(
                key: playerKey,
                url: localFilePath,
              ),
            if (percentDownload > 0 && percentDownload < 1)
              LinearPercentIndicator(
                lineHeight: 20.0,
                percent: percentDownload,
                center: Text("${(percentDownload * 100).toInt()}%", style: TextStyle(color: Colors.white)),
                linearStrokeCap: LinearStrokeCap.butt,
                progressColor: globals.darkRed,
              ),
            Expanded(
              child: WebView(
                onWebViewCreated: (WebViewController controller) {
                  webViewController = controller;
                },
                initialUrl: Uri.dataFromString(strCanto, mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
                    .toString(),
                gestureNavigationEnabled: true,
              ),
            ),
          ],
        ),
      ),
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
      webViewController.scrollBy(0, 3);
    });
  }

  void transpor(int numero) {
    LineSplitter ls = new LineSplitter();
    strCanto = utf8.decode(base64.decode(widget.canto.extBase64));
    List<String> content = ls.convert(strCanto);

    List<String> escalaTmp = [
      "zerofiller",
      "@01",
      "@02",
      "@03",
      "@04",
      "@05",
      "@06",
      "@07",
      "@08",
      "@09",
      "@10",
      "@11",
      "@12"
    ];
    List<String> escalaEuropeia = [
      "zerofiller",
      "Do",
      "Do#",
      "Re",
      "Mib",
      "Mi",
      "Fa",
      "Fa#",
      "Sol",
      "Sol#",
      "La",
      "Sib",
      "Si",
      "Do",
      "Do#",
      "Re",
      "Mib",
      "Mi",
      "Fa",
      "Fa#",
      "Sol",
      "Sol#",
      "La",
      "Sib",
      "Si"
    ];
//    List<String> escalaAmericana = new List<String>.from(["zerofiller", "C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B", "C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"]);
    List<String> escalaMenos =
        new List<String>.from(["C-", "C#-", "D-", "Eb-", "E-", "F-", "F#-", "G-", "G#-", "A-", "Bb-", "B-"]);
    List<String> escalaMenor =
        new List<String>.from(["Cm", "C#m", "Dm", "Ebm", "Em", "Fm", "F#m", "Gm", "G#m", "Am", "Bbm", "Bm"]);
    List<String> escala = escalaEuropeia;
//    if (settings.getBoolean("escalaAmericana", false)) {
//      escala = escalaAmericana;
//    }
    int pri = 99;
    int dif = 0;

    for (var c = 0; c < content.length; c++) {
      if (!content[c].contains("FF0000")) {
        if (content[c].contains("@transp@")) {
          //int transSalv = settings.getInt("TRANSP_" + html, 0);
          //if (transSalv != 0) {
          //   receiveString = (((("<FONT COLOR=\"#8a00e0\">" + getString(R.string.saved)) + getString(R.string.transpo)) + escalaTmp[transSalv]) + "</FONT>");
          //  pri = 98;
          //} else {
          continue;
          // }
        }
        if (content[c].contains("@capot@")) {
//            int capotSalv = settings.getInt("CAPOT_" + html, 0);
//            if (capotSalv != 0) {
//              receiveString = (((((("<FONT COLOR=\"#8a00e0\">" + getString(R.string.saved)) + getString(R.string.capo)) + capotSalv) + "ª ") + getString(R.string.traste)) + "</FONT>");
//              pri = 98;
//            } else {
//              if (receiveString.contains(getString(R.string.capo))) {
//                stringBuilder.append(receiveString).append("\n");
//              }
          continue;
        }
        continue;
      }
      if (content[c].contains("<H2>")) {
        continue;
      }
      content[c] =
          content[c].replaceAll("Do#", escalaTmp[2]).replaceAll("Fa#", escalaTmp[7]).replaceAll("Sol#", escalaTmp[9]);
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
      strCanto = strCanto + c + '\n';
    });
  }

  getTraspDialog() {
    return Get.defaultDialog(
        title: 'Transpor',
        radius: 4,
        content: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.6),
            child: Padding(
                padding: EdgeInsets.all(4),
                child: Table(children: [
                  TableRow(children: [
                    transporButton(01, "Do/Do-"),
                    transporButton(02, "Do#/Do#-"),
                  ]),
                  TableRow(children: [
                    transporButton(03, "Re/Re-"),
                    transporButton(04, "Mib"),
                  ]),
                  TableRow(children: [
                    transporButton(05, "Mi/Mi-"),
                    transporButton(06, "Fa/Fa-"),
                  ]),
                  TableRow(children: [
                    transporButton(07, "Fa#/Fa#-"),
                    transporButton(08, "Sol/Sol-"),
                  ]),
                  TableRow(children: [
                    transporButton(09, "Sol#/Sol#-"),
                    transporButton(10, "La/La-"),
                  ]),
                  TableRow(children: [
                    transporButton(11, "Sib/Sib-"),
                    transporButton(12, "Si/Si-"),
                  ])
                ]))));
  }

  Widget transporButton(int numero, String nota) {
    return Container(
        margin: EdgeInsets.all(8),
        width: 100,
        child: FlatButton(
            child: Text(nota),
            color: Colors.grey[200],
            textColor: Colors.black,
            onPressed: () {
              transpor(numero);
              scroll = 0;
              webViewController.loadUrl(
                  Uri.dataFromString(strCanto, mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
                      .toString());
              setState(() {});
              Navigator.of(context).pop();
            }));
  }
}
