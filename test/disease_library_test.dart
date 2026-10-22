import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/content/content_page.dart';
import 'package:norocep/features/diseases/disease_library_screen.dart';

void main() {
  test('her hastalık kartı var ve zorunlu bölümleri içeriyor', () {
    for (final (_, asset) in diseaseEntries) {
      final page = ContentPage.parse(
        File(asset).readAsStringSync(),
        source: asset,
      );
      expect(page.body, contains('## Tanım'), reason: asset);
      expect(page.body, contains('## Belirtiler'), reason: asset);
      expect(
        RegExp(r'^## .*[Tt]edavi', multiLine: true).hasMatch(page.body),
        isTrue,
        reason: '$asset: tedavi bölümü',
      );
      expect(page.body, contains('## Komplikasyonlar'), reason: asset);
    }
    expect(diseaseEntries.length, 15);
  });

  testWidgets('liste ve arama', (tester) async {
    tester.view.physicalSize = const Size(720, 3000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: DiseaseLibraryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('İskemik İnme'), findsOneWidget);
    expect(find.text('Guillain-Barré Sendromu'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'gbs');
    await tester.pumpAndSettle();
    expect(find.text('Guillain-Barré Sendromu'), findsOneWidget);
    expect(find.text('İskemik İnme'), findsNothing);

    await tester.enterText(find.byType(TextField), 'noromuskuler');
    await tester.pumpAndSettle();
    expect(find.text('Miyastenia Gravis ve Miyastenik Kriz'), findsOneWidget);
    expect(find.text('Amiyotrofik Lateral Skleroz (ALS)'), findsOneWidget);

    await tester.tap(find.text('Miyastenia Gravis ve Miyastenik Kriz'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SpO₂ geç düşer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
