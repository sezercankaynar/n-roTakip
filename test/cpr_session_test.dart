import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/cpr/cpr_session.dart';

void main() {
  late DateTime now;
  late CprSession s;

  void at(int minutes, [int seconds = 0]) => now = DateTime(
    2026,
    1,
    1,
    10,
  ).add(Duration(minutes: minutes, seconds: seconds));

  setUp(() {
    at(0);
    s = CprSession(clock: () => now);
    s.start();
  });

  List<String> labels() => s.timeline.map((e) => e.label).toList();
  List<String> times() =>
      s.timeline.map((e) => formatDuration(e.elapsed)).toList();

  test('nabız kontrolü 2 dakikada, adrenalin 3 dakikada uyarır', () {
    at(1, 59);
    expect(s.pollAlerts(), isEmpty);
    at(2);
    expect(s.pollAlerts(), [CprAlert.pulseCheckDue]);
    expect(s.pollAlerts(), isEmpty);
    at(3);
    expect(s.pollAlerts(), [CprAlert.adrenalineDue]);
    at(6);
    expect(s.pollAlerts(), [CprAlert.pulseCheckDue, CprAlert.adrenalineDue]);
  });

  test('geç basılan nabız kontrolü planlanan tam zamana yazılır', () {
    at(2, 7);
    expect(s.dueSlot(ScheduledTask.pulseCheck), 1);
    s.recordPulseCheck();
    expect(s.dueSlot(ScheduledTask.pulseCheck), isNull);
    final e = s.timeline.last;
    expect(e.label, 'Nabız kontrolü');
    expect(e.elapsed, const Duration(minutes: 2));
    expect(e.time, DateTime(2026, 1, 1, 10, 2));
  });

  test('erken basılan adrenalin planlanan tam zamana yazılır', () {
    at(2, 40);
    s.recordAdrenaline();
    expect(s.timeline.last.elapsed, const Duration(minutes: 3));
    expect(s.timeline.last.label, 'Adrenalin 1 mg (1. doz)');
    at(3, 10);
    expect(s.dueSlot(ScheduledTask.adrenaline), isNull);
  });

  test('tolerans dışındaki basış gerçek zamanıyla "ek" olarak kaydedilir', () {
    at(1);
    s.recordAdrenaline();
    expect(s.timeline.last.label, 'Adrenalin 1 mg (1. doz) (ek)');
    expect(s.timeline.last.elapsed, const Duration(minutes: 1));
    // 3. dakikadaki planlı doz hâlâ beklemede.
    at(3, 5);
    expect(s.dueSlot(ScheduledTask.adrenaline), 1);
    s.recordAdrenaline();
    expect(s.timeline.last.label, 'Adrenalin 1 mg (2. doz)');
    expect(s.timeline.last.elapsed, const Duration(minutes: 3));
  });

  test('aynı planlı zamana ikinci basış ek kayıt olur', () {
    at(2, 5);
    s.recordPulseCheck();
    at(2, 20);
    s.recordPulseCheck();
    expect(times().sublist(1), ['02:00', '02:20']);
    expect(labels().last, 'Nabız kontrolü (ek)');
  });

  test('basılmayan planlı işlem süresi dolunca "onaylanmadı" görünür', () {
    at(2, 59);
    expect(labels().any((l) => l.contains('onaylanmadı')), isFalse);
    at(3, 1);
    // 2:00 nabız kontrolü 60 sn tolerans geçti; 3:00 adrenalin henüz değil.
    final missed = s.timeline.where((e) => !e.confirmed).toList();
    expect(missed.map((e) => e.label), ['Nabız kontrolü zamanı (onaylanmadı)']);
    expect(missed.single.elapsed, const Duration(minutes: 2));
  });

  test('ritim sonradan eklenir; nabız varsa ROSC ile biter', () {
    at(2, 3);
    s.recordPulseCheck();
    s.setLastPulseRhythm(Rhythm.shockable);
    expect(labels().last, 'Nabız kontrolü: ${Rhythm.shockable.label}');
    at(4, 2);
    s.recordPulseCheck();
    s.setLastPulseRhythm(Rhythm.pulse);
    expect(s.hasEnded, isTrue);
    expect(labels().last, 'ROSC (spontan dolaşımın geri dönüşü)');
    expect(s.elapsed, const Duration(minutes: 4, seconds: 2));
  });

  test('atropin ve amiodaron dozları gerçek zamanla kaydedilir', () {
    at(1, 15);
    s.recordAtropine();
    s.recordAmiodarone();
    s.recordAmiodarone();
    expect(
      labels(),
      containsAll([
        'Atropin (1. doz)',
        'Amiodaron 300 mg (1. doz)',
        'Amiodaron 150 mg (2. doz)',
      ]),
    );
    expect(s.atropineCount, 1);
    expect(s.timeline.last.elapsed, const Duration(minutes: 1, seconds: 15));
  });

  test('bitişten sonra kayıt alınmaz ve özet tamdır', () {
    at(2, 2);
    s.recordPulseCheck();
    at(3, 1);
    s.recordAdrenaline();
    at(5);
    s.end();
    at(9);
    expect(s.elapsed, const Duration(minutes: 5));
    expect(s.pollAlerts(), isEmpty);
    s.recordShock();
    expect(s.shockCount, 0);
    // 4:00 nabız kontrolü onaylanmadı; bitişten sonraki zamanlar listelenmez.
    expect(times(), ['00:00', '02:00', '03:00', '04:00', '05:00']);
    final text = s.summaryText();
    expect(text, contains('Toplam süre: 05:00'));
    expect(text, contains('10:04:00  (+04:00)  Nabız kontrolü zamanı'));
  });

  test('süre biçimlendirme', () {
    expect(formatDuration(const Duration(seconds: 75)), '01:15');
    expect(formatDuration(const Duration(hours: 1, seconds: 3)), '1:00:03');
    expect(formatDuration(const Duration(seconds: -5)), '-00:05');
  });
}
