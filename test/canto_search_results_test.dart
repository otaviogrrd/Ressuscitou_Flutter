import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ressuscitou/helpers/canto_search.dart';
import 'package:ressuscitou/model/canto.dart';
import 'package:ressuscitou/widgets/canto_search_results.dart';

List<String> boldParts(CantoSearchResult result, String query) => result
    .snippetParts(query).where((part) => part.highlighted).map((part) => part.text).toList();

void main() {
  test('highlights original accented words without changing the excerpt', () {
    const text = '…Uma manhã de paz, com esperanc\u0327a e alegria.';
    final result = CantoSearchResult(Canto(), snippet: text);
    expect(boldParts(result, 'manha esperança'), ['manhã', 'esperanc\u0327a']);
    expect(result.snippetParts('manha esperança').map((part) => part.text).join(), text);
    expect(boldParts(result, 'inexistente'), isEmpty);
  });

  test('remembered phrases highlight anchors and typos highlight the actual word', () {
    final result = CantoSearchResult(Canto(), approximate: true,
        snippet: 'LEVANDO SEMPRE EM NOSSO CORPO O MORRER DE JESUS');
    expect(boldParts(result, 'levando sempre o poder de Jesus'), ['LEVANDO', 'SEMPRE', 'O', 'DE', 'JESUS']);
    final typo = CantoSearchResult(Canto(), approximate: true, snippet: 'Uma manhã de paz.');
    expect(boldParts(typo, 'manah de paz'), ['manhã', 'de', 'paz']);
  });

  testWidgets('snippet renders bold matches and preserves the full text in both themes', (tester) async {
    final result = CantoSearchResult(Canto(), snippet: 'Uma manhã de paz.');
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(brightness: brightness), home: Scaffold(
        body: ListTile(title: const Text('Canto'), subtitle: CantoSearchSnippet(result: result, query: 'manha')),
      )));
      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.textSpan!.toPlainText(), 'Uma manhã de paz.');
      final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.where((span) => span.style?.fontWeight == FontWeight.bold).map((span) => span.text), ['manhã']);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('separates approximate rows once, after exact rows', (tester) async {
    final exact = CantoSearchResult(Canto());
    final similar = CantoSearchResult(Canto(), approximate: true);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Column(children: [
      CantoSearchResultGroup(result: exact, child: const Text('Exato')),
      CantoSearchResultGroup(result: similar, previousResult: exact, child: const Text('Semelhante 1')),
      CantoSearchResultGroup(result: similar, previousResult: similar, child: const Text('Semelhante 2')),
    ]))));
    expect(find.text('Resultados semelhantes:'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Resultados semelhantes:')).dy,
        greaterThan(tester.getBottomLeft(find.text('Exato')).dy + 16));
    expect(tester.getTopLeft(find.text('Semelhante 1')).dy,
        greaterThan(tester.getBottomLeft(find.text('Resultados semelhantes:')).dy));
  });

  testWidgets('shows the divider for approximate-only results and hides it for exact results', (tester) async {
    for (final approximate in [false, true]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: CantoSearchResultGroup(
        result: CantoSearchResult(Canto(), approximate: approximate), child: const Text('Canto'),
      ))));
      expect(find.text('Resultados semelhantes:'), approximate ? findsOneWidget : findsNothing);
    }
  });

  test('short approximate phrases highlight the actual replaced word', () {
    final result = CantoSearchResult(Canto(), approximate: true,
        snippet: 'LEVANDO SEMPRE EM NOSSO CORPO O MORRER DE JESUS.');
    expect(boldParts(result, 'poder de Jesus'), ['MORRER', 'DE', 'JESUS']);
  });


  test('phonetic spelling highlights the original word from the song', () {
    final result = CantoSearchResult(Canto(), approximate: true, snippet: 'Eu sigo chorando.');
    expect(boldParts(result, 'xorando'), ['chorando']);
  });

}
