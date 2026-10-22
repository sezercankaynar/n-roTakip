import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/drugs/drug_page.dart';
import 'package:norocep/features/infusion/infusion.dart';
import 'package:norocep/features/infusion/infusion_screen.dart';

void phone(WidgetTester t, {double height = 3200}) {
  t.view.physicalSize = Size(720, height);
  t.view.devicePixelRatio = 2.0;
  addTearDown(t.view.reset);
}

void main() {
  group('sürekli infüzyon', () {
    test('noradrenalin 4 mg/250 mL, 70 kg, 0,1 µg/kg/dk → 26,25 mL/sa', () {
      const inf = Infusion(
        amount: 4,
        amountUnit: AmountUnit.mg,
        volumeMl: 250,
        unit: DoseUnit.mcgKgMin,
        weightKg: 70,
      );
      expect(inf.concentration, 16); // µg/mL
      expect(inf.rateFor(0.1), closeTo(26.25, 1e-9));
      expect(inf.doseFor(26.25), closeTo(0.1, 1e-9));
    });

    test('dopamin 400 mg/250 mL, 80 kg, 5 µg/kg/dk → 15 mL/sa', () {
      const inf = Infusion(
        amount: 400,
        amountUnit: AmountUnit.mg,
        volumeMl: 250,
        unit: DoseUnit.mcgKgMin,
        weightKg: 80,
      );
      expect(inf.rateFor(5), closeTo(15, 1e-9));
    });

    test('nikardipin 25 mg/250 mL, 5 mg/sa → 50 mL/sa', () {
      const inf = Infusion(
        amount: 25,
        amountUnit: AmountUnit.mg,
        volumeMl: 250,
        unit: DoseUnit.mgH,
      );
      expect(inf.rateFor(5), closeTo(50, 1e-9));
    });

    test('amiodaron 900 mg/500 mL, 1 mg/dk → 33,3 mL/sa', () {
      const inf = Infusion(
        amount: 900,
        amountUnit: AmountUnit.mg,
        volumeMl: 500,
        unit: DoseUnit.mgMin,
      );
      expect(inf.rateFor(1), closeTo(33.33, 0.01));
    });

    test('heparin 25000 ünite/500 mL, 70 kg, 18 ünite/kg/sa → 25,2 mL/sa', () {
      const inf = Infusion(
        amount: 25000,
        amountUnit: AmountUnit.unit,
        volumeMl: 500,
        unit: DoseUnit.unitKgH,
        weightKg: 70,
      );
      expect(inf.rateFor(18), closeTo(25.2, 1e-9));
    });

    test('deksmedetomidin 200 µg/50 mL, 70 kg, 0,5 µg/kg/sa → 8,75 mL/sa', () {
      const inf = Infusion(
        amount: 200,
        amountUnit: AmountUnit.mcg,
        volumeMl: 50,
        unit: DoseUnit.mcgKgH,
        weightKg: 70,
      );
      expect(inf.rateFor(0.5), closeTo(8.75, 1e-9));
    });

    test('mg torbayla µg dozu ve tersi çevrilir', () {
      expect(AmountUnit.mg.convert(4, AmountUnit.mcg), 4000);
      expect(AmountUnit.mcg.convert(500, AmountUnit.mg), 0.5);
      expect(
        () => AmountUnit.unit.convert(1, AmountUnit.mg),
        throwsArgumentError,
      );
    });

    test('kilo gereken birimde kilo yoksa geçersiz', () {
      const inf = Infusion(
        amount: 4,
        amountUnit: AmountUnit.mg,
        volumeMl: 250,
        unit: DoseUnit.mcgKgMin,
      );
      expect(inf.isValid, isFalse);
    });
  });

  test('her infüzyon ilacı tutarlı', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final d in infusionDrugs) {
      expect(d.unit.compatibleWith(d.prepUnit), isTrue, reason: d.name);
      expect(d.high, isNotNull, reason: d.name);
      if (d.low != null) expect(d.low! < d.high!, isTrue, reason: d.name);
      if (d.max != null) expect(d.max! >= d.high!, isTrue, reason: d.name);
      if (d.asset != null) {
        await rootBundle.loadString(d.asset!, cache: false); // sayfa var olmalı
      }
    }
    for (final d in loadingDrugs) {
      if (d.asset != null) await rootBundle.loadString(d.asset!, cache: false);
    }
  });

  group('yükleme dozu', () {
    test('levetirasetam en fazla 4500 mg', () {
      final lev = loadingDrugs.firstWhere((d) => d.name == 'Levetirasetam');
      expect(lev.totalMg(60), 3600);
      expect(lev.totalMg(90), 4500);
    });
    test('fenitoin 70 kg → 1400 mg, en az 28 dakika', () {
      final phe = loadingDrugs.firstWhere((d) => d.name == 'Fenitoin');
      expect(phe.totalMg(70), 1400);
      expect(phe.minMinutes(70), 28);
    });
  });

  test('mL/sa ve damla', () {
    expect(mlPerHour(500, 240), 125);
    expect(dropsPerMinute(125, 20), closeTo(41.67, 0.01));
    expect(dropsPerMinute(100, 60), 100);
  });

  test('sayı biçimi', () {
    expect(formatNumber(26.25, maxDecimals: 1), '26,3');
    expect(formatNumber(15), '15');
    expect(formatNumber(0.05), '0,05');
    expect(parseNumber('0,1'), 0.1);
    expect(parseNumber('abc'), isNull);
  });

  testWidgets('ilaç seçilip dozdan hız hesaplanır', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(home: InfusionScreen(drug: infusionDrugs.first)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Doz birimi: µg/kg/dk'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Hasta kilosu'),
      '70',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'İstenen doz'),
      '0,1',
    );
    await tester.pump();
    expect(find.textContaining('26,3  mL/sa'), findsOneWidget);
    expect(find.text('Doz tablosu (bu hazırlıkla)'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'İstenen doz'), '2');
    await tester.pump();
    expect(find.textContaining('Olağan aralığın dışında'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hızdan doza', (tester) async {
    phone(tester);
    final nik = infusionDrugs.firstWhere((d) => d.name == 'Nikardipin');
    await tester.pumpWidget(MaterialApp(home: InfusionScreen(drug: nik)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hızdan doza'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Pompa hızı'), '200');
    await tester.pump();
    expect(find.textContaining('20  mg/sa'), findsOneWidget);
    expect(find.textContaining('en yüksek dozun üstünde'), findsOneWidget);
  });

  testWidgets('fenitoin çok hızlı verilirse uyarır', (tester) async {
    phone(tester);
    final phe = loadingDrugs.firstWhere((d) => d.name == 'Fenitoin');
    await tester.pumpWidget(
      MaterialApp(home: InfusionScreen(loading: phe, initialTab: 1)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Hasta kilosu'),
      '70',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Süre'), '15');
    await tester.pump();
    expect(find.textContaining('Toplam doz: 1400 mg'), findsOneWidget);
    expect(find.textContaining('En az 28 dakikada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('damla hesabı', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      const MaterialApp(home: InfusionScreen(initialTab: 2)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Verilecek hacim'),
      '500',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Süre'), '4');
    await tester.pump();
    expect(find.textContaining('125  mL/sa'), findsOneWidget);
    expect(find.text('42 damla/dk'), findsOneWidget);
    expect(find.text('125 damla/dk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ilaç sayfasında infüzyon kartı görünür', (tester) async {
    phone(tester, height: 6000);
    await tester.pumpWidget(
      MaterialApp(home: drugPage('assets/content/ilac/dopamin.md', 'Dopamin')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Doz birimi: µg/kg/dk'), findsOneWidget);
    await tester.tap(find.text('Hızı hesapla'));
    await tester.pumpAndSettle();
    expect(find.text('İnfüzyon Hesaplayıcı'), findsOneWidget);
  });
}
