import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/content/content_page.dart';
import 'package:norocep/features/drugs/drug_guide_screen.dart';

void main() {
  final files = Directory('assets/content/ilac')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  test('ilaç kartları bulunur', () {
    expect(files.length, greaterThanOrEqualTo(66));
  });

  for (final f in files) {
    test('${f.path}: kategori ve zorunlu bölümler', () {
      final page = ContentPage.parse(f.readAsStringSync(), source: f.path);
      expect(drugCategoryOrder, contains(page.category), reason: 'kategori');
      expect(page.body, contains('## Doz'));
      expect(page.body, contains('## Yan etkiler'));
      expect(page.body, contains('## Etki'));
    });
  }

  test('Türkçe karakterden bağımsız arama', () {
    expect(normalizeForSearch('İdarusizumab'), 'idarusizumab');
    expect(normalizeForSearch('ÇİĞŞÖÜ ı'), 'cigsou i');
  });

  testWidgets('liste kategorilere göre gelir ve aranır', (tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: DrugGuideScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Trombolitik'), findsNWidgets(2)); // düğme + başlık
    expect(find.text('Alteplaz (rt-PA)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'keppra');
    await tester.pumpAndSettle();
    expect(find.text('Levetirasetam'), findsOneWidget);
    expect(find.text('Alteplaz (rt-PA)'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ANTIEPILEPTIK');
    await tester.pumpAndSettle();
    expect(find.text('Fenitoin'), findsOneWidget);
    expect(find.text('Diazepam'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    final bloodChip = find.widgetWithText(ChoiceChip, 'Kan ve kan ürünleri');
    await tester.ensureVisible(bloodChip);
    await tester.pumpAndSettle();
    await tester.tap(bloodChip);
    await tester.pumpAndSettle();
    expect(find.text('Kan ve kan ürünleri transfüzyonu'), findsOneWidget);
    expect(find.text('Fenitoin'), findsNothing);
    final allChip = find.widgetWithText(ChoiceChip, 'Tümü (66)');
    await tester.ensureVisible(allChip);
    await tester.pumpAndSettle();
    await tester.tap(allChip);
    await tester.enterText(find.byType(TextField), 'fenitoin');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fenitoin'));
    await tester.pumpAndSettle();
    expect(find.textContaining('20 mg/kg IV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
