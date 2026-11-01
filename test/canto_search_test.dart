import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ressuscitou/helpers/canto_search.dart';
import 'package:ressuscitou/model/canto.dart';

String encodedLyrics(String body) => base64Encode(utf8.encode('''
<html><head><style>.html_canto{white-space:pre;font-family:monospace}</style></head>
<body><div class="html_canto"><H1>Título</H1><div class="inv">@transp@ @capot@</div>
$body</div></body></html>'''));

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

  test('shared common words do not qualify unrelated approximate titles', () {
    final index = CantoSearchIndex([
      Canto(id: 1, titulo: 'Senhor dos caminhos'),
      Canto(id: 2, titulo: 'Senhor da manhã'),
      Canto(id: 3, titulo: 'Caminhos da esperança'),
    ]);
    expect(index.search('senhor dos campos'), isEmpty);
    expect(index.search('senhor da noite'), isEmpty);
    expect(index.search('senr'), isEmpty); // short queries do not use approximation
    expect(index.search('senhor dos caminho').single.id, 1);
    expect(index.search('senhor dos caminhs').single.id, 1);
  });

  test('approximate title results explain the actual matching title', () {
    final canto = Canto(titulo: 'Ressuscitou');
    final result = CantoSearchIndex([canto]).searchResults('ressucitou').single;
    expect(result.approximate, isTrue);
    expect(result.subtitle, 'Título semelhante: Ressuscitou');
    expect(result.canto, same(canto));
  });

  test('compact legacy indexes show the original accented lyric phrase', () {
    final encoded = encodedLyrics('<FONT COLOR="#FF0000">Do Sol Re</FONT>\n'
        '<FONT COLOR="#000000">Uma manhã de paz &amp; alegria.</FONT>');
    final canto = Canto(titulo: 'Outro canto', conteudo: 'umamanhadepazealegria', htmlBase64: encoded);
    final result = CantoSearchIndex([canto]).searchResults('manha de paz').single;
    expect(result.subtitle, 'Trecho: Uma manhã de paz & alegria.');
    expect(result.approximate, isFalse);
    expect(result.snippet, isNot(contains('Do Sol')));
    expect(result.snippet, isNot(contains('@transp@')));
    expect(canto.htmlBase64, encoded);
  });

  test('snippets handle HTML boundaries and plain content fallback', () {
    final index = CantoSearchIndex([
      Canto(id: 1, titulo: 'Primeiro', htmlBase64: encodedLyrics('<p>Uma manhã</p><p>de paz</p>')),
      Canto(id: 2, titulo: 'Segundo', htmlBase64: 'invalid!', conteudo: 'Uma manhã de paz'),
    ]);
    final results = index.searchResults('manhã de paz');
    expect(results.map((result) => result.canto.id), [1, 2]);
    expect(results.every((result) => result.subtitle == 'Trecho: Uma manhã de paz'), isTrue);
    expect(index.searchResults('').every((result) => result.subtitle == null), isTrue);
  });

  test('snippets use the actual occurrence in long lyrics', () {
    final canto = Canto(titulo: 'Outro', conteudo: '${'início ' * 30}Uma manhã de paz ${'final ' * 30}');
    final result = CantoSearchIndex([canto]).searchResults('manha de paz').single;
    expect(result.snippet, contains('Uma manhã de paz'));
    expect(result.snippet!.startsWith('…'), isTrue);
    expect(result.snippet!.endsWith('…'), isTrue);
    expect(result.snippet!.length, lessThan(150));
  });


  test('Portuguese composed and decomposed accents normalize identically', () {
    const composed = 'Á É Í Ó Ú Â Ê Ô Ã Õ Ç à';
    const decomposed = 'A\u0301 E\u0301 I\u0301 O\u0301 U\u0301 A\u0302 E\u0302 O\u0302 A\u0303 O\u0303 C\u0327 a\u0300';
    expect(normalizeCantoSearch(composed), 'a e i o u a e o a o c a');
    expect(normalizeCantoSearch(decomposed), normalizeCantoSearch(composed));
    final index = CantoSearchIndex([
      Canto(id: 1, titulo: 'Canção da manhã'),
      Canto(id: 2, titulo: 'Outro', conteudo: 'cancao da manha'),
    ]);
    for (final query in ['CANÇÃO DA MANHÃ', 'cancao da manha', 'canc\u0327a\u0303o da manha\u0303']) {
      expect(index.search(query).map((canto) => canto.id), [1, 2]);
    }
  });

  test('typing accents, deleting them and using smart punctuation stays safe', () {
    final canto = Canto(titulo: 'Coração e esperança', htmlBase64: encodedLyrics('A manhã traz paz e esperança.'));
    final index = CantoSearchIndex([canto]);
    for (final input in ['coração', 'corac\u0327a\u0303o', 'manhã', 'manha\u0303', '“esperança”', 'esperança 🕊️']) {
      for (var length = 0; length <= input.length; length++) {
        expect(() => index.searchResults(input.substring(0, length)), returnsNormally);
      }
      expect(index.search(input), contains(canto));
    }
    for (final input in ['\u0301', 'ã', 'ç', '´', '😀', '', 'não existe aqui']) {
      expect(() => index.searchResults(input), returnsNormally);
    }
  });

  test('decomposed accents in original lyrics preserve the matching excerpt', () {
    const phrase = 'Uma manha\u0303 de paz e esperanc\u0327a.';
    final canto = Canto(titulo: 'Outro', htmlBase64: encodedLyrics(phrase));
    final result = CantoSearchIndex([canto]).searchResults('manhã de paz').single;
    expect(result.snippet, phrase);
    expect(result.subtitle, 'Trecho: $phrase');
  });

}
