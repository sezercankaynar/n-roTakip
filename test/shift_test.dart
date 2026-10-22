import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/shift/shift.dart';
import 'package:norocep/features/shift/shift_notifier.dart';
import 'package:norocep/features/shift/shift_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeShiftNotifier implements ShiftNotifier {
  final scheduled = <int, ShiftTask>{};

  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> schedule(ShiftTask t) async {
    if (t.isDone) {
      scheduled.remove(t.id);
    } else {
      scheduled[t.id] = t;
    }
  }

  @override
  Future<void> cancel(ShiftTask t) async => scheduled.remove(t.id);
}

void phone(WidgetTester t, {double height = 2600}) {
  t.view.physicalSize = Size(720, height);
  t.view.devicePixelRatio = 2.0;
  addTearDown(t.view.reset);
}

final day = DateTime(2026, 10, 22);
DateTime at(int h, [int m = 0]) => day.add(Duration(hours: h, minutes: m));

void main() {
  group('vardiya saatleri', () {
    test('gündüz vardiyası bugün başlar', () {
      expect(const ShiftPreset(8, 8).startFor(at(9)), at(8));
      expect(const ShiftPreset(8, 8).startFor(at(6)), at(8));
    });
    test('gece vardiyası gece yarısından sonra dünden başlar', () {
      expect(const ShiftPreset(20, 12).startFor(at(3)), at(-4));
      expect(const ShiftPreset(20, 12).startFor(at(21)), at(20));
    });
    test('etiketler', () {
      expect(shiftPresets.map((p) => p.label), [
        '08:00–16:00',
        '08:00–20:00',
        '20:00–08:00',
        '16:00–08:00',
        '08:00–08:00',
      ]);
    });
  });

  test('tekrar vardiya sonuna kadar', () {
    final t = repeatTimes(at(10), 4, at(20));
    expect(t, [at(10), at(14), at(18)]);
    expect(repeatTimes(at(10), 0, at(20)), [at(10)]);
  });

  test('gecikmiş, sıradaki, yapıldı ayrımı', () {
    final s = Shift(
      start: at(8),
      end: at(16),
      tasks: [
        ShiftTask(id: 1, title: 'A', at: at(9)),
        ShiftTask(id: 2, title: 'B', at: at(11)),
        ShiftTask(id: 3, title: 'C', at: at(9, 30), doneAt: at(9, 31)),
      ],
    );
    expect(s.overdue(at(10)).map((t) => t.title), ['A']);
    expect(s.upcoming(at(10)).map((t) => t.title), ['B']);
    expect(s.done.map((t) => t.title), ['C']);
    expect(s.nextId, 4);
  });

  test('devir özeti yatağa göre ve yapılmayanları gösterir', () {
    final s = Shift(
      start: at(8),
      end: at(16),
      tasks: [
        ShiftTask(id: 1, title: 'Nimodipin', at: at(12), bed: '12'),
        ShiftTask(
          id: 2,
          title: 'Kan şekeri',
          at: at(9),
          bed: '12',
          doneAt: at(9, 5),
        ),
        ShiftTask(id: 3, title: 'Eczane', at: at(10), important: true),
      ],
    );
    final text = handoverText(s);
    expect(text, contains('Yatak 12'));
    expect(text, contains('✓ 09:00 Kan şekeri (yapıldı 09:05)'));
    expect(text, contains('✗ 12:00 Nimodipin (YAPILMADI)'));
    expect(text, contains('Genel'));
    expect(text, contains('⚠'));
  });

  test('kayıt ve yükleme', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ShiftStore();
    final s = Shift(
      start: at(8),
      end: at(16),
      tasks: [
        ShiftTask(
          id: 1,
          title: 'Nimodipin',
          at: at(12),
          bed: '5',
          kind: TaskKind.drug,
          important: true,
          note: 'ışıktan koru',
          seriesId: 1,
        ),
      ],
    );
    await store.save(s);
    final back = (await store.load())!;
    final t = back.tasks.single;
    expect(back.end, at(16));
    expect(
      [t.title, t.bed, t.kind, t.important, t.note, t.seriesId],
      ['Nimodipin', '5', TaskKind.drug, true, 'ışıktan koru', 1],
    );
    await store.save(null);
    expect(await store.load(), isNull);
  });

  test('bildirim numaraları izlemlerle çakışmaz', () {
    final t = ShiftTask(id: 3, title: 'x', at: at(9));
    expect(shiftNotificationId(t), 1000006);
    expect(shiftNotificationId(t, early: true), 1000007);
  });

  testWidgets('vardiya başlatılır, tekrarlı iş eklenir, işaretlenir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    phone(tester, height: 4000);
    final notifier = FakeShiftNotifier();
    await tester.pumpWidget(
      MaterialApp(
        home: ShiftScreen(notifier: notifier, clock: () => at(9, 10)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vardiyanı başlat'), findsOneWidget);
    await tester.tap(find.text('08:00–16:00 vardiyasını başlat'));
    await tester.pumpAndSettle();
    expect(find.text('Vardiyam 08:00–16:00'), findsOneWidget);

    await tester.tap(find.text('İş ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nimodipin'));
    await tester.pump();
    expect(find.text('4 saatte bir'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Yatak / oda'), '12');
    await tester.tap(find.text('Önemli'));
    await tester.pump();
    // İlk saat 09:30; 4 saatte bir → 09:30, 13:30.
    expect(find.textContaining('2 hatırlatma'), findsOneWidget);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('09:30'), findsOneWidget);
    expect(find.text('13:30'), findsOneWidget);
    expect(notifier.scheduled, hasLength(2));
    expect(notifier.scheduled.values.every((t) => t.important), isTrue);
    expect(find.textContaining('Sıradaki: 09:30 · Yatak 12'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1 / 2 iş yapıldı'), findsOneWidget);
    expect(notifier.scheduled, hasLength(1));
    final saved = (await ShiftStore().load())!;
    expect(saved.done.single.doneAt, at(9, 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('geciken iş ayrı görünür; yatağa göre gruplanır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ShiftStore().save(
      Shift(
        start: at(8),
        end: at(16),
        tasks: [
          ShiftTask(id: 1, title: 'Kan alımı', at: at(9), bed: '3'),
          ShiftTask(id: 2, title: 'Pozisyon', at: at(11), bed: '12'),
          ShiftTask(id: 3, title: 'Eczane', at: at(12)),
        ],
      ),
    );
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ShiftScreen(notifier: FakeShiftNotifier(), clock: () => at(10)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zamanı geçti (1)'), findsOneWidget);
    expect(find.text('Sıradaki işler (2)'), findsOneWidget);

    await tester.tap(find.text('Yatağa göre'));
    await tester.pumpAndSettle();
    expect(find.text('Yatak 3'), findsOneWidget);
    expect(find.text('Yatak 12'), findsOneWidget);
    expect(find.text('Genel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vardiya bitirilince liste ve bildirimler silinir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final notifier = FakeShiftNotifier();
    final task = ShiftTask(id: 1, title: 'Nimodipin', at: at(12));
    notifier.scheduled[1] = task;
    await ShiftStore().save(Shift(start: at(8), end: at(16), tasks: [task]));
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ShiftScreen(notifier: notifier, clock: () => at(15)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Vardiyayı bitir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 iş yapılmadı'), findsOneWidget);
    expect(find.textContaining('YAPILMADI'), findsOneWidget);
    await tester.tap(find.text('Bitir ve sil'));
    await tester.pumpAndSettle();
    expect(find.text('Vardiyanı başlat'), findsOneWidget);
    expect(notifier.scheduled, isEmpty);
    expect(await ShiftStore().load(), isNull);
  });

  testWidgets('eski vardiya kendiliğinden silinir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ShiftStore().save(
      Shift(
        start: at(8),
        end: at(16),
        tasks: [ShiftTask(id: 1, title: 'x', at: at(9))],
      ),
    );
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ShiftScreen(
          notifier: FakeShiftNotifier(),
          clock: () => at(16 + 13),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vardiyanı başlat'), findsOneWidget);
    expect(await ShiftStore().load(), isNull);
  });

  test('sonraki zaman dilimi', () {
    expect(nextSlot(at(9, 10)), at(9, 30));
    expect(nextSlot(at(9, 40)), at(10));
  });
}
