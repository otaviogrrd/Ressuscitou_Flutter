import "package:flutter/material.dart";
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/model/mensagem.dart';

class MensagensPage extends StatefulWidget {
  @override
  _MensagensPageState createState() => _MensagensPageState();
}

class _MensagensPageState extends State<MensagensPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mensagens"),centerTitle:  false),
      body: Container(
        margin: EdgeInsets.all(16),
        child: FutureBuilder(
          future: MensagemService().getMensagens(),
          builder: (context, AsyncSnapshot<List<Mensagem>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data.isEmpty)
                return Center(child: Text("Não há mensagens."));
              else
                return SingleChildScrollView(
                    child: Column(children: <Widget>[
                  for (final item in snapshot.data)
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text(item.titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Align(
                          alignment: Alignment.centerRight,
                          child: Text(getDateFormatted(item.data_Ini), style: TextStyle(fontSize: 13))),
                      Text(item.conteudo, style: TextStyle(fontSize: 15)),
                      SizedBox(height: 30)
                    ])
                ]));
            } else
              return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
