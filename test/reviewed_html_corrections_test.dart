import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ressuscitou/model/canto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repairs the three reviewed songs in both variants without losing repetitions or IDs', () async {
    final raw = jsonDecode(await rootBundle.loadString('assets/cantos.json')) as List;
    final songs = raw.map((row) => Canto.fromJson(row as Map<String, dynamic>)).toList();
    final data = jsonDecode(await rootBundle.loadString('assets/reviewed_html_corrections.json')) as Map<String, dynamic>;
    final rules = data['songs'] as Map<String, dynamic>;
    final before = {for (final song in songs) song.html: [song.htmlBase64, song.extBase64]};
    CantoService.applyReviewedHtmlCorrections(songs, rules);
    var changed = 0;
    for (final song in songs) {
      final originals = before[song.html]!;
      final current = [song.htmlBase64, song.extBase64];
      for (var index = 0; index < 2; index++) {
        if (current[index] == originals[index]) continue;
        changed++;
        final old = utf8.decode(base64Decode(originals[index]));
        final updated = utf8.decode(base64Decode(current[index]));
        expect('\n'.allMatches(updated).length, '\n'.allMatches(old).length);
        for (final marker in ['@transp@', '@capot@', '<H1>', '#FF0000', 'white-space:pre', 'font-family:monospace']) {
          expect(marker.allMatches(updated).length, marker.allMatches(old).length);
        }
        final field = index == 0 ? 'html_base64' : 'ext_base64';
        final patches = (rules[song.html] as Map<String, dynamic>)[field]['patches'] as List;
        for (final patch in patches) { expect(updated, contains(patch['new'] as String)); }
      }
    }
    expect(changed, 6);
    final once = songs.map((song) => [song.htmlBase64, song.extBase64]).toList();
    CantoService.applyReviewedHtmlCorrections(songs, rules);
    expect(songs.map((song) => [song.htmlBase64, song.extBase64]).toList(), once);
    expect(songs.map((song) => song.id), raw.map((row) => row['id']));
  });

  test('never overwrites a newer or customized HTML variant', () async {
    final data = jsonDecode(await rootBundle.loadString('assets/reviewed_html_corrections.json')) as Map<String, dynamic>;
    final rules = data['songs'] as Map<String, dynamic>;
    final key = rules.keys.first;
    final song = Canto(html: key, htmlBase64: base64Encode(utf8.encode('versão nova')),
        extBase64: base64Encode(utf8.encode('versão estendida nova')));
    final original = [song.htmlBase64, song.extBase64];
    CantoService.applyReviewedHtmlCorrections([song], rules);
    expect([song.htmlBase64, song.extBase64], original);
  });
}
