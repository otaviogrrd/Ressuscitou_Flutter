import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ressuscitou/helpers/canto_search.dart';
import 'package:ressuscitou/model/canto.dart';

String encodedLyrics(String body, {bool black = true}) => base64Encode(utf8.encode('''
<html><head><style>.html_canto{white-space:pre;font-family:monospace}</style></head>
<body><div class="html_canto"><H1>Título</H1><div class="inv">@transp@ @capot@</div>
${black ? '<FONT COLOR="#000000">$body</FONT>' : body}</div></body></html>'''));

void main() {
  test('normalization handles accents, case, punctuation and spaces', () {
    expect(normalizeCantoSearch('  É O SENHOR — coração!  '), 'e o senhor coracao');
  });

  test('exact, title fragment and lyric matches precede approximate titles', () {
    final songs = [
      Canto(id: 4, titulo: 'Ressucitou'),
      Canto(id: 3, titulo: 'Outro canto', htmlBase64: encodedLyrics('ressuscitou')),
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

  test('titles and black lyrics ignore accents and punctuation', () {
    final songs = [
      Canto(id: 1, titulo: 'É o Senhor'),
      Canto(id: 2, titulo: 'Outro', conteudo: 'indiceantigo', htmlBase64: encodedLyrics('Glória ao Senhor')),
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

  test('black HTML shows the original accented lyric phrase', () {
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

  test('snippets handle HTML boundaries and damaged normal variants', () {
    final index = CantoSearchIndex([
      Canto(id: 1, titulo: 'Primeiro', htmlBase64: encodedLyrics('<p>Uma manhã</p><p>de paz</p>')),
      Canto(id: 2, titulo: 'Segundo', htmlBase64: 'invalid!', extBase64: encodedLyrics('Uma manhã de paz')),
    ]);
    final results = index.searchResults('manhã de paz');
    expect(results.map((result) => result.canto.id), [1, 2]);
    expect(results.every((result) => result.subtitle == 'Trecho: Uma manhã de paz'), isTrue);
    expect(index.searchResults('').every((result) => result.subtitle == null), isTrue);
  });

  test('snippets use the actual occurrence in long lyrics', () {
    final canto = Canto(titulo: 'Outro', htmlBase64: encodedLyrics('${'início ' * 30}Uma manhã de paz ${'final ' * 30}'));
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
      Canto(id: 2, titulo: 'Outro', htmlBase64: encodedLyrics('canção da manhã')),
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


  test('approximate lyrics show the actual corrected phrase from black HTML', () {
    final canto = Canto(titulo: 'Título diferente', categoria: 2,
        htmlBase64: encodedLyrics('Uma manhã de paz e alegria.'));
    final index = CantoSearchIndex([canto]);
    final result = index.searchResults('manah de paz', category: 2).single;
    expect(result.approximate, isTrue);
    expect(result.titleMatch, isFalse);
    expect(result.subtitle, 'Trecho semelhante: Uma manhã de paz e alegria.');
    expect(index.searchResults('manah de paz', category: 1), isEmpty);
    expect(index.searchResults('manhã de paz').single.approximate, isFalse);
  });

  test('only black HTML is searched, never the legacy index or other colors', () {
    final canto = Canto(titulo: 'Exemplo', conteudo: 'indiceremovido palavraantiga', htmlBase64: encodedLyrics(
        '<FONT COLOR="#FF0000">cifras vermelhas</FONT>'
        '<FONT COLOR="#008000">anotação verde</FONT>'
        '<span>texto sem cor explícita</span>'
        '<FONT COLOR="#000000">Frase preta <b>com ênfase</b>'
        '<FONT COLOR="#FF0000">outra cifra</FONT>'
        '<span class="inv">segredo oculto</span></FONT>', black: false));
    final index = CantoSearchIndex([canto]);
    for (final query in ['indice removido', 'indiceremovido', 'palavraantiga', 'cifras vermelhas',
                         'anotação verde', 'texto sem cor', 'outra cifra', 'segredo oculto']) {
      expect(index.search(query), isEmpty, reason: query);
    }
    final result = index.searchResults('frase preta com enfase').single;
    expect(result.snippet, 'Frase preta com ênfase');
    expect(result.approximate, isFalse);
  });

  test('black font and inline CSS variants preserve inherited colors', () {
    final index = CantoSearchIndex([
      Canto(id: 1, titulo: 'Primeiro', htmlBase64: encodedLyrics('<font color="BLACK">Luz da manhã</font>', black: false)),
      Canto(id: 2, titulo: 'Segundo', htmlBase64: encodedLyrics('<span style="color: rgb(0, 0, 0)">Luz da <b>manhã</b></span>', black: false)),
      Canto(id: 3, titulo: 'Terceiro', htmlBase64: encodedLyrics('<font color="#000"><span style="color:red">fora da busca</span>Luz da manhã</font>', black: false)),
    ]);
    expect(index.search('luz da manha').map((canto) => canto.id), [1, 2, 3]);
    expect(index.search('fora da busca'), isEmpty);
  });

  test('HTML without black lyrics does not fall back to compact content', () {
    final index = CantoSearchIndex([
      Canto(titulo: 'Exemplo', conteudo: 'conteudolegadosemespacos', htmlBase64: 'broken!'),
      Canto(titulo: 'Outro', conteudo: 'conteúdo legado sem espaços', htmlBase64: encodedLyrics('texto sem tag preta', black: false)),
    ]);
    expect(index.search('conteudo legado'), isEmpty);
    expect(index.search('conteudolegadosemespacos'), isEmpty);
    expect(index.search('texto sem tag preta'), isEmpty);
  });

  test('exact lyric hits precede approximate phrases and unrelated phrases are rejected', () {
    final index = CantoSearchIndex([
      Canto(id: 2, titulo: 'Segundo', htmlBase64: encodedLyrics('A manhã traz luz e alegria.')),
      Canto(id: 1, titulo: 'Primeiro', htmlBase64: encodedLyrics('A manha traz lus e alegria.')),
      Canto(id: 3, titulo: 'Terceiro', htmlBase64: encodedLyrics('A noite traz silêncio e descanso.')),
    ]);
    final results = index.searchResults('manha traz lus');
    expect(results.map((result) => result.canto.id), [1, 2]);
    expect(results.first.approximate, isFalse);
    expect(results.last.approximate, isTrue);
    expect(results.last.snippet, contains('manhã traz luz'));
    expect(index.search('a manhã traz tristeza'), isEmpty);
    expect(index.search('alegria luz manhã'), isEmpty);
    expect(index.search('manh'), hasLength(2)); // partial exact matches, no short fuzzy matching
  });

  test('a title hit shows its black lyric occurrence when available', () {
    final canto = Canto(titulo: 'Luz da manhã', htmlBase64: encodedLyrics('Chegou a luz da manhã com alegria.'));
    expect(CantoSearchIndex([canto]).searchResults('luz da manha').single.subtitle,
        'Trecho: Chegou a luz da manhã com alegria.');
  });


  test('the remembered phrase supplied by the user finds the actual black lyrics', () {
    const phrase = 'LEVANDO SEMPRE EM NOSSO CORPO O MORRER DE JESUS, '
        'PARA QUE SE MANIFESTE EM NOSSO CORPO QUE ESTÁ RESSUSCITADO.';
    final canto = Canto(titulo: 'Exemplo do usuário', htmlBase64: encodedLyrics(phrase));
    final result = CantoSearchIndex([canto]).searchResults('levando sempre o poder de Jesus').single;
    expect(result.canto, same(canto));
    expect(result.approximate, isTrue);
    expect(result.subtitle, startsWith('Trecho semelhante: LEVANDO SEMPRE'));
    expect(result.snippet, contains('O MORRER DE JESUS'));
    expect(result.snippet, isNot(contains('poder')));
  });

  test('remembered phrases need enough ordered nearby anchors', () {
    final index = CantoSearchIndex([
      Canto(titulo: 'Exemplo', htmlBase64: encodedLyrics('Levando sempre em nosso corpo o morrer de Jesus.')),
      Canto(titulo: 'Outro', htmlBase64: encodedLyrics('Levando sempre no longo caminho entre vales e montanhas distantes a palavra de Jesus.')),
    ]);
    expect(index.search('levando sempre o poder de Jesus').map((song) => song.titulo), ['Exemplo']);
    expect(index.search('levando sempre Jesus').map((song) => song.titulo), ['Exemplo']);
    expect(index.search('Jesus sempre levando poder'), isEmpty);
    expect(index.search('levando sempre poder vida'), isEmpty);
    expect(index.search('sempre poder Jesus'), isEmpty);
  });

  test('remembered matches rank after exact and minor typo phrases', () {
    final index = CantoSearchIndex([
      Canto(id: 3, titulo: 'Terceiro', htmlBase64: encodedLyrics('Levando sempre em nosso corpo o morrer de Jesus.')),
      Canto(id: 2, titulo: 'Segundo', htmlBase64: encodedLyrics('Levando sempre o podre de Jesus.')),
      Canto(id: 1, titulo: 'Primeiro', htmlBase64: encodedLyrics('Levando sempre o poder de Jesus.')),
    ]);
    expect(index.search('levando sempre o poder de Jesus').map((song) => song.id), [1, 2, 3]);
  });


  test('poder de Jesus finds morrer de Jesus even without the longer query', () {
    final canto = Canto(titulo: 'O mesmo Deus', categoria: 2,
        htmlBase64: encodedLyrics('LEVANDO SEMPRE EM NOSSO CORPO O MORRER DE JESUS.'));
    final index = CantoSearchIndex([canto]);
    for (final query in ['poder de Jesus', 'PODER DE JESUS', 'poder de Jésus']) {
      final result = index.searchResults(query, category: 2).single;
      expect(result.canto, same(canto));
      expect(result.approximate, isTrue);
      expect(result.snippet, contains('MORRER DE JESUS'));
    }
    expect(index.search('poder de Jesus', category: 1), isEmpty);
  });

  test('short phrase substitutions keep their context and exact hits come first', () {
    final index = CantoSearchIndex([
      Canto(id: 2, titulo: 'Segundo', htmlBase64: encodedLyrics('O morrer de Jesus.')),
      Canto(id: 1, titulo: 'Primeiro', htmlBase64: encodedLyrics('O poder de Jesus.')),
      Canto(id: 3, titulo: 'Outro', htmlBase64: encodedLyrics('O nome de Jesus. A vida de Jesus. O morrer para todos.')),
    ]);
    expect(index.search('poder de Jesus').map((song) => song.id), [1, 2]);
    expect(index.search('poder Jesus de'), isEmpty);
    expect(index.search('poder de outro'), isEmpty);
  });


  test('Portuguese sound-based misspellings find original black lyric words', () {
    final songs = [
      Canto(id: 1, titulo: 'Primeiro', htmlBase64: encodedLyrics('Continuo chorando nesta manhã.')),
      Canto(id: 2, titulo: 'Segundo', htmlBase64: encodedLyrics('Sigo o caminho com carinho.')),
      Canto(id: 3, titulo: 'Terceiro', htmlBase64: encodedLyrics('Meu querido amigo.')),
    ];
    final index = CantoSearchIndex(songs);
    final crying = index.searchResults('xorando').first;
    expect(crying.canto.id, 1);
    expect(crying.approximate, isTrue);
    expect(crying.snippet, contains('chorando'));
    expect(index.search('kaminho').map((song) => song.id), contains(2));
    expect(index.search('kerido').map((song) => song.id), contains(3));
    expect(index.search('xerifando'), isEmpty);
  });

  test('correct spelling stays ahead of phonetic matches and categories apply', () {
    final index = CantoSearchIndex([
      Canto(id: 2, titulo: 'Segundo', categoria: 2, htmlBase64: encodedLyrics('Eu estou chorando.')),
      Canto(id: 1, titulo: 'Primeiro', categoria: 1, htmlBase64: encodedLyrics('Eu estou xorando.')),
    ]);
    final results = index.searchResults('xorando');
    expect(results.map((result) => result.canto.id), [1, 2]);
    expect(results.first.approximate, isFalse);
    expect(results.last.approximate, isTrue);
    expect(index.search('xorando', category: 2).single.id, 2);
  });

}
