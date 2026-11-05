import 'package:flutter_test/flutter_test.dart';
import 'package:ressuscitou/model/canto.dart';

Map<String, dynamic> fixture() => {
  'edicao': 2026,
  'categorias': [
    {'id': 'final', 'nome': 'Nome configurado', 'ordem': 2},
    {'id': 'entrada', 'nome': 'Entrada configurada', 'ordem': 1},
  ],
  'cantos': [
    {'id': 227, 'numero': '21', 'categoria': 3, 'categorias': ['entrada', 'final']},
  ],
};

void main() {
  test('catalog metadata and memberships survive offline serialization', () {
    final catalog = Catalogo.fromJson(fixture());
    expect(catalog.categorias.map((g) => g.id), ['entrada', 'final']);
    expect(catalog.categorias.first.nome, 'Entrada configurada');
    expect(catalog.cantos.single.categoria, 3);
    final restored = Catalogo.fromJson(catalog.toJson());
    expect(restored.edicao, 2026);
    expect(restored.cantos.single.categorias, ['entrada', 'final']);
    expect(restored.cantos.single.numero, '21');
    expect(restored.cantos.single.toJson().containsKey('adve'), isFalse);
  });

  test('legacy flags merge without duplicates and omit laudes', () {
    final catalog = Catalogo.fromJson([
      {'id': 1, 'adve': true, 'nata': true, 'pasc': true, 'pent': true, 'laud': true},
    ]);
    expect(catalog.cantos.single.categorias, ['advento-natal', 'pascoa-pentecostes']);
    expect(catalog.categorias.length, 10);
    expect(Catalogo.fromJson(catalog.toJson()).cantos.single.categorias,
        catalog.cantos.single.categorias);
  });

  test('invalid category references and duplicates are rejected', () {
    for (final links in [['missing'], ['entrada', 'entrada']]) {
      final data = fixture();
      (data['cantos'] as List).first['categorias'] = links;
      expect(() => Catalogo.fromJson(data), throwsFormatException);
    }
    final duplicate = fixture();
    (duplicate['categorias'] as List).add({'id': 'entrada', 'nome': 'Outra', 'ordem': 3});
    expect(() => Catalogo.fromJson(duplicate), throwsFormatException);
  });

  test('explicit empty links override old flags', () {
    expect(Canto.fromJson({'categorias': [], 'adve': true}).categorias, isEmpty);
  });
}
