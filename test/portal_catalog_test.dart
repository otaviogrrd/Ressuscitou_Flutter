import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ressuscitou/helpers/song_presentation.dart';
import 'package:ressuscitou/model/canto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('category overrides use unique HTML keys, not colliding legacy IDs', () {
    final first = Canto(id: 227, html: 'A ESPADA', categoria: 1,
        htmlBase64: 'original', extBase64: 'extended');
    final second = Canto(id: 227, html: 'ALELUIA PASCAL II', categoria: 4);
    CantoService.applyPortalCategories([first, second], {'A ESPADA': 2});
    expect(first.categoria, 2);
    expect(second.categoria, 4);
    expect(first.id, 227);
    expect(second.id, 227);
    expect(first.htmlBase64, 'original');
    expect(first.extBase64, 'extended');
  });

  test('all bundled HTML bodies keep exact whitespace, notes and markers', () async {
    final data = (jsonDecode(await rootBundle.loadString('assets/cantos.json')) as Map<String, dynamic>)['cantos'] as List;
    for (final record in data) {
      final canto = Canto.fromJson(record as Map<String, dynamic>);
      for (final encoded in [canto.htmlBase64, canto.extBase64]) {
        final original = utf8.decode(base64Decode(encoded));
        final body = RegExp(r'<body\b', caseSensitive: false).firstMatch(original);
        expect(body, isNotNull, reason: canto.html);
        final originalBody = original.substring(body!.start);
        for (final dark in [false, true]) {
          final rendered = presentSongHtml(original, category: canto.categoria, dark: dark);
          expect(rendered, contains(originalBody), reason: '${canto.html}: body changed');
          for (final marker in ['@transp@', '@capot@']) {
            expect(marker.allMatches(rendered).length, marker.allMatches(original).length);
          }
        }
      }
    }
  });
}
