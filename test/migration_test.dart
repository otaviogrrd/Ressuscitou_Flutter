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

  test('number-only catalogs display and serialize the current number', () {
    final canto = Canto.fromJson({'id': 227, 'numero': '21'});
    expect(canto.numero, '21');
    expect(canto.id, 227);
    expect(canto.toJson()['numero'], '21');
    expect(canto.toJson().containsKey('nr_2019'), isFalse);
    expect(canto.toJson().containsKey('nr_2026'), isFalse);
    expect(Canto.fromJson(canto.toJson()).numero, '21');
  });

  test('legacy catalogs prefer the newest non-empty edition number', () {
    expect(Canto.fromJson({'numero': '227', 'nr_2019': '21'}).numero, '21');
    expect(Canto.fromJson({
      'numero': '227', 'nr_2019': '21', 'nr_2026': '22',
    }).numero, '22');
    expect(Canto.fromJson({
      'numero': '227', 'nr_2019': '21', 'nr_2026': ' ',
    }).numero, '21');
    expect(Canto.fromJson({'numero': 21}).numero, '21');
    expect(Canto.fromJson({}).numero, isEmpty);
  });

  test('legacy content is ignored and not serialized', () {
    final canto = Canto.fromJson({
      'id': 227, 'numero': '21', 'conteudo': 'indiceantigosemespacos',
    });
    expect(canto.id, 227);
    expect(canto.numero, '21');
    expect(canto.toJson().containsKey('conteudo'), isFalse);
  });

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

  test('serializing a canto preserves its values and canonical number', () {
    final canto = Canto(
      id: 42,
      titulo: 'Canto de ensaio',
      numero: '007',
      categorias: ['advento-natal'],
      htmlBase64: base64Encode(utf8.encode('<h1>Ensaio</h1>')),
      downloaded: true,
    );
    final serialized = canto.toJson();
    final restored = Canto.fromJson(jsonDecode(jsonEncode(serialized)));
    expect(restored.toJson(), serialized);
    expect(canto.id, 42);
    expect(canto.titulo, 'Canto de ensaio');
    expect(restored.numero, '007');
    expect(restored.categorias, ['advento-natal']);
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
      'cantosFonte': CantoService().urlCantos,
      'cantosVersao': CantoService.bundledCatalogVersion,
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
