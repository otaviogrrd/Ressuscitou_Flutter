import 'package:flutter_test/flutter_test.dart';
import 'package:ressuscitou/helpers/canto_search.dart';
import 'package:ressuscitou/model/canto.dart';

void main() {
  test('normalization handles accents, case, punctuation and spaces', () {
    expect(normalizeCantoSearch('  É O SENHOR — coração!  '), 'e o senhor coracao');
  });

  test('exact, title fragment and lyric matches precede approximate titles', () {
    final songs = [
      Canto(id: 4, titulo: 'Ressucitou'),
      Canto(id: 3, titulo: 'Outro canto', conteudo: 'ressuscitou'),
      Canto(id: 2, titulo: 'Ressuscitou Aleluia'),
      Canto(id: 1, titulo: 'Ressuscitou'),
    ];
    expect(CantoSearchIndex(songs).search('ressuscitou').map((canto) => canto.id),
        [1, 2, 3, 4]);
  });

  test('a typo still finds the song', () {
    final canto = Canto(id: 1, titulo: 'Ressuscitou');
    expect(CantoSearchIndex([canto]).search('ressucitou'), [canto]);
  });

  test('titles and old compact lyric indexes ignore accents and spaces', () {
    final songs = [
      Canto(id: 1, titulo: 'É o Senhor'),
      Canto(id: 2, titulo: 'Outro', conteudo: 'gloriaaosenhor'),
    ];
    final index = CantoSearchIndex(songs);
    expect(index.search('e o senhor').first.id, 1);
    expect(index.search('éosenhor').first.id, 1);
    expect(index.search('glória ao senhor').first.id, 2);
  });

  test('number lookup prioritizes exact numbers and accepts leading zeros', () {
    final songs = [
      Canto(id: 1, nr2019: '017', titulo: 'Outro'),
      Canto(id: 2, nr2019: '007', titulo: 'Exato'),
      Canto(id: 3, nr2019: '120', numero: '7', titulo: 'Número antigo'),
      Canto(id: 7, nr2019: '999', titulo: 'ID não é número de canto'),
    ];
    final index = CantoSearchIndex(songs);
    expect(index.search('7').map((canto) => canto.id), [2, 3, 1]);
    expect(index.search('007').map((canto) => canto.id), [2, 3, 1]);
    expect(index.search('998'), isEmpty);
  });

  test('category applies to both exact and approximate matches', () {
    final index = CantoSearchIndex([
      Canto(id: 1, titulo: 'Ressuscitou', categoria: 1),
      Canto(id: 2, titulo: 'Ressuscitou', categoria: 2),
    ]);
    expect(index.search('ressucitou', category: 2).single.id, 2);
    expect(index.search('ressuscitou', category: 3), isEmpty);
  });

  test('empty queries and ties preserve catalog order and original objects', () {
    final first = Canto(id: 2, titulo: 'É o Senhor', categoria: 1);
    final second = Canto(id: 1, titulo: 'E o Senhor', categoria: 1);
    final songs = [first, second];
    final index = CantoSearchIndex(songs);
    final all = index.search('   ', category: 1);
    expect(all, songs);
    expect(identical(all, songs), isFalse);
    expect(identical(index.search('e o senhor').first, first), isTrue);
    expect(songs.first.titulo, 'É o Senhor');
    expect(index.search('e o senhor').map((canto) => canto.id), [2, 1]);
  });

  test('short or unrelated queries do not produce approximate noise', () {
    final index = CantoSearchIndex([Canto(titulo: 'Ressuscitou')]);
    expect(index.search('zz'), isEmpty);
    expect(index.search('xyzabc'), isEmpty);
  });
}
