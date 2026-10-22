import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/app_settings.dart';
import 'package:norocep/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('açılış uyarısı onaylanınca ana ekran açılır', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    await tester.pumpWidget(NoroCepApp(settings: settings));

    final button = find.widgetWithText(FilledButton, 'Devam et');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('CPR Zamanlayıcı'), findsOneWidget);
    expect(find.text('Ölçekler'), findsOneWidget);
    expect(find.text('EKG ve Resüsitasyon'), findsOneWidget);
    expect(find.text('İnfüzyon Hesaplayıcı'), findsOneWidget);
    expect(find.text('Vardiyam'), findsOneWidget);
    expect(settings.disclaimerAccepted, isTrue);
  });

  testWidgets('NIHSS seçimi toplamı günceller', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'disclaimer_accepted_v1': true});
    final settings = await AppSettings.load();
    await tester.pumpWidget(NoroCepApp(settings: settings));

    await tester.tap(find.text('Ölçekler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NIHSS'));
    await tester.pumpAndSettle();

    expect(find.text('Toplam: 0'), findsOneWidget);
    final coma = find.textContaining('tamamen yanıtsız');
    await tester.tap(coma, warnIfMissed: true);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Toplam: 3'), findsOneWidget);
  });
}
