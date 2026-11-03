import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/global.dart';
import '../model/canto.dart';
import 'canto.dart';

class LiturgicoPage extends StatefulWidget {
  const LiturgicoPage({super.key});
  @override
  State<LiturgicoPage> createState() => _LiturgicoPageState();
}

class _LiturgicoPageState extends State<LiturgicoPage> {
  late final Future<List<Canto>> _cantos = CantoService().getCantosLocal();
  static const _groups = [
    'ADVENTO',
    'LAUDES - VÉSPERAS',
    'CANTOS DE ENTRADA',
    'NATAL',
    'QUARESMA',
    'PÁSCOA',
    'PENTECOSTES',
    'CANTOS À VIRGEM',
    'CANTOS PARA AS CRIANÇAS',
    'PAZ - APRESENTAÇÃO DAS OFERENDAS',
    'FRAÇÃO DO PÃO',
    'COMUNHÃO',
    'CANTO FINAL',
  ];

  bool _belongsTo(Canto canto, int index) => switch (index) {
        0 => canto.adve,
        1 => canto.laud,
        2 => canto.entr,
        3 => canto.nata,
        4 => canto.quar,
        5 => canto.pasc,
        6 => canto.pent,
        7 => canto.virg,
        8 => canto.cria,
        9 => canto.cpaz,
        10 => canto.fpao,
        11 => canto.comu,
        12 => canto.cfin,
        _ => false,
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Índice Litúrgico')),
        body: FutureBuilder<List<Canto>>(
          future: _cantos,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Não foi possível carregar os cantos.'));
            }
            final cantos = snapshot.data;
            if (cantos == null) return const Center(child: CircularProgressIndicator());
            return ListView(children: [
              for (var index = 0; index < _groups.length; index++)
                ExpansionTile(
                  key: PageStorageKey(index),
                  title: Text(_groups[index],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )),
                  children: [
                    for (final canto in cantos.where((canto) => _belongsTo(canto, index)))
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: getColorCateg(canto.categoria),
                          foregroundColor: Colors.black,
                          child: Text(canto.numero, style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(canto.titulo),
                        trailing: canto.url.isEmpty
                            ? null
                            : Icon(Icons.music_note,
                                color: canto.downloaded
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey),
                        onTap: () async {
                          await Get.to(() => CantoPage(canto: canto));
                          if (mounted) setState(() {});
                        },
                      ),
                  ],
                ),
            ]);
          },
        ),
      );
}
