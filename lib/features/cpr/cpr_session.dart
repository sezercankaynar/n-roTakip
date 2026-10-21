/// CPR zamanlayıcısının mantığı. Arayüzden bağımsızdır ve test edilebilir.
///
/// Süreler duvar saatinden (clock) hesaplanır; böylece uygulama arka plana
/// geçse veya ekran donsa bile sayaçlar doğru kalır.
library;

enum CprEventType {
  start,
  rhythmCheck,
  adrenaline,
  shock,
  amiodarone,
  airway,
  rosc,
  end,
}

enum Rhythm {
  shockable('Şoklanabilir (VF / nabızsız VT)'),
  nonShockable('Şoklanamaz (asistoli / NEA)'),
  pulse('Nabız var (ROSC)');

  const Rhythm(this.label);

  final String label;
}

/// Adrenalin zamanlaması (AHA/ERC: 3–5 dakikada bir).
enum AdrenalineStatus {
  /// Henüz verilmedi.
  notGiven,

  /// Son dozdan bu yana 3 dakikadan az geçti.
  waiting,

  /// 3–5 dakika aralığında: doz verilebilir.
  window,

  /// 5 dakika geçti: doz gecikiyor.
  overdue,
}

enum CprAlert {
  /// 2 dakikalık döngü doldu: ritim ve nabız kontrolü.
  rhythmCheckDue,

  /// Son adrenalinden bu yana 3 dakika geçti.
  adrenalineWindowOpen,

  /// Son adrenalinden bu yana 5 dakika geçti.
  adrenalineOverdue,
}

class CprEvent {
  const CprEvent(this.type, this.time, this.elapsed, this.label);

  final CprEventType type;
  final DateTime time;
  final Duration elapsed;
  final String label;
}

class CprSession {
  CprSession({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const cycleLength = Duration(minutes: 2);
  static const adrenalineMinInterval = Duration(minutes: 3);
  static const adrenalineMaxInterval = Duration(minutes: 5);

  final DateTime Function() _clock;
  final List<CprEvent> events = [];

  DateTime? _startedAt;
  DateTime? _endedAt;
  DateTime? _cycleStart;
  DateTime? _lastAdrenaline;
  int _cycleNumber = 0;

  // pollAlerts() içinde aynı uyarının tekrar verilmemesi için.
  int _alertedCycle = 0;
  DateTime? _windowAlertedFor;
  DateTime? _overdueAlertedFor;

  bool get hasStarted => _startedAt != null;
  bool get isRunning => _startedAt != null && _endedAt == null;
  bool get hasEnded => _endedAt != null;
  DateTime? get startedAt => _startedAt;

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    return (_endedAt ?? _clock()).difference(_startedAt!);
  }

  /// Şu anki döngünün sırası (1'den başlar).
  int get cycleNumber => _cycleNumber;

  Duration get cycleElapsed {
    if (_cycleStart == null) return Duration.zero;
    return (_endedAt ?? _clock()).difference(_cycleStart!);
  }

  /// Döngü sonuna kalan süre; süre dolduysa negatif olur.
  Duration get cycleRemaining => cycleLength - cycleElapsed;

  bool get rhythmCheckDue => isRunning && cycleElapsed >= cycleLength;

  int get adrenalineCount => _count(CprEventType.adrenaline);
  int get shockCount => _count(CprEventType.shock);
  int get amiodaroneCount => _count(CprEventType.amiodarone);

  Duration? get sinceAdrenaline {
    if (_lastAdrenaline == null) return null;
    return (_endedAt ?? _clock()).difference(_lastAdrenaline!);
  }

  AdrenalineStatus get adrenalineStatus {
    final since = sinceAdrenaline;
    if (since == null) return AdrenalineStatus.notGiven;
    if (since < adrenalineMinInterval) return AdrenalineStatus.waiting;
    if (since < adrenalineMaxInterval) return AdrenalineStatus.window;
    return AdrenalineStatus.overdue;
  }

  void start() {
    if (hasStarted) return;
    final now = _clock();
    _startedAt = now;
    _cycleStart = now;
    _cycleNumber = 1;
    _log(CprEventType.start, 'CPR başladı');
  }

  /// Ritim/nabız kontrolü yapıldı; yeni 2 dakikalık döngü başlar.
  void recordRhythmCheck(Rhythm rhythm) {
    if (!isRunning) return;
    _log(CprEventType.rhythmCheck, 'Ritim kontrolü: ${rhythm.label}');
    if (rhythm == Rhythm.pulse) {
      recordRosc();
      return;
    }
    _cycleStart = _clock();
    _cycleNumber++;
  }

  void recordAdrenaline() {
    if (!isRunning) return;
    _lastAdrenaline = _clock();
    _log(
      CprEventType.adrenaline,
      'Adrenalin 1 mg (${adrenalineCount + 1}. doz)',
    );
  }

  void recordShock() {
    if (!isRunning) return;
    _log(CprEventType.shock, 'Şok (${shockCount + 1}. şok)');
  }

  void recordAmiodarone() {
    if (!isRunning) return;
    final label = switch (amiodaroneCount) {
      0 => 'Amiodaron 300 mg (1. doz)',
      1 => 'Amiodaron 150 mg (2. doz)',
      _ => 'Amiodaron (${amiodaroneCount + 1}. doz)',
    };
    _log(CprEventType.amiodarone, label);
  }

  void recordAirway() {
    if (!isRunning) return;
    _log(CprEventType.airway, 'İleri havayolu / entübasyon');
  }

  void recordRosc() {
    if (!isRunning) return;
    _log(CprEventType.rosc, 'ROSC (spontan dolaşımın geri dönüşü)');
    _endedAt = _clock();
  }

  void end() {
    if (!isRunning) return;
    _log(CprEventType.end, 'CPR sonlandırıldı');
    _endedAt = _clock();
  }

  /// Son çağrıdan bu yana yeni oluşan uyarıları döndürür (her uyarı bir kez).
  List<CprAlert> pollAlerts() {
    if (!isRunning) return const [];
    final alerts = <CprAlert>[];
    if (rhythmCheckDue && _alertedCycle != _cycleNumber) {
      _alertedCycle = _cycleNumber;
      alerts.add(CprAlert.rhythmCheckDue);
    }
    final last = _lastAdrenaline;
    if (last != null) {
      final status = adrenalineStatus;
      if (status == AdrenalineStatus.overdue && _overdueAlertedFor != last) {
        _overdueAlertedFor = last;
        _windowAlertedFor = last;
        alerts.add(CprAlert.adrenalineOverdue);
      } else if (status == AdrenalineStatus.window &&
          _windowAlertedFor != last) {
        _windowAlertedFor = last;
        alerts.add(CprAlert.adrenalineWindowOpen);
      }
    }
    return alerts;
  }

  /// Hasta dosyasına aktarılabilecek düz metin özet (kişisel veri içermez).
  String summaryText() {
    final b = StringBuffer('CPR ÖZETİ\n');
    if (_startedAt != null) {
      b.writeln('Başlangıç: ${formatClock(_startedAt!)}');
      b.writeln('Toplam süre: ${formatDuration(elapsed)}');
    }
    b.writeln(
      'Adrenalin: $adrenalineCount doz · Şok: $shockCount · '
      'Amiodaron: $amiodaroneCount doz',
    );
    b.writeln();
    for (final e in events) {
      b.writeln(
        '${formatClock(e.time)}  (+${formatDuration(e.elapsed)})  '
        '${e.label}',
      );
    }
    return b.toString();
  }

  int _count(CprEventType type) => events.where((e) => e.type == type).length;

  void _log(CprEventType type, String label) {
    final now = _clock();
    events.add(CprEvent(type, now, now.difference(_startedAt!), label));
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 75 saniye → "01:15"; 1 saat üzeri → "1:02:03". Negatif süreler "-" ile.
String formatDuration(Duration d) {
  final sign = d.isNegative ? '-' : '';
  final s = d.abs().inSeconds;
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  return h > 0
      ? '$sign$h:${_two(m)}:${_two(sec)}'
      : '$sign${_two(m)}:${_two(sec)}';
}

String formatClock(DateTime t) =>
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';
