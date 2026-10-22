import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/content/content_screen.dart';
import 'package:norocep/features/protocols/unit_protocol.dart';
import 'package:norocep/features/search/favorites.dart';
import 'package:norocep/features/search/search_index.dart';
import 'package:norocep/features/search/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void phone(WidgetTester t, {double height = 3000}) {
  t.view.physicalSize = Size(720, height);
  t.view.devicePixelRatio = 2.0;
  addTearDown(t.view.reset);
}

SearchItem item(
  String id,
  String title, {
  List<String> k = const [],
  String body = '',
}) => SearchItem(
  id: id,
  title: title,
  section: 'Test',
  icon: Icons.abc,
  keywords: k,
  body: body,
  open: (_) {},
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Favorites.instance.reset();
  });

  test('başlık eşleşmesi metin eşleşmesinden önce gelir', () {
    final all = [
      item('a', 'Subaraknoid kanama', body: 'nimodipin 60 mg'),
      item('b', 'Nimodipin'),
      item('c', 'Kalsiyum kanal blokörü', k: ['Nimotop']),
    ];
    expect(searchItems(all, 'nimo').map((i) => i.id), ['b', 'c', 'a']);
    expect(searchItems(all, 'NİMODİPİN').first.id, 'b');
    expect(searchItems(all, ''), isEmpty);
    expect(searchItems(all, 'xyz'), isEmpty);
  });

  test('Türkçe karakterden bağımsız', () {
    final all = [item('a', 'Bası yarası evreleri')];
    expect(searchItems(all, 'basi yarasi'), hasLength(1));
  });

  test('favoriler kaydedilir ve sıra korunur', () async {
    await Favorites.instance.toggle('x');
    await Favorites.instance.toggle('y');
    await Favorites.instance.toggle('x');
    await Favorites.instance.toggle('z');
    expect(Favorites.instance.ids, ['y', 'z']);
    Favorites.instance.reset();
    await Favorites.instance.load();
    expect(Favorites.instance.ids, ['y', 'z']);
    final all = [item('z', 'Z'), item('y', 'Y')];
    expect(favoriteItems(all, ['y', 'gone', 'z']).map((i) => i.id), ['y', 'z']);
  });

  test('dizin bütün bölümleri ve protokolleri içerir', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await UnitProtocolStore().save([
      UnitProtocol(
        id: '1',
        title: 'Nimodipin: eczanemizin talimatı',
        kind: ProtocolKind.drugPrep,
        body: '',
        updatedAt: DateTime(2026),
      ),
    ]);
    final all = await buildSearchIndex();
    final ids = all.map((i) => i.id).toSet();
    expect(ids, contains('assets/content/ilac/nimodipin.md'));
    expect(ids, contains('assets/content/hastalik/epilepsi-status.md'));
    expect(ids, contains('assets/content/resusitasyon/kardiyak-arrest.md'));
    expect(ids, contains('tool:cpr'));
    expect(ids, contains('protocol:1'));
    expect(ids.length, all.length, reason: 'kimlikler benzersiz olmalı');
    final nimo = searchItems(all, 'nimodipin').map((i) => i.title).toList();
    expect(nimo.first, 'Nimodipin');
    expect(nimo, contains('Nimodipin: eczanemizin talimatı'));
    expect(nimo, contains('Nimodipin (IV) infüzyonu'));
    expect(searchItems(all, 'VF').first.section, 'EKG ritmi');
  });

  testWidgets('arama sonucundan sayfa açılır ve favorilere eklenir', (
    tester,
  ) async {
    phone(tester);
    var opened = '';
    final index = Future.value([
      SearchItem(
        id: 'p1',
        title: 'Nimodipin',
        section: 'İlaç',
        icon: Icons.medication,
        open: (_) => opened = 'p1',
      ),
      item('p2', 'Noradrenalin'),
    ]);
    await tester.pumpWidget(MaterialApp(home: SearchScreen(index: index)));
    await tester.pumpAndSettle();
    expect(find.text('Favorilerim'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nimo');
    await tester.pump();
    expect(find.text('1 sonuç'), findsOneWidget);
    await tester.tap(find.byTooltip('Favorilere ekle'));
    await tester.pumpAndSettle();
    expect(Favorites.instance.ids, ['p1']);
    await tester.tap(find.text('Nimodipin'));
    expect(opened, 'p1');

    await tester.tap(find.byTooltip('Temizle'));
    await tester.pumpAndSettle();
    expect(find.text('Nimodipin'), findsOneWidget); // favorilerde
    expect(tester.takeException(), isNull);
  });

  testWidgets('içerik sayfasında yıldız', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: ContentScreen(
          asset: 'assets/content/hemsirelik/sbar-ornekleri.md',
          title: 'SBAR',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Favorilere ekle'));
    await tester.pumpAndSettle();
    expect(Favorites.instance.ids, [
      'assets/content/hemsirelik/sbar-ornekleri.md',
    ]);
    expect(find.byTooltip('Favorilerden çıkar'), findsOneWidget);
  });
}
