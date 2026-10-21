import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/cpr/cpr_screen.dart';

void main() {
  testWidgets('nabız kontrolü ve atropin kaydedilir, özet gösterilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CprScreen()));
    await tester.tap(find.text('BAŞLAT'));
    await tester.pump();

    expect(find.text('Nabız kontrolü · 0 kez'), findsOneWidget);
    expect(find.text('Adrenalin 1 mg · 0 kez'), findsOneWidget);

    await tester.tap(find.text('Nabız kontrolü yapıldı'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Ritim belirtmeden devam et'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Nabız kontrolü · 1 kez'), findsOneWidget);
    expect(find.text('Nabız kontrolü (ek)'), findsOneWidget);

    await tester.tap(find.text('Atropin (0)'));
    await tester.pump();
    expect(find.text('Atropin (1)'), findsOneWidget);

    await tester.tap(find.text('ROSC'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('CPR Özeti'), findsOneWidget);
    expect(find.textContaining('Atropin: 1 doz'), findsOneWidget);
  });

  testWidgets('telefon ekranında taşma olmadan çizilir', (tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CprScreen()));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('BAŞLAT'));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text("CPR'ı sonlandır"));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sonlandır'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('CPR Özeti'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
