import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/labs/labs.dart';
import 'package:norocep/features/labs/labs_screen.dart';

void phone(WidgetTester t, {double height = 2400}) {
  t.view.physicalSize = Size(720, height);
  t.view.devicePixelRatio = 2.0;
  addTearDown(t.view.reset);
}

LabTest byName(String n) => labTests.firstWhere((t) => t.name.startsWith(n));

void main() {
  test('sodyum düzeyleri', () {
    final na = byName('Sodyum');
    expect(na.classify(118), LabLevel.criticalLow);
    expect(na.classify(130), LabLevel.low);
    expect(na.classify(140), LabLevel.normal);
    expect(na.classify(150), LabLevel.high);
    expect(na.classify(162), LabLevel.criticalHigh);
  });

  test('potasyum ve trombosit kritik sınırları', () {
    expect(byName('Potasyum').classify(6.5), LabLevel.criticalHigh);
    expect(byName('Potasyum').classify(2.5), LabLevel.criticalLow);
    expect(byName('Trombosit').classify(15), LabLevel.criticalLow);
    expect(byName('Trombosit').classify(90), LabLevel.low);
  });

  test('her tetkik tutarlı', () {
    final names = <String>{};
    for (final t in labTests) {
      expect(names.add(t.name), isTrue, reason: 'tekrar: ${t.name}');
      expect(t.low <= t.high, isTrue, reason: t.name);
      if (t.critLow != null) {
        expect(t.critLow! <= t.low, isTrue, reason: t.name);
      }
      if (t.critHigh != null) {
        expect(t.critHigh! >= t.high, isTrue, reason: t.name);
      }
    }
    for (final g in LabGroup.values) {
      expect(labTests.any((t) => t.group == g), isTrue, reason: g.label);
    }
  });

  test('metin biçimi', () {
    expect(byName('Sodyum').normalText, '135–145');
    expect(byName('Sodyum').criticalText, '< 120  ·  > 160');
    expect(byName('pH').normalText, '7,35–7,45');
    expect(byName('Kreatinin').criticalText, isNull);
  });

  test('düzeltilmiş kalsiyum', () {
    expect(correctedCalcium(8.0, 2.0), closeTo(9.6, 1e-9));
    expect(correctedCalcium(9.0, 4.0), 9.0);
  });

  testWidgets('değer girilince kritik uyarısı çıkar', (tester) async {
    phone(tester, height: 12000);
    await tester.pumpWidget(const MaterialApp(home: LabsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Nörolojide önemli sınırlar'), findsOneWidget);
    await tester.tap(find.text('Sodyum (Na)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Hastanın değeri'),
      '118',
    );
    await tester.pump();
    expect(find.text('KRİTİK DÜŞÜK'), findsOneWidget);
    expect(find.textContaining('Hekime hemen bildirin'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Hastanın değeri'),
      '140',
    );
    await tester.pump();
    expect(find.text('Normal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arama süzer', (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: LabsScreen()));
    await tester.enterText(find.byType(TextField).first, 'inr');
    await tester.pump();
    expect(find.text('INR'), findsOneWidget);
    expect(find.text('Sodyum (Na)'), findsNothing);
    expect(find.text('Nörolojide önemli sınırlar'), findsNothing);
  });

  testWidgets('sodyum hızı hesabı uyarır', (tester) async {
    phone(tester, height: 9000);
    await tester.pumpWidget(const MaterialApp(home: LabsScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Önceki Na'), '118');
    await tester.enterText(find.widgetWithText(TextField, 'Şimdiki Na'), '126');
    await tester.enterText(find.widgetWithText(TextField, 'Arada'), '12');
    await tester.pump();
    expect(find.textContaining('Çok hızlı değişim'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
