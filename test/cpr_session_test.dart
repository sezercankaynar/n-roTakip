import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/cpr/cpr_session.dart';

void main() {
  late DateTime now;
  late CprSession s;

  void advance(Duration d) => now = now.add(d);

  setUp(() {
    now = DateTime(2026, 1, 1, 10);
    s = CprSession(clock: () => now);
  });

  test('2 dakikada ritim kontrolü uyarısı bir kez verilir', () {
    s.start();
    advance(const Duration(seconds: 119));
    expect(s.pollAlerts(), isEmpty);
    expect(s.rhythmCheckDue, isFalse);

    advance(const Duration(seconds: 1));
    expect(s.pollAlerts(), [CprAlert.rhythmCheckDue]);
    expect(s.pollAlerts(), isEmpty);
    expect(s.rhythmCheckDue, isTrue);
  });

  test('kontrol sonrası yeni döngü başlar', () {
    s.start();
    advance(const Duration(minutes: 2, seconds: 10));
    s.pollAlerts();
    s.recordRhythmCheck(Rhythm.shockable);
    expect(s.cycleNumber, 2);
    expect(s.cycleRemaining, CprSession.cycleLength);
    advance(const Duration(minutes: 2));
    expect(s.pollAlerts(), [CprAlert.rhythmCheckDue]);
  });

  test('adrenalin 3. dakikada hafif, 5. dakikada güçlü uyarı', () {
    s.start();
    expect(s.adrenalineStatus, AdrenalineStatus.notGiven);
    s.recordAdrenaline();
    advance(const Duration(minutes: 2, seconds: 59));
    expect(s.adrenalineStatus, AdrenalineStatus.waiting);
    expect(s.pollAlerts(), [CprAlert.rhythmCheckDue]);

    advance(const Duration(seconds: 1));
    expect(s.adrenalineStatus, AdrenalineStatus.window);
    expect(s.pollAlerts(), [CprAlert.adrenalineWindowOpen]);

    advance(const Duration(minutes: 2));
    expect(s.adrenalineStatus, AdrenalineStatus.overdue);
    expect(s.pollAlerts(), [CprAlert.adrenalineOverdue]);
    expect(s.pollAlerts(), isEmpty);
  });

  test('yeni adrenalin dozu sayacı sıfırlar', () {
    s.start();
    s.recordAdrenaline();
    advance(const Duration(minutes: 4));
    s.pollAlerts();
    s.recordAdrenaline();
    expect(s.adrenalineCount, 2);
    expect(s.adrenalineStatus, AdrenalineStatus.waiting);
    advance(const Duration(minutes: 3));
    expect(s.pollAlerts(), contains(CprAlert.adrenalineWindowOpen));
  });

  test('amiodaron dozları 300 mg sonra 150 mg', () {
    s.start();
    s.recordAmiodarone();
    s.recordAmiodarone();
    final labels = s.events.map((e) => e.label).toList();
    expect(labels, contains('Amiodaron 300 mg (1. doz)'));
    expect(labels, contains('Amiodaron 150 mg (2. doz)'));
  });

  test('ROSC sayaçları durdurur ve özet üretir', () {
    s.start();
    advance(const Duration(minutes: 1));
    s.recordShock();
    advance(const Duration(minutes: 1, seconds: 30));
    s.recordRhythmCheck(Rhythm.pulse);
    expect(s.hasEnded, isTrue);
    expect(s.elapsed, const Duration(minutes: 2, seconds: 30));
    advance(const Duration(minutes: 10));
    expect(s.elapsed, const Duration(minutes: 2, seconds: 30));
    expect(s.pollAlerts(), isEmpty);
    s.recordShock();
    expect(s.shockCount, 1);
    final text = s.summaryText();
    expect(text, contains('Toplam süre: 02:30'));
    expect(text, contains('ROSC'));
  });

  test('süre biçimlendirme', () {
    expect(formatDuration(const Duration(seconds: 75)), '01:15');
    expect(formatDuration(const Duration(hours: 1, seconds: 3)), '1:00:03');
    expect(formatDuration(const Duration(seconds: -5)), '-00:05');
  });
}
