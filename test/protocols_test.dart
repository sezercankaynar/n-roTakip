import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/protocols/protocols_screen.dart';
import 'package:norocep/features/protocols/unit_protocol.dart';
import 'package:shared_preferences/shared_preferences.dart';

void phone(WidgetTester t, {double height = 2400}) {
  t.view.physicalSize = Size(720, height);
  t.view.devicePixelRatio = 2.0;
  addTearDown(t.view.reset);
}

UnitProtocol sample({String id = '1', String title = 'Nimodipin hazırlama'}) =>
    UnitProtocol(
      id: id,
      title: title,
      kind: ProtocolKind.drugPrep,
      body: '## Hazırlama\n1. Işıktan koru\n- [ ] Set kontrol\n- [x] Etiket',
      updatedAt: DateTime(2026, 10, 22),
    );

void main() {
  test('paylaşılan metin geri okunur', () {
    final p = sample();
    final back = UnitProtocol.parseShared(p.toShareText(), id: '2');
    expect(back.title, p.title);
    expect(back.kind, ProtocolKind.drugPrep);
    expect(back.body, p.body);
  });

  test('düz metinde ilk satır başlık olur', () {
    final p = UnitProtocol.parseShared('# Status akışı\n- adım', id: 'x');
    expect(p.title, 'Status akışı');
    expect(p.kind, ProtocolKind.note);
    expect(p.body, '- adım');
  });

  test('kişisel veri uyarıları', () {
    expect(personalDataWarnings('Nimodipin 60 mg 4 saatte bir'), isEmpty);
    expect(personalDataWarnings('TC: 12345678901'), hasLength(2));
    expect(personalDataWarnings('Ara: 0532 123 45 67'), hasLength(1));
    expect(personalDataWarnings('Hasta adı: Ali'), hasLength(1));
  });

  test('onay kutuları simgeye çevrilir', () {
    expect(renderChecklist('- [ ] a\n  - [x] b'), '- ☐ a\n  - ☑ b');
    expect(renderChecklist('## A\n- \n1. \n- [ ] \n- b'), '## A\n- b');
  });

  test('kayıt ve yükleme', () async {
    SharedPreferences.setMockInitialValues({});
    final store = UnitProtocolStore();
    expect(await store.load(), isEmpty);
    await store.save([sample(), sample(id: '2', title: 'İkinci')]);
    final again = await store.load();
    expect(again.map((p) => p.title), ['Nimodipin hazırlama', 'İkinci']);
    expect(again.first.updatedAt, DateTime(2026, 10, 22));
  });

  test('şablonlarda tıbbi doz yok, yalnızca başlıklar', () {
    for (final (_, _, body) in protocolTemplates) {
      expect(body, isNot(contains(RegExp(r'\d+\s*mg'))));
    }
  });

  testWidgets('şablondan yeni protokol yazılır, açılır ve silinir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: ProtocolsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Henüz protokol yok'), findsOneWidget);
    expect(find.textContaining('Hasta adı, kimlik'), findsOneWidget);

    await tester.tap(find.text('Yeni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İlaç hazırlama'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Başlık'),
      'Nimodipin: eczanemizin talimatı',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Nimodipin: eczanemizin talimatı'), findsOneWidget);
    final saved = await UnitProtocolStore().load();
    expect(saved.single.kind, ProtocolKind.drugPrep);
    expect(saved.single.body, contains('## Hazırlama'));

    await tester.tap(find.text('Nimodipin: eczanemizin talimatı'));
    await tester.pumpAndSettle();
    expect(find.text('Hazırlama'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz protokol yok'), findsOneWidget);
    expect(await UnitProtocolStore().load(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kimlik numarası yazılınca uyarır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ProtocolEditor(
          initial: UnitProtocol(
            id: '1',
            title: '',
            kind: ProtocolKind.note,
            body: '',
            updatedAt: DateTime(2026),
          ),
        ),
      ),
    );
    await tester.enterText(find.widgetWithText(TextField, 'Başlık'), 'Not');
    await tester.enterText(
      find.widgetWithText(TextField, 'Metin'),
      'Yatak 3: 12345678901',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Kişisel veri olabilir'), findsOneWidget);
    await tester.tap(find.text('Düzelt'));
    await tester.pumpAndSettle();
    expect(find.text('Kişisel veri olabilir'), findsNothing);
  });

  testWidgets('düzenleme ve arama', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await UnitProtocolStore().save([
      sample(),
      UnitProtocol(
        id: '2',
        title: 'Status epileptikus akışı',
        kind: ProtocolKind.flow,
        body: '1. 0. dakika: hava yolu',
        updatedAt: DateTime(2026, 10, 1),
      ),
    ]);
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: ProtocolsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Tümü (2)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'epileptikus');
    await tester.pump();
    expect(find.text('Status epileptikus akışı'), findsOneWidget);
    expect(find.text('Nimodipin hazırlama'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('Akış şeması'));
    await tester.pump();
    expect(find.text('Nimodipin hazırlama'), findsNothing);

    await tester.tap(find.text('Status epileptikus akışı'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Başlık'),
      'Status akışı (2026)',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Status akışı (2026)'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final saved = await UnitProtocolStore().load();
    expect(saved.map((p) => p.title), contains('Status akışı (2026)'));
    expect(tester.takeException(), isNull);
  });
}
