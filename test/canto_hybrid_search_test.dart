import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ressuscitou/helpers/canto_hybrid_search.dart';
import 'package:ressuscitou/model/canto.dart';

Canto sample(String key, String text, {int category = 1}) => Canto(html: key,
    titulo: key, categoria: category, htmlBase64: base64Encode(utf8.encode(
        '<html><body><font color="#000000">$text</font></body></html>')));
Map<String, Object> hit(Canto song, String snippet) => {'html': song.html,
    'source_hash': sha256.convert(utf8.encode('${song.htmlBase64}\n${song.extBase64}')).toString(), 'snippet': snippet};
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('returns local search immediately and appends verified semantic suggestions', () async {
    final song = sample('PRIMEIRO', 'Tenho esperança no futuro.');
    var changes = 0;
    final engine = CantoHybridSearch([song], onChanged: () => changes++,
        endpoint: 'https://search.example/search', debounce: Duration.zero,
        client: MockClient((request) async {
          expect(jsonDecode(request.body)['query'], 'confiança no amanhã');
          return http.Response(jsonEncode({'results': [hit(song, 'Tenho esperança no futuro.')]}), 200);
        }));
    expect(engine.search('confiança no amanhã'), isEmpty);
    await settle();
    expect(changes, 1);
    final results = engine.search('confiança no amanhã');
    expect(results.single.canto, same(song));
    expect(results.single.approximate, isTrue);
    engine.dispose();
  });

  test('ignores invented snippets and stale catalog hashes', () async {
    final song = sample('PRIMEIRO', 'Tenho esperança no futuro.');
    final engine = CantoHybridSearch([song], onChanged: () {},
        endpoint: 'https://search.example/search', debounce: Duration.zero,
        client: MockClient((_) async => http.Response(jsonEncode({'results': [
          hit(song, 'Texto que não existe no canto.'),
          {...hit(song, 'Tenho esperança no futuro.'), 'source_hash': 'outdated'},
        ]}), 200)));
    engine.search('confiança no amanhã');
    await settle();
    expect(engine.search('confiança no amanhã'), isEmpty);
    engine.dispose();
  });

  test('network failure keeps local results and an unconfigured URL makes no request', () async {
    final song = sample('PRIMEIRO', 'Uma manhã de paz.');
    for (final endpoint in ['', 'https://search.example/search']) {
      var calls = 0;
      final engine = CantoHybridSearch([song], endpoint: endpoint,
          debounce: Duration.zero, onChanged: () {}, client: MockClient((_) async {
            calls++;
            throw http.ClientException('offline');
          }));
      expect(engine.search('manhã de paz').single.canto, same(song));
      await settle();
      expect(engine.search('manhã de paz').single.canto, same(song));
      expect(calls, endpoint.isEmpty ? 0 : 1);
      engine.dispose();
    }
  });

  test('responses to older queries cannot replace newer results', () async {
    final song = sample('PRIMEIRO', 'Tenho esperança no futuro.');
    final delayed = Completer<http.Response>();
    var changes = 0;
    final engine = CantoHybridSearch([song], onChanged: () => changes++,
        endpoint: 'https://search.example/search', debounce: Duration.zero,
        client: MockClient((_) => delayed.future));
    engine.search('confiança no amanhã');
    await settle();
    engine.search('');
    delayed.complete(http.Response(jsonEncode({'results': [hit(song, 'Tenho esperança no futuro.')]}), 200));
    await settle();
    expect(changes, 0);
    expect(engine.search('').single.approximate, isFalse);
    engine.dispose();
  });

  test('deduplicates suggestions and preserves current category', () async {
    final first = sample('PRIMEIRO', 'Uma manhã de paz.');
    final second = sample('SEGUNDO', 'Outra manhã de paz.', category: 2);
    final engine = CantoHybridSearch([first, second], onChanged: () {},
        endpoint: 'https://search.example/search', debounce: Duration.zero,
        client: MockClient((_) async => http.Response(jsonEncode({'results': [
          hit(first, 'Uma manhã de paz.'), hit(second, 'Outra manhã de paz.'), hit(first, 'Uma manhã de paz.'),
        ]}), 200)));
    engine.search('manhã de paz', category: 1);
    await settle();
    final results = engine.search('manhã de paz', category: 1);
    expect(results, hasLength(1));
    expect(results.single.canto, same(first));
    expect(results.single.approximate, isFalse);
    engine.dispose();
  });
}
