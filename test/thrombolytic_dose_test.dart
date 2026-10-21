import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/stroke/thrombolytic_dose.dart';
import 'package:norocep/features/stroke/thrombolytic_dose_screen.dart';

void main() {
  group('alteplaz', () {
    test('70 kg: 63 mg = 6,3 bolus + 56,7 infüzyon', () {
      final d = AlteplaseDose.forWeight(70);
      expect(d.totalMg, 63);
      expect(d.bolusMg, 6.3);
      expect(d.infusionMg, 56.7);
      expect(d.infusionRateMlPerHour, 56.7);
      expect(d.capped, isFalse);
      expect(d.vials, 2);
      expect(d.preparedMg, 100);
      expect(d.discardMg, 37);
    });

    test('bolus + infüzyon her zaman toplam dozu verir', () {
      for (var kg = 30.0; kg <= 120; kg += 0.5) {
        final d = AlteplaseDose.forWeight(kg);
        expect(
          d.bolusMg + d.infusionMg,
          closeTo(d.totalMg, 1e-9),
          reason: '$kg',
        );
        expect(d.totalMg, lessThanOrEqualTo(90));
        expect(d.discardMg, greaterThanOrEqualTo(0));
      }
    });

    test('100 kg üzeri 90 mg ile sınırlanır', () {
      final d = AlteplaseDose.forWeight(120);
      expect(d.totalMg, 90);
      expect(d.bolusMg, 9);
      expect(d.infusionMg, 81);
      expect(d.capped, isTrue);
      expect(AlteplaseDose.forWeight(100).capped, isFalse);
    });

    test('flakon seçimi ve atılacak miktar', () {
      final d = AlteplaseDose.forWeight(72, vialMg: 20); // 64,8 mg
      expect(d.totalMg, 64.8);
      expect(d.vials, 4);
      expect(d.discardMg, 15.2);
    });
  });

  group('tenekteplaz', () {
    test('70 kg: 17,5 mg = 3,5 mL', () {
      final d = TenecteplaseDose.forWeight(70);
      expect(d.doseMg, 17.5);
      expect(d.doseMl, 3.5);
      expect(d.vialMl, 5);
      expect(d.discardMl, 1.5);
    });

    test('yuvarlama: 73 kg → 18,3 mg', () {
      expect(TenecteplaseDose.forWeight(73).doseMg, 18.3);
    });

    test('100 kg ve üzeri 25 mg ile sınırlanır', () {
      expect(TenecteplaseDose.forWeight(100).doseMg, 25);
      final d = TenecteplaseDose.forWeight(130, vialMg: 50);
      expect(d.doseMg, 25);
      expect(d.capped, isTrue);
      expect(d.doseMl, 5);
      expect(d.discardMl, 5);
    });
  });

  test('kilo girişi ve sayı biçimi', () {
    expect(parseWeight('72,5'), 72.5);
    expect(parseWeight(' 80 '), 80);
    expect(parseWeight('15'), isNull);
    expect(parseWeight('abc'), isNull);
    expect(formatNumber(64.8), '64,8');
    expect(formatNumber(90), '90');
  });

  testWidgets('ekranda doz hesaplanır', (tester) async {
    tester.view.physicalSize = const Size(720, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ThrombolyticDoseScreen()));
    await tester.enterText(find.byType(TextField), '70');
    await tester.pump();
    expect(find.text('63 mg'), findsOneWidget);
    expect(find.text('6,3 mL'), findsOneWidget);
    expect(find.text('56,7 mL/saat'), findsOneWidget);

    await tester.tap(find.text('Tenekteplaz'));
    await tester.pump();
    expect(find.text('17,5 mg'), findsOneWidget);
    expect(find.text('3,5 mL'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '10');
    await tester.pump();
    expect(find.textContaining('Geçerli bir kilo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
