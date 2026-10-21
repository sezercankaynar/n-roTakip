/// CPR zamanlayıcısının mantığı. Arayüzden bağımsızdır ve test edilebilir.
///
/// Nabız kontrolü ve adrenalin sabit bir takvime göre planlanır
/// (2. 4. 6. dakika... ve 3. 6. 9. dakika...). Kullanıcı işlemi yaptığında
/// butona basar; basış planlanan zamana yakınsa kayda saniyeler kaymadan
/// planlanan tam zaman yazılır. Basılmayan planlı işlemler kayıtta
/// "onaylanmadı" olarak görünür; böylece yapılmamış bir işlem yapılmış gibi
/// kaydedilmez.
///
/// Süreler duvar saatinden (clock) hesaplanır; böylece uygulama arka plana
/// geçse veya ekran donsa bile sayaçlar doğru kalır.
library;

enum CprEventType {
  start,
  pulseCheck,
  adrenaline,
  shock,
  amiodarone,
  atropine,
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

/// Takvime bağlı işlemler.
enum ScheduledTask {
  pulseCheck(Duration(minutes: 2), 'Nabız kontrolü'),
  adrenaline(Duration(minutes: 3), 'Adrenalin 1 mg');

  const ScheduledTask(this.interval, this.label);

  final Duration interval;
  final String label;
}

enum CprAlert { pulseCheckDue, adrenalineDue }

class CprEvent {
  const CprEvent(
    this.type,
    this.time,
    this.elapsed,
    this.label, {
    this.confirmed = true,
  });

  final CprEventType type;
  final DateTime time;
  final Duration elapsed;
  final String label;

  /// `false`: planlanan zaman geçti ama kullanıcı işlemi onaylamadı.
  final bool confirmed;
}

class CprSession {
  CprSession({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Planlanan zamandan en fazla bu kadar önce basılırsa o zamana yazılır.
  static const earlyTolerance = Duration(seconds: 30);

  /// Planlanan zamandan en fazla bu kadar sonra basılırsa o zamana yazılır.
  /// Daha geç basışlar gerçek saatiyle "ek" olarak kaydedilir.
  static const lateTolerance = Duration(seconds: 60);

  final DateTime Function() _clock;
  final List<CprEvent> _events = [];

  DateTime? _startedAt;
  DateTime? _endedAt;

  // Onaylanan planlı işlemlerin sıra numaraları (1 = ilk planlı zaman).
  final _confirmed = {for (final t in ScheduledTask.values) t: <int>{}};

  // pollAlerts() içinde aynı uyarının tekrar verilmemesi için.
  final _alerted = {for (final t in ScheduledTask.values) t: 0};

  bool get hasStarted => _startedAt != null;
  bool get isRunning => _startedAt != null && _endedAt == null;
  bool get hasEnded => _endedAt != null;
  DateTime? get startedAt => _startedAt;

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    return (_endedAt ?? _clock()).difference(_startedAt!);
  }

  int get adrenalineCount => _count(CprEventType.adrenaline);
  int get pulseCheckCount => _count(CprEventType.pulseCheck);
  int get shockCount => _count(CprEventType.shock);
  int get amiodaroneCount => _count(CprEventType.amiodarone);
  int get atropineCount => _count(CprEventType.atropine);

  /// Planlı işlemin [index]. tekrarının CPR başlangıcından itibaren zamanı.
  static Duration slotTime(ScheduledTask task, int index) =>
      task.interval * index;

  /// Zamanı gelmiş, tolerans süresi dolmamış ve henüz onaylanmamış planlı
  /// işlem (yoksa `null`). Arayüzde "ŞİMDİ" uyarısı için kullanılır.
  int? dueSlot(ScheduledTask task) {
    if (!isRunning) return null;
    final e = elapsed;
    final last = e.inMilliseconds ~/ task.interval.inMilliseconds;
    if (last < 1) return null;
    final lateStart = e - lateTolerance;
    for (var k = last; k >= 1 && slotTime(task, k) >= lateStart; k--) {
      if (!_confirmed[task]!.contains(k)) return k;
    }
    return null;
  }

  /// Bir sonraki planlı zamana kalan süre.
  Duration untilNext(ScheduledTask task) {
    final e = elapsed;
    final next = e.inMilliseconds ~/ task.interval.inMilliseconds + 1;
    return slotTime(task, next) - e;
  }

  void start() {
    if (hasStarted) return;
    _startedAt = _clock();
    _log(CprEventType.start, 'CPR başladı', Duration.zero);
  }

  /// Nabız kontrolü yapıldı. Ritim isteğe bağlı olarak sonradan
  /// [setLastPulseRhythm] ile eklenir.
  void recordPulseCheck() {
    if (!isRunning) return;
    _recordScheduled(
      ScheduledTask.pulseCheck,
      CprEventType.pulseCheck,
      'Nabız kontrolü',
    );
  }

  /// Son nabız kontrolü kaydına ritmi ekler (basış anı korunur).
  /// "Nabız var" seçilirse CPR ROSC ile sona erer.
  void setLastPulseRhythm(Rhythm rhythm) {
    if (!isRunning) return;
    final i = _events.lastIndexWhere((e) => e.type == CprEventType.pulseCheck);
    if (i < 0) return;
    final old = _events[i];
    final suffix = old.label.endsWith(' (ek)') ? ' (ek)' : '';
    final base = suffix.isEmpty
        ? old.label
        : old.label.substring(0, old.label.length - suffix.length);
    _events[i] = CprEvent(
      old.type,
      old.time,
      old.elapsed,
      '$base: ${rhythm.label}$suffix',
    );
    if (rhythm == Rhythm.pulse) recordRosc();
  }

  void recordAdrenaline() {
    if (!isRunning) return;
    _recordScheduled(
      ScheduledTask.adrenaline,
      CprEventType.adrenaline,
      'Adrenalin 1 mg (${adrenalineCount + 1}. doz)',
    );
  }

  void recordShock() =>
      _logNow(CprEventType.shock, 'Şok (${shockCount + 1}. şok)');

  void recordAmiodarone() {
    final label = switch (amiodaroneCount) {
      0 => 'Amiodaron 300 mg (1. doz)',
      1 => 'Amiodaron 150 mg (2. doz)',
      _ => 'Amiodaron (${amiodaroneCount + 1}. doz)',
    };
    _logNow(CprEventType.amiodarone, label);
  }

  void recordAtropine() =>
      _logNow(CprEventType.atropine, 'Atropin (${atropineCount + 1}. doz)');

  void recordAirway() =>
      _logNow(CprEventType.airway, 'İleri havayolu / entübasyon');

  void recordRosc() {
    if (!isRunning) return;
    _logNow(CprEventType.rosc, 'ROSC (spontan dolaşımın geri dönüşü)');
    _endedAt = _clock();
  }

  void end() {
    if (!isRunning) return;
    _logNow(CprEventType.end, 'CPR sonlandırıldı');
    _endedAt = _clock();
  }

  /// Son çağrıdan bu yana zamanı gelen planlı işlemler (her biri bir kez).
  List<CprAlert> pollAlerts() {
    if (!isRunning) return const [];
    final alerts = <CprAlert>[];
    for (final task in ScheduledTask.values) {
      final reached = elapsed.inMilliseconds ~/ task.interval.inMilliseconds;
      if (reached > _alerted[task]!) {
        _alerted[task] = reached;
        alerts.add(switch (task) {
          ScheduledTask.pulseCheck => CprAlert.pulseCheckDue,
          ScheduledTask.adrenaline => CprAlert.adrenalineDue,
        });
      }
    }
    return alerts;
  }

  /// Kayıtlar ve süresi dolup onaylanmamış planlı işlemler, zamana göre sıralı.
  List<CprEvent> get timeline {
    final start = _startedAt;
    if (start == null) return const [];
    final items = [..._events];
    final e = elapsed;
    for (final task in ScheduledTask.values) {
      for (var k = 1; slotTime(task, k) <= e; k++) {
        final t = slotTime(task, k);
        final expired = hasEnded || t + lateTolerance < e;
        if (expired && !_confirmed[task]!.contains(k)) {
          items.add(
            CprEvent(
              task == ScheduledTask.pulseCheck
                  ? CprEventType.pulseCheck
                  : CprEventType.adrenaline,
              start.add(t),
              t,
              '${task.label} zamanı (onaylanmadı)',
              confirmed: false,
            ),
          );
        }
      }
    }
    items.sort((a, b) {
      final c = a.elapsed.compareTo(b.elapsed);
      // Aynı saniyede başlangıç ve bitiş kayıtları doğru sırada kalsın.
      return c != 0 ? c : a.type.index.compareTo(b.type.index);
    });
    return items;
  }

  /// Hasta dosyasına aktarılabilecek düz metin özet (kişisel veri içermez).
  String summaryText() {
    final b = StringBuffer('CPR ÖZETİ\n');
    if (_startedAt != null) {
      b.writeln('Başlangıç: ${formatClock(_startedAt!)}');
      b.writeln('Toplam süre: ${formatDuration(elapsed)}');
    }
    b.writeln(
      'Nabız kontrolü: $pulseCheckCount · Adrenalin: $adrenalineCount '
      'doz · Şok: $shockCount · Amiodaron: $amiodaroneCount doz · '
      'Atropin: $atropineCount doz',
    );
    b.writeln();
    for (final e in timeline) {
      b.writeln(
        '${formatClock(e.time)}  (+${formatDuration(e.elapsed)})  '
        '${e.label}',
      );
    }
    return b.toString();
  }

  void _recordScheduled(ScheduledTask task, CprEventType type, String label) {
    final e = elapsed;
    final slot = _matchingSlot(task, e);
    if (slot == null) {
      _log(type, '$label (ek)', e);
      return;
    }
    _confirmed[task]!.add(slot);
    _log(type, label, slotTime(task, slot));
  }

  /// [e] anındaki basışın ait olduğu planlı işlem: tolerans aralığında olan,
  /// onaylanmamış ve zamanı basışa en yakın olan.
  int? _matchingSlot(ScheduledTask task, Duration e) {
    int? best;
    Duration? bestDiff;
    final ms = task.interval.inMilliseconds;
    final from = ((e - lateTolerance).inMilliseconds / ms).ceil();
    final to = ((e + earlyTolerance).inMilliseconds / ms).floor();
    for (var k = from < 1 ? 1 : from; k <= to; k++) {
      if (_confirmed[task]!.contains(k)) continue;
      final diff = (slotTime(task, k) - e).abs();
      if (bestDiff == null || diff < bestDiff) {
        best = k;
        bestDiff = diff;
      }
    }
    return best;
  }

  int _count(CprEventType type) => _events.where((e) => e.type == type).length;

  void _logNow(CprEventType type, String label) {
    if (!isRunning) return;
    _log(type, label, elapsed);
  }

  void _log(CprEventType type, String label, Duration at) {
    _events.add(CprEvent(type, _startedAt!.add(at), at, label));
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
