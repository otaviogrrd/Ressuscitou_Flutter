import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/model/canto.dart';
import 'package:ressuscitou/model/cantoList.dart';
import 'package:ressuscitou/model/configuracoes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('older backups retain lists, transpositions, capo and notes', () {
    final backup = <String, dynamic>{
      'listas': [
        {'titulo': 'Ensaio', 'cantos': [42, 7]},
      ],
      'cantos': [
        {'cantoId': 42, 'trans': 5, 'capot': 2, 'anota': 'Entrada após o refrão'},
      ],
    };
    final config = Configuracoes.fromJson(backup);
    expect(jsonDecode(jsonEncode(config)), backup);
    expect(config.cantos.single.trans, 5);
    expect(config.cantos.single.anota, 'Entrada após o refrão');
    final sparse = Configuracoes.fromJson({
      'cantos': [
        {'cantoId': 7},
      ],
    });
    expect(sparse.listas, isEmpty);
    expect(sparse.cantos.single.anota, isEmpty);
    expect(sparse.cantos.single.trans, 0);
  });

  test('serializing a canto preserves its values and legacy JSON keys', () {
    final canto = Canto(
      id: 42,
      titulo: 'Canto de ensaio',
      nr2019: '007',
      adve: true,
      htmlBase64: base64Encode(utf8.encode('<h1>Ensaio</h1>')),
      downloaded: true,
    );
    final serialized = canto.toJson();
    final restored = Canto.fromJson(jsonDecode(jsonEncode(serialized)));
    expect(restored.toJson(), serialized);
    expect(canto.id, 42);
    expect(canto.titulo, 'Canto de ensaio');
    expect(restored.nr2019, '007');
    expect(restored.adve, isTrue);
    expect(restored.downloaded, isTrue);
    expect(Canto.fromJson({'id': 7}).selected, isFalse);
    expect(Canto.fromJson({'id': 7}).titulo, isEmpty);
  });

  test('updating a saved list preserves other lists and preference keys', () async {
    SharedPreferences.setMockInitialValues({
      'Listas': jsonEncode([
        {'titulo': 'Ensaio', 'cantos': [42]},
        {'titulo': 'Outra', 'cantos': [7]},
      ]),
      'TRANSP_42': 5,
      'ANOT_42': 'Nota existente',
    });
    globals.prefs = await SharedPreferences.getInstance();
    final service = CantoListService();
    await service.saveList(
      listaOld: 'Ensaio',
      listaNew: CantoList(titulo: 'Ensaio atualizado', cantos: [42, 9]),
    );
    final lists = await service.getCantosList();
    expect(lists.map((list) => list.titulo), ['Outra', 'Ensaio atualizado']);
    expect(lists.last.cantos, [42, 9]);
    expect(globals.prefs.getInt('TRANSP_42'), 5);
    expect(globals.prefs.getString('ANOT_42'), 'Nota existente');
  });

  test('stored cantos remain available without a network request', () async {
    SharedPreferences.setMockInitialValues({
      'listCantos': jsonEncode([
        {'id': 42, 'titulo': 'Canto local', 'nr_2019': '007'},
      ]),
    });
    globals.prefs = await SharedPreferences.getInstance();
    final cantos = await CantoService().getCantosLocal();
    expect(cantos.single.titulo, 'Canto local');
    expect(cantos.single.downloaded, isFalse);
    expect(globals.cantosGlobal.single.id, 42);
  });

  testWidgets('custom speed dial stays open after a child action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        floatingActionButton: SpeedDial(
          closeManually: true,
          animatedIcon: AnimatedIcons.menu_close,
          children: [
            SpeedDialChild(child: const Text('Transp'), onTap: () => tapped = true),
          ],
        ),
      ),
    ));
    await tester.tap(find.byType(AnimatedIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transp'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    expect(find.text('Transp'), findsOneWidget);
  });
}
