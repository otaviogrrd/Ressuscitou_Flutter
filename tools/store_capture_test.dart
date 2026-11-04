import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:ressuscitou/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture App Store screens', (tester) async {
    await globals.inicial();
    await globals.prefs.setBool('TermosIniciaisLidos', true);
    await globals.prefs.setBool('msgTabletLida', true);
    await globals.prefs.setString(
      'MessageLida',
      DateTime.now().toIso8601String().split('T').first,
    );
    await tester.pumpWidget(app.MainPage());

    final search = find.byIcon(Icons.search);
    for (
      var attempt = 0;
      attempt < 45 && search.evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(search, findsOneWidget);
    await binding.takeScreenshot('catalogo');

    await tester.tap(search);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'ressuscitou');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('busca');

    final result = find.text('RESSUSCITOU', findRichText: true).hitTestable();
    expect(result, findsWidgets);
    await tester.tap(result.first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('canto');

    Navigator.of(tester.element(find.byType(BackButton).first)).pop();
    await tester.pumpAndSettle();
    final menu = find.byTooltip('Abrir menu de navegação');
    final index = find.text('Índice Litúrgico');
    if (index.hitTestable().evaluate().isEmpty) {
      final drawer = find.byType(DrawerButton);
      await tester.tap(drawer.evaluate().isNotEmpty ? drawer : menu);
      await tester.pumpAndSettle();
    }
    await tester.tap(index.hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsWidgets);
    await binding.takeScreenshot('indice-liturgico');
  });
}
