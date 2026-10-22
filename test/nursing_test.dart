import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/nursing/emergency_codes.dart';
import 'package:norocep/features/nursing/emergency_codes_screen.dart';
import 'package:norocep/features/nursing/nursing_screen.dart';
import 'package:norocep/features/nursing/pressure_injury_screen.dart';
import 'package:norocep/features/scales/scale.dart';
import 'package:norocep/features/scales/scale_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void phone(WidgetTester t, {double height = 1520}) {
  t.view.physicalSize = Size(720, height);
  t.view.devicePixelRatio = 2.0;
  addTearDown(t.view.reset);
}

void main() {
  group('Morse', () {
    test('aralık 0–125', () {
      expect(morseFallScale.minTotal, 0);
      expect(morseFallScale.maxTotal, 125);
    });
    test('risk eşikleri', () {
      expect(morseFallScale.interpret(0).label, startsWith('Düşük'));
      expect(morseFallScale.interpret(24).label, startsWith('Düşük'));
      expect(morseFallScale.interpret(25).label, startsWith('Orta'));
      expect(morseFallScale.interpret(44).label, startsWith('Orta'));
      expect(morseFallScale.interpret(45).label, startsWith('Yüksek'));
    });
  });

  group('Norton', () {
    test('aralık 5–20', () {
      expect(nortonScale.minTotal, 5);
      expect(nortonScale.maxTotal, 20);
    });
    test('risk eşikleri', () {
      expect(nortonScale.interpret(20).label, startsWith('Düşük'));
      expect(nortonScale.interpret(15).label, startsWith('Düşük'));
      expect(nortonScale.interpret(14).label, startsWith('Risk var'));
      expect(nortonScale.interpret(12).label, startsWith('Yüksek'));
      expect(nortonScale.interpret(5).label, startsWith('Yüksek'));
    });
  });

  testWidgets('ölçek ekranı toplamı ve risk düzeyini gösterir', (tester) async {
    phone(tester, height: 6000);
    await tester.pumpWidget(
      MaterialApp(home: ScaleScreen(scale: morseFallScale)),
    );
    // Düşme öyküsü evet (25), ikincil tanı evet (15), diğerleri 0.
    await tester.tap(find.text('Evet').first);
    await tester.tap(find.text('Evet').at(1));
    await tester.tap(find.text('Yok / yatak istirahati / hemşire yardımıyla'));
    await tester.tap(find.text('Hayır').at(2));
    await tester.tap(find.text('Normal / yatak istirahati / hareketsiz'));
    await tester.tap(find.text('Kendi yürüme kapasitesinin farkında'));
    await tester.pump();
    expect(find.text('40'), findsOneWidget);
    expect(find.text('Orta risk (25–44)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('acil kod kaydı', () async {
    SharedPreferences.setMockInitialValues({});
    final store = EmergencyCodeStore();
    final codes = await store.load();
    expect(codes.map((c) => c.name), contains('Mavi Kod'));
    codes[0] = codes[0].copyWith(extension: '2222');
    await store.save(codes);
    final again = await store.load();
    expect(again.first.extension, '2222');
  });

  testWidgets('acil kod düzenlenir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: EmergencyCodesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mavi Kod'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Dahili numara'),
      '5555',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dahili: 5555'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hemşirelik menüsünden tanı açılır', (tester) async {
    phone(tester, height: 5000);
    await tester.pumpWidget(const MaterialApp(home: NursingScreen()));
    await tester.tap(find.text('Yutmada bozulma'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Yutma taraması yapılmadan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('altı bası yarası evresi tanımlı', () {
    expect(pressureStages, hasLength(6));
    expect(
      StageDepth.values.map((d) => pressureStages.where((s) => s.depth == d)),
      everyElement(hasLength(1)),
    );
  });

  testWidgets('bası yarası evre şemaları ve bölgeler çizilir', (tester) async {
    phone(tester, height: 9000);
    await tester.pumpWidget(const MaterialApp(home: PressureInjuryScreen()));
    await tester.pumpAndSettle();
    for (final s in pressureStages) {
      expect(find.text(s.name), findsOneWidget);
    }
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.tap(find.text('Risk bölgeleri'));
    await tester.pumpAndSettle();
    for (final p in riskPositions) {
      expect(find.text(p.name), findsOneWidget);
    }
    expect(find.text('5. Topuk'), findsOneWidget);
    await tester.tap(find.text('Bakım'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SSKIN'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menüden bakım rehberleri ve denetim soruları açılır', (
    tester,
  ) async {
    phone(tester, height: 5000);
    await tester.pumpWidget(const MaterialApp(home: NursingScreen()));
    for (final t in [
      'Fiziksel kısıtlama',
      'Denetim soruları ve cevapları (JCI, SKS)',
      'SBAR ile iletişim ve örnekler',
    ]) {
      await tester.tap(find.text(t));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Bası yarası: evreler (görsel) ve bakım'));
    await tester.pumpAndSettle();
    expect(find.text('Evre 1'), findsOneWidget);
  });
}
