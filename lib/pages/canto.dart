import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:ressuscitou/model/canto.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../helpers/global.dart';
import 'dart:async';

class CantoPage extends StatefulWidget {
  final Canto canto;

  CantoPage({Key key, @required this.canto}) : super(key: key);

  @override
  _CantoPageState createState() => _CantoPageState();
}

class _CantoPageState extends State<CantoPage> {
  WebViewController webViewController;
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  String str;
  int scrolling = 0;
  int transp = 0;

  @override
  Widget build(BuildContext context) {
    transpor(transp);
    return WillPopScope(
      onWillPop: () {
        scrolling = 0;
        Navigator.pop(context, false);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(),
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
                  //Icon(Icons.music_note, color: globals.darkRed),
                  //label: 'Transpor',
                  onTap: () => getTraspDialog(),
                  backgroundColor: Colors.grey[100]),
              SpeedDialChild(
                  elevation: 2,
                  child: Stack(
                    children: <Widget>[
                      Center(child: Icon(Icons.arrow_downward, color: globals.darkRed)),
                      if (scrolling > 0)
                        Positioned(
                            bottom: 2,
                            right: 5,
                            child: Text(scrolling.toString() + 'x', style: TextStyle(color: globals.darkRed))),
                    ],
                  ),
                  //label: 'Scroll',
                  onTap: () async {
                    if (await webViewController.canScrollVertically()) setState(() => setTimer());
                  },
                  backgroundColor: Colors.grey[100]),
            ]),
        body: WebView(
          onWebViewCreated: (WebViewController controller) {
            webViewController = controller;
          },
          initialUrl: Uri.dataFromString(str, mimeType: 'text/html', encoding: Encoding.getByName('utf-8')).toString(),
          gestureNavigationEnabled: true,
        ),
      ),
    );
  }

  setTimer() {
    scrolling++;
    Timer.periodic(Duration(milliseconds: 200), (timer) async {
      if (!(await webViewController.canScrollVertically())) {
        setState(() => scrolling = 0);
        return;
      }
      if (scrolling == 0) timer.cancel();
      webViewController.scrollBy(0, 3);
    });
  }

  void transpor(int numero) {
    LineSplitter ls = new LineSplitter();
    str = utf8.decode(base64.decode(widget.canto.extBase64));
    List<String> content = ls.convert(str);

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
    str = "";
    content.forEach((c) {
      str = str + c + '\n';
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
              scrolling = 0;
              webViewController.loadUrl(
                  Uri.dataFromString(str, mimeType: 'text/html', encoding: Encoding.getByName('utf-8')).toString());
              Navigator.of(context).pop();
            }));
  }
}
