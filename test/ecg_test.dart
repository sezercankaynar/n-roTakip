import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/ecg/ecg_screen.dart';
import 'package:norocep/features/ecg/ecg_wave.dart';
import 'package:norocep/features/ecg/rhythms.dart';

void phone(WidgetTester t, {double height = 2400}) {
  t.view.physicalSize = Size(720, height);
  t.view.devicePixelRatio = 2.0;
  addTearDown(t.view.reset);
}

/// [seconds] sürede taban çizgisinin üstüne çıkan R tepelerini sayar.
int countPeaks(EcgSignal s, {double seconds = 6, double threshold = 0.6}) {
  var n = 0;
  var above = false;
  for (var t = 0.0; t < seconds; t += 0.002) {
    final v = s.at(t);
    if (!above && v > threshold) {
      n++;
      above = true;
    } else if (above && v < threshold * 0.5) {
      above = false;
    }
  }
  return n;
}

void main() {
  group('sentetik EKG', () {
    test('sinüs 60/dk → 6 sn\'de 6 atım', () {
      expect(countPeaks(EcgSignal.sinus(60)), 6);
    });
    test('sinüs 120/dk → 6 sn\'de 12 atım', () {
      expect(countPeaks(EcgSignal.sinus(120)), 12);
    });
    test('tam blokta ventrikül hızı yavaş', () {
      expect(countPeaks(EcgSignal.completeBlock()), lessThanOrEqualTo(4));
    });
    test('asistoli düz', () {
      for (var t = 0.0; t < 6; t += 0.01) {
        expect(EcgSignal.asystole().at(t).abs(), lessThan(0.05));
      }
    });
    test('AF düzensiz', () {
      final s = EcgSignal.atrialFib();
      final peaks = <double>[];
      var above = false;
      for (var t = 0.0; t < 6; t += 0.002) {
        final v = s.at(t);
        if (!above && v > 0.6) {
          peaks.add(t);
          above = true;
        } else if (above && v < 0.3) {
          above = false;
        }
      }
      final rr = [
        for (var i = 1; i < peaks.length; i++) peaks[i] - peaks[i - 1],
      ];
      final spread =
          rr.reduce((a, b) => a > b ? a : b) -
          rr.reduce((a, b) => a < b ? a : b);
      expect(spread, greaterThan(0.15));
    });
  });

  test('ritim listesi tam', () {
    expect(rhythms.length, greaterThanOrEqualTo(15));
    final arrest = rhythms
        .where(
          (r) =>
              r.urgency == RhythmUrgency.arrestShock ||
              r.urgency == RhythmUrgency.arrestNoShock,
        )
        .map((r) => r.name);
    expect(arrest, containsAll(['Asistoli', 'Ventriküler fibrilasyon (VF)']));
    for (final r in rhythms) {
      expect(r.actions, isNotEmpty, reason: r.name);
      r.signal().at(1); // üretici hata vermemeli
    }
  });

  testWidgets('ritim listesi, detay ve algoritma açılır', (tester) async {
    phone(tester, height: 12000);
    await tester.pumpWidget(const MaterialApp(home: EcgScreen()));
    await tester.pumpAndSettle();
    for (final r in rhythms) {
      expect(find.text(r.name), findsOneWidget);
    }
    await tester.tap(find.text('Asistoli'));
    await tester.pumpAndSettle();
    expect(find.text('ŞOK VERİLMEZ, atropin önerilmez'), findsOneWidget);
    expect(find.text('CPR Zamanlayıcıyı aç'), findsOneWidget);
    await tester.tap(find.text('İlgili algoritma'));
    await tester.pumpAndSettle();
    expect(find.text('Kardiyak Arrest Algoritması'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EKG okuma: hız hesaplayıcı', (tester) async {
    phone(tester, height: 5000);
    await tester.pumpWidget(const MaterialApp(home: EcgScreen(initialTab: 1)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4');
    await tester.pump();
    expect(find.text('Kalp hızı ≈ 75 /dk'), findsOneWidget);
    await tester.tap(find.text('6 saniye'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '13');
    await tester.pump();
    expect(find.text('Kalp hızı ≈ 130 /dk (taşikardi)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resüsitasyon sayfaları açılır', (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: EcgScreen(initialTab: 2)));
    await tester.pumpAndSettle();
    for (final (title, _, _) in resusPages) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });
}
