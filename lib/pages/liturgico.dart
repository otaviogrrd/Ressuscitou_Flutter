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
              for (final group in CantoService.catalogoAtual!.categorias)
                ExpansionTile(
                  key: PageStorageKey(group.id),
                  title: Text(group.nome,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )),
                  children: [
                    for (final canto in cantos.where((canto) => canto.categorias.contains(group.id)))
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
