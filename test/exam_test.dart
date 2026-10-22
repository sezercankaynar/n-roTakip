import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/exam/exam_screen.dart';
import 'package:norocep/features/exam/gcs.dart';
import 'package:norocep/features/exam/gcs_screen.dart';
import 'package:norocep/features/exam/mrs_screen.dart';
import 'package:norocep/features/exam/pupil_gauge_screen.dart';

GcsOption opt(String code, int? score) => gcsComponents
    .firstWhere((c) => c.code == code)
    .options
    .firstWhere((o) => o.score == score);

void main() {
  void phone(WidgetTester t, {double height = 1520}) {
    t.view.physicalSize = Size(720, height);
    t.view.devicePixelRatio = 2.0;
    addTearDown(t.view.reset);
  }

  test('GKS aralığı 3–15', () {
    final max = GcsResult({
      'E': opt('E', 4),
      'V': opt('V', 5),
      'M': opt('M', 6),
    });
    expect(max.total, 15);
    expect(max.summary(), 'GKS 15 (E4 V5 M6)');
    final min = GcsResult({
      'E': opt('E', 1),
      'V': opt('V', 1),
      'M': opt('M', 1),
    });
    expect(min.total, 3);
    expect(min.severity, startsWith('Ağır'));
  });

  test('şiddet sınırları', () {
    String? sev(int e, int v, int m) =>
        GcsResult({'E': opt('E', e), 'V': opt('V', v), 'M': opt('M', m)})
            .severity;
    expect(sev(4, 5, 4), startsWith('Hafif')); // 13
    expect(sev(4, 4, 4), startsWith('Orta')); // 12
    expect(sev(2, 2, 5), startsWith('Orta')); // 9
    expect(sev(2, 2, 4), startsWith('Ağır')); // 8
  });

  test('entübe hastada toplam verilmez, VT yazılır', () {
    final r = GcsResult({
      'E': opt('E', 3),
      'V': opt('V', null),
      'M': opt('M', 5),
    });
    expect(r.complete, isTrue);
    expect(r.total, isNull);
    expect(r.summary(), 'GKS: E3 VT M5');
  });

  test('eksik değerlendirme', () {
    final r = GcsResult({'E': opt('E', 3)});
    expect(r.complete, isFalse);
    expect(r.summary(), 'GKS: E3 V? M?');
  });

  testWidgets('GKS ekranı', (tester) async {
    phone(tester, height: 5000);
    await tester.pumpWidget(const MaterialApp(home: GcsScreen()));
    await tester.tap(find.text('Sesle'));
    await tester.tap(find.text('Konfüze'));
    await tester.pump();
    await tester.tap(find.text('Ağrıyı lokalize ediyor'));
    await tester.pump();
    expect(find.text('12'), findsOneWidget);
    expect(find.text('GKS 12 (E3 V4 M5)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mRS ve pupil cetveli çizilir', (tester) async {
    phone(tester, height: 3000);
    await tester.pumpWidget(const MaterialApp(home: MrsScreen()));
    await tester.tap(find.textContaining('Orta engellilik'));
    await tester.pump();
    expect(find.text('mRS 3'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: PupilGaugeScreen()));
    expect(find.text('1 mm'), findsOneWidget);
    expect(find.text('9 mm'), findsOneWidget);
    expect(dpPerMm, closeTo(6.3, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('muayene menüsünden içerik açılır', (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: ExamScreen()));
    await tester.tap(find.text('Kraniyal Sinirler'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hipoglossal'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
