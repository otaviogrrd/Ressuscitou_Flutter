import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/model/canto.dart';

class AudiosPage extends StatefulWidget {
  @override
  _AudiosPageState createState() => _AudiosPageState();
}

class _AudiosPageState extends State<AudiosPage> {
  bool cantosLoaded = false;
  bool downloading = false;
  int downCount = 0;
  List<Canto> listCantos = [];
  List<Canto> listCantos2 = [];

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          if (downloading) downloading = false;
          Navigator.pop(context, false);
          return Future.value(false);
        },
        child: Scaffold(
          appBar: AppBar(title: Text('Ressuscitou'), centerTitle: false, actions: [
            if (listCantos.where((c) => (c.selected != null && c.selected)).toList().isNotEmpty)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () => action('Apagar'),
              ),
            if (listCantos2.isNotEmpty && !downloading)
              IconButton(
                icon: Icon(Icons.file_download, color: Colors.white),
                onPressed: () => action('Download'),
              ),
          ]),
          body: getBody(),
        ));
  }

  action(String value) async {
    if (value == 'Apagar') {
      for (var i = 0; i < listCantos.length; i++) {
        if (listCantos[i].selected != null && listCantos[i].selected) {
          await listCantos[i].mp3Delete();
        }
      }
      cantosLoaded = false;
      setState(() {});
    }
    if (value == 'UnMarkAll') {
      for (var i = 0; i < listCantos.length; i++) {
        listCantos[i].selected = false;
      }
      setState(() {});
    }
    if (value == 'MarkAll') {
      for (var i = 0; i < listCantos.length; i++) {
        listCantos[i].selected = true;
      }
      setState(() {});
    }

    if (value == 'Download') {
      download();
    }
  }

  download() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    Get.defaultDialog(
      title: 'Atenção',
      radius: 4,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text('Download de todos audios disponíveis.'),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('Aproximadamente 1GB!'),
          ),
          if (connectivityResult == ConnectivityResult.mobile)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('É recomendado o uso de WiFi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (connectivityResult == ConnectivityResult.mobile)
            Text('para economia de seus dados móveis.', style: TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
      confirm: Container(
        width: 100,
        child: FlatButton(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Continuar")),
            color: globals.darkRed,
            textColor: Colors.white,
            onPressed: () {
              downloading = true;
              startDownloader();
              Navigator.pop(context);
            }),
      ),
      cancel: Container(
        width: 100,
        child: FlatButton(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Cancelar")),
            color: Colors.black12,
            textColor: Colors.black,
            onPressed: () => Navigator.pop(context)),
      ),
    );
  }

  startDownloader() async {
    if (listCantos2.where((c) => (!c.downloaded)).toList().length > 0 && downloading) {
      loop:
      for (var c = 0; c < listCantos2.length; c++) {
        if (listCantos2[c].percentDownload == 0) {
          downloadFile(c);
          downCount++;
        }
        if (downCount == 3) break loop;
      }
    }
  }

  Future downloadFile(int index) async {
    if (listCantos2[index].percentDownload > 0) {
      downCount--;
      startDownloader();
      return;
    }
    listCantos2[index].percentDownload = 0.001;

    StreamController<int> progressStreamController = new StreamController();
    Dio dio = new Dio();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/' + listCantos2[index].html + '.mp3');
    var url = "https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/audios/" +
        listCantos2[index].html +
        ".mp3";

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
        listCantos2[index].downloaded = true;
        setState(() {});
      });
    }).whenComplete(() {
      progressStreamController.close();
      listCantos2[index].downloaded = true;
      downCount--;
      Timer(Duration(seconds: 1), () => startDownloader());
    });

    await for (int p in progressStreamController.stream) {
      setState(() {
        listCantos2[index].percentDownload = p / 100;
      });
    }
  }

  getBody() {
    if (cantosLoaded)
      return listaCantos();
    else
      return FutureBuilder(
          future: CantoService().getCantosLocal(),
          builder: (BuildContext cont, AsyncSnapshot<List<Canto>> snapshot) {
            if (snapshot.hasData) {
              listCantos = snapshot.data.where((c) => (c.downloaded != null && c.downloaded)).toList();
              listCantos2 = snapshot.data
                  .where((c) => (c.url != null && c.url == "X" && c.downloaded != null && !c.downloaded))
                  .toList();
              cantosLoaded = true;
              delaySetState();
              return listaCantos();
            } else
              return Center(child: CircularProgressIndicator());
          });
  }

  listaCantos() {
    if (downloading) {
      if (listCantos2.isNotEmpty)
        return ListView.builder(
            itemCount: listCantos2.length,
            itemBuilder: (context, index) {
              return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: Text(listCantos2[index].titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                )),
                ((listCantos2[index].percentDownload * 100).toInt() < 99)
                    ? Container(
                        height: 45,
                        width: 45,
                        child: CircularPercentIndicator(
                          radius: 30.0,
                          lineWidth: 2,
                          percent: listCantos2[index].percentDownload,
                          center: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              child: Text(
                                "${(listCantos2[index].percentDownload * 100).toInt()}%",
                              ),
                            ),
                          ),
                          progressColor: globals.darkRed,
                        ),
                      )
                    : Container(height: 45, width: 45, child: Icon(Icons.check)),
              ]);
            });
    }
    if (listCantos != null && listCantos.isNotEmpty) {
      return Column(
        children: <Widget>[
          Table(children: [
            TableRow(
              children: <Widget>[
                InkWell(
                  onTap: () => action('MarkAll'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16,8,0,8),
                        child: Icon(Icons.check_box, color: globals.darkRed),
                      ),
                      Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Selecionar Todos'))),
                    ],
                  ),
                ),

                InkWell(
                  onTap: () => action('UnMarkAll'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16,8,0,8),
                        child: Icon(Icons.check_box_outline_blank, color: globals.darkRed),
                      ),
                      Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Limpar Seleção'))),
                    ],
                  ),
                ),
//                FlatButton.icon(
//                  icon: Icon(Icons.check_box_outline_blank, color: globals.darkRed),
//                  label: Text('Limpar Seleção'),
//                  onPressed: () => action('UnMarkAll'),
//                ),
              ],
            ),
          ]),
          Expanded(
            child: ListView.builder(
                itemCount: listCantos.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    value: listCantos[index].selected,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => setState(() {
                      listCantos[index].selected = !listCantos[index].selected;
                    }),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                            child: Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(listCantos[index].titulo,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        )),
                        Text(listCantos[index].fileSize, style: TextStyle(fontSize: 13))
                      ],
                    ),
                  );
                }),
          ),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text("Não há arquivos baixados", textAlign: TextAlign.center),
    );
  }

  delaySetState() async {
    Future<String>.delayed(Duration(milliseconds: 100), () => 'delay').then((String value) {
      setState(() {});
    });
  }
}
