import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/followup/follow_up.dart';
import 'package:norocep/features/followup/follow_up_notifier.dart';
import 'package:norocep/features/followup/follow_up_screen.dart';
import 'package:norocep/features/followup/follow_up_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotifier implements FollowUpNotifier {
  final scheduled = <int>[];
  final cancelled = <int>[];

  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<void> schedule(FollowUp f) async => scheduled.add(f.id);

  @override
  Future<void> cancel(FollowUp f) async => cancelled.add(f.id);
}

void main() {
  final start = DateTime(2026, 1, 1, 10);
  FollowUp make() => FollowUp(
    id: 1,
    label: 'Yatak 3',
    kind: FollowUpKind.thrombolysis,
    start: start,
  );
  DateTime at(int minutes) => start.add(Duration(minutes: minutes));

  test('takvim: 8 × 15 dk, 12 × 30 dk, 16 × 60 dk = 36 kontrol, 24 saat', () {
    expect(followUpOffsets.length, 36);
    expect(followUpOffsets.first, const Duration(minutes: 15));
    expect(followUpOffsets[7], const Duration(hours: 2));
    expect(followUpOffsets[8], const Duration(hours: 2, minutes: 30));
    expect(followUpOffsets[19], const Duration(hours: 8));
    expect(followUpOffsets[20], const Duration(hours: 9));
    expect(followUpOffsets.last, const Duration(hours: 24));
    expect(phaseOf(0).interval, const Duration(minutes: 15));
    expect(phaseOf(8).interval, const Duration(minutes: 30));
    expect(phaseOf(35).interval, const Duration(hours: 1));
  });

  test('durumlar: yaklaşan, şimdi, gecikti, yapıldı', () {
    final f = make();
    expect(f.statusOf(0, at(5)), CheckStatus.upcoming);
    expect(f.statusOf(0, at(11)), CheckStatus.due); // 5 dk önceden
    expect(f.statusOf(0, at(20)), CheckStatus.due);
    expect(f.statusOf(0, at(21)), CheckStatus.overdue);
    f.markIndexDone(0, at(21));
    expect(f.statusOf(0, at(30)), CheckStatus.done);
  });

  test('kontrol yapıldı: şu anki kontrolü işaretler, kaçırılanı doldurmaz', () {
    final f = make();
    expect(f.markDone(at(5)), isNull); // henüz zamanı yok
    expect(f.markDone(at(16)), 0);
    expect(f.markDone(at(17)), isNull); // aynı kontrol tekrar işaretlenmez
    // 30. dakika kaçırıldı, 45. dakikada basıldı.
    expect(f.markDone(at(46)), 2);
    expect(f.done[1], isNull);
    expect(f.statusOf(1, at(46)), CheckStatus.overdue);
    expect(f.overdueCount(at(46)), 1);
    // Geç kalınsa da şu anki kontrol işaretlenir (60. dk, 69. dk'da).
    expect(f.markDone(at(69)), 3);
    expect(f.completedCount, 3);
  });

  test('geri alma ve tamamlanma', () {
    final f = make();
    f.markDone(at(15));
    f.undo(0);
    expect(f.completedCount, 0);
    expect(f.isFinished(at(60)), isFalse);
    expect(f.isFinished(at(24 * 60 + 10)), isTrue);
  });

  test('JSON gidiş-dönüş', () {
    final f = make()..markDone(at(15));
    final g = FollowUp.fromJson(f.toJson());
    expect(g.label, 'Yatak 3');
    expect(g.kind, FollowUpKind.thrombolysis);
    expect(g.start, start);
    expect(g.done[0], at(15));
    expect(g.done.skip(1).every((d) => d == null), isTrue);
  });

  test('kayıt ve kimlik', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FollowUpStore();
    expect(await store.load(), isEmpty);
    await store.save([make()]);
    final loaded = await store.load();
    expect(loaded.single.label, 'Yatak 3');
    expect(FollowUpStore.nextId(loaded), 2);
    expect(notificationId(make(), 5), 105);
  });

  testWidgets('yeni izlem oluşturulur, kontrol işaretlenir, izlem bitirilir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    var now = DateTime(2026, 1, 1, 10);
    final notifier = FakeNotifier();
    await tester.pumpWidget(
      MaterialApp(
        home: FollowUpListScreen(
          store: FollowUpStore(),
          notifier: notifier,
          clock: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Aktif izlem yok'), findsOneWidget);

    await tester.tap(find.text('Yeni izlem'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Yatak 3');
    await tester.tap(find.text('İzlemi başlat'));
    await tester.pumpAndSettle();
    expect(find.text('Yatak 3'), findsOneWidget);
    expect(find.textContaining('Sonraki kontrol: 10:15'), findsOneWidget);
    expect(notifier.scheduled, [1]);

    now = DateTime(2026, 1, 1, 10, 16);
    await tester.pump(const Duration(seconds: 16));
    expect(find.textContaining('KONTROL ZAMANI'), findsOneWidget);

    await tester.tap(find.text('Yatak 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kontrol yapıldı'));
    await tester.pump();
    expect(find.text('1. kontrol kaydedildi (10:16)'), findsOneWidget);
    expect(find.text('Yapıldı 10:16'), findsOneWidget);

    await tester.tap(find.byTooltip('İzlemi bitir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bitir'));
    await tester.pumpAndSettle();
    expect(notifier.cancelled, [1]);
    expect(find.textContaining('Aktif izlem yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Açık zamanlayıcılar test bitmeden kapansın.
    await tester.pumpWidget(const SizedBox());
  });
}
