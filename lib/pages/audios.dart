import "dart:io";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:path_provider/path_provider.dart";
import "package:percent_indicator/circular_percent_indicator.dart";
import "../helpers/global.dart";
import "../model/canto.dart";
import '../pages/player.dart';

class AudiosPage extends StatefulWidget {
  @override
  _AudiosPageState createState() => _AudiosPageState();
}

class _AudiosPageState extends State<AudiosPage> {
  bool cantosLoaded = false;
  bool downloading = false;
  int downCount = 0;
  final Set<int> _failedDownloads = {};
  List<Canto> listCantos = [];
  List<Canto> listCantos2 = [];

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    globals.listaGlobal = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          downloading = false;
        }
      },
      child: Scaffold(
          appBar: AppBar(title: Text("Áudios"), centerTitle: false, actions: [
            if (globals.listaGlobal.isNotEmpty && !downloading)
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () => action("Reproduzir"),
                tooltip: "Reproduzir selecionados",
              ),
            if (listCantos.where((c) => (c.selected)).toList().isNotEmpty && !downloading)
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => action("Apagar"),
                tooltip: "Apagar selecionados",
              ),
            if (listCantos2.isNotEmpty && !downloading)
              IconButton(
                icon: Icon(Icons.file_download),
                onPressed: () => action("Download"),
                tooltip: "Baixar todos áudios",
              ),
          ]),
          body: getBody(),
        ));
  }

  action(String value) async {
    if (value == "Apagar") {
      Get.defaultDialog(
        title: "Apagar áudios",
        radius: 4,
        content: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.6),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Tem certeza que deseja apagar os áudios selecionados?", textAlign: TextAlign.center),
                ],
              ),
            )),
        confirm: Container(
          width: 100,
          child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Apagar")),
            onPressed: () async {
              var count = 0;
              for (var i = 0; i < listCantos.length; i++) {
                if (listCantos[i].selected) {
                  count++;
                  await listCantos[i].mp3Delete();
                }
              }
              globals.listaGlobal = [];
              cantosLoaded = false;
              setState(() {});
              Navigator.of(context).pop();
              if (count == 1)
                snackBar(Get.overlayContext, "$count Canto apagado!");
              else
                snackBar(Get.overlayContext, "$count Cantos apagados!");
            },
          ),
        ),
        cancel: Container(
          width: 100,
          child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Theme.of(context).colorScheme.onSecondary),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text("Cancelar")),
              onPressed: () => Navigator.pop(context)),
        ),
      );
    }
    if (value == "UnMarkAll") {
      for (var i = 0; i < listCantos.length; i++) {
        listCantos[i].selected = false;
        globals.listaGlobal = [];
      }
      setState(() {});
    }
    if (value == "MarkAll") {
      for (var i = 0; i < listCantos.length; i++) {
        listCantos[i].selected = true;
        if (globals.listaGlobal.where((c) => (c.id == listCantos[i].id)).toList().isEmpty)
          globals.listaGlobal.add(globals.cantosGlobal.where((c) => (c.id == listCantos[i].id)).toList().first);
      }
      setState(() {});
    }

    if (value == "Download") {
      download();
    }

    if (value == "Reproduzir") {
      Get.to(() => PlayerPage());
    }
  }

  download() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      snackBar(Get.overlayContext, "Sem conexão de internet!");
      return;
    }

    Get.defaultDialog(
      title: "Atenção",
      radius: 4,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Download de todos áudios disponíveis."),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text("Aproximadamente 1GB!"),
          ),
          if (connectivityResult.contains(ConnectivityResult.mobile) && !connectivityResult.contains(ConnectivityResult.wifi))
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text("É recomendado o uso de WiFi", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (connectivityResult.contains(ConnectivityResult.mobile) && !connectivityResult.contains(ConnectivityResult.wifi))
            Text("para economia de seus dados móveis.", style: TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
      confirm: Container(
        width: 100,
        child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Continuar")),
            onPressed: () {
              action("UnMarkAll");
              downloading = true;
              _failedDownloads.clear();
              startDownloader();
              Navigator.pop(context);
            }),
      ),
      cancel: Container(
        width: 100,
        child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Theme.of(context).colorScheme.onSecondary),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text("Cancelar")),
            onPressed: () => Navigator.pop(context)),
      ),
    );
  }

  void startDownloader() {
    if (!mounted || !downloading) return;
    for (var index = 0; index < listCantos2.length && downCount < 3; index++) {
      final canto = listCantos2[index];
      if (!canto.downloaded && canto.percentDownload == 0 && !_failedDownloads.contains(canto.id)) {
        downCount++;
        downloadFile(index);
      }
    }
    if (downCount == 0) setState(() {
      downloading = false;
      cantosLoaded = false;
    });
  }

  Future<void> downloadFile(int index) async {
    final canto = listCantos2[index];
    if (canto.percentDownload > 0) {
      downCount--;
      startDownloader();
      return;
    }
    canto.percentDownload = 0.001;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${canto.html}.mp3');
      final response = await Dio().get<List<int>>(
        'https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/audios/${canto.html}.mp3',
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() => canto.percentDownload = (received / total).clamp(0.0, 1.0).toDouble());
          }
        },
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) throw StateError('Áudio vazio.');
      await file.writeAsBytes(bytes, flush: true);
      await canto.mp3Downloaded();
    } catch (error) {
      canto.percentDownload = 0;
      _failedDownloads.add(canto.id);
      if (mounted) snackBar(context, 'Erro ao baixar áudio: $error');
    } finally {
      downCount--;
      if (mounted) setState(() {});
      if (mounted && downloading) startDownloader();
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
              listCantos = snapshot.data!.where((c) => (c.downloaded)).toList();
              listCantos2 = snapshot.data!.where((c) => (c.url == "X" && !c.downloaded)).toList();
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
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                          radius: 20.0,
                          lineWidth: 2,
                          percent: listCantos2[index].percentDownload,
                          center: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              child: Text("${(listCantos2[index].percentDownload * 100).toInt()}%"),
                            ),
                          ),
                          progressColor: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Container(height: 45, width: 45, child: Icon(Icons.check)),
              ]),
              );
            });
    }
    if (listCantos.isNotEmpty) {
      return Column(
        children: [
          Table(children: [
            TableRow(
              children: [
                InkWell(
                  onTap: () => action("MarkAll"),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 0, 8),
                        child: Icon(
                          Icons.check_box,
                          color: checkDarkMode(context) ? null : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text("Selecionar Todos"))),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => action("UnMarkAll"),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 0, 8),
                        child: Icon(
                          Icons.check_box_outline_blank,
                          // color: Theme.of(context).colorScheme.primary,

                          color: checkDarkMode(context) ? null : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text("Limpar Seleção"))),
                    ],
                  ),
                ),
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
                      if (listCantos[index].selected)
                        globals.listaGlobal.add(globals.cantosGlobal.where((c) => (c.id == listCantos[index].id)).toList().first);
                      else
                        globals.listaGlobal.removeWhere((c) => c.id == listCantos[index].id);
                    }),
                    checkColor: checkDarkMode(context) ? Theme.of(context).colorScheme.primary : null,
                    activeColor: checkDarkMode(context) ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.primary,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(listCantos[index].titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
    return Center(
      child: Text("Não há áudios baixados"),
    );
  }

  delaySetState() async {
    Future<String>.delayed(Duration(milliseconds: 100), () => "delay").then((String value) {
      setState(() {});
    });
  }
}
