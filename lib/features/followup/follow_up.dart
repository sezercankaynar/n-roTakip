/// Trombolitik ve trombektomi sonrası 24 saatlik izlem takvimi.
///
/// Kılavuz önerisi: ilk 2 saat 15 dakikada bir (8 kontrol), sonraki 6 saat
/// 30 dakikada bir (12 kontrol), 24. saate kadar saatte bir (16 kontrol).
/// Hasta adı tutulmaz; yalnızca "Yatak 3" gibi bir etiket kullanılır.
library;

enum FollowUpKind {
  thrombolysis('Trombolitik'),
  thrombectomy('Trombektomi'),
  both('Trombolitik + trombektomi');

  const FollowUpKind(this.label);

  final String label;
}

class FollowUpPhase {
  const FollowUpPhase(this.label, this.interval, this.count);

  final String label;
  final Duration interval;
  final int count;
}

const followUpPhases = [
  FollowUpPhase('0–2. saat · 15 dakikada bir', Duration(minutes: 15), 8),
  FollowUpPhase('2–8. saat · 30 dakikada bir', Duration(minutes: 30), 12),
  FollowUpPhase('8–24. saat · saatte bir', Duration(hours: 1), 16),
];

/// Başlangıçtan itibaren her kontrolün zamanı (36 kontrol, son kontrol
/// 24. saatte).
final List<Duration> followUpOffsets = () {
  final out = <Duration>[];
  var t = Duration.zero;
  for (final p in followUpPhases) {
    for (var i = 0; i < p.count; i++) {
      t += p.interval;
      out.add(t);
    }
  }
  return List<Duration>.unmodifiable(out);
}();

/// [index]. kontrolün ait olduğu dönem.
FollowUpPhase phaseOf(int index) {
  var i = index;
  for (final p in followUpPhases) {
    if (i < p.count) return p;
    i -= p.count;
  }
  return followUpPhases.last;
}

enum CheckStatus { done, due, overdue, upcoming }

class FollowUp {
  FollowUp({
    required this.id,
    required this.label,
    required this.kind,
    required this.start,
    List<DateTime?>? done,
  }) : done = done ?? List<DateTime?>.filled(followUpOffsets.length, null);

  /// Bir kontrol zamanından bu kadar sonra yapılmadıysa "gecikti" sayılır.
  static const graceLate = Duration(minutes: 5);

  /// Zamanından en fazla bu kadar önce yapılan kontrol o kontrole sayılır.
  static const graceEarly = Duration(minutes: 5);

  final int id;
  final String label;
  final FollowUpKind kind;
  final DateTime start;

  /// Her kontrolün yapıldığı an (`null`: yapılmadı).
  final List<DateTime?> done;

  int get total => followUpOffsets.length;
  DateTime timeOf(int i) => start.add(followUpOffsets[i]);
  DateTime get end => timeOf(total - 1);
  int get completedCount => done.where((d) => d != null).length;

  CheckStatus statusOf(int i, DateTime now) {
    if (done[i] != null) return CheckStatus.done;
    final t = timeOf(i);
    if (now.isBefore(t.subtract(graceEarly))) return CheckStatus.upcoming;
    if (now.isAfter(t.add(graceLate))) return CheckStatus.overdue;
    return CheckStatus.due;
  }

  int overdueCount(DateTime now) => [
    for (var i = 0; i < total; i++)
      if (statusOf(i, now) == CheckStatus.overdue) i,
  ].length;

  /// Yapılmamış ilk kontrol (yoksa `null`: izlem tamamlandı).
  int? nextPending() {
    final i = done.indexWhere((d) => d == null);
    return i < 0 ? null : i;
  }

  bool isFinished(DateTime now) =>
      nextPending() == null || now.isAfter(end.add(graceLate));

  /// Şu anki kontrol: zamanı gelmiş (veya 5 dakika içinde gelecek) en son
  /// kontrol. Henüz hiçbir kontrolün zamanı gelmediyse `null`.
  int? currentIndex(DateTime now) {
    for (var i = total - 1; i >= 0; i--) {
      if (!now.isBefore(timeOf(i).subtract(graceEarly))) return i;
    }
    return null;
  }

  /// "Kontrol yapıldı": şu anki kontrolü işaretler (geç kalınmış olsa bile).
  /// Daha önce kaçırılmış kontroller kendiliğinden doldurulmaz, "gecikti"
  /// olarak kalır; böylece kayıt gerçeği yansıtır. İşaretlenen kontrolün
  /// sırasını, şu anki kontrol zaten yapıldıysa veya henüz zamanı
  /// gelmediyse `null` döndürür.
  int? markDone(DateTime now) {
    final i = currentIndex(now);
    if (i == null || done[i] != null) return null;
    done[i] = now;
    return i;
  }

  /// Belirli bir kontrolü (örneğin geç yapılmış olanı) işaretler.
  void markIndexDone(int i, DateTime now) => done[i] = now;

  /// Yanlışlıkla işaretlenen kontrolü geri alır.
  void undo(int i) => done[i] = null;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'kind': kind.name,
    'start': start.toIso8601String(),
    'done': [for (final d in done) d?.toIso8601String()],
  };

  factory FollowUp.fromJson(Map<String, Object?> j) {
    final rawDone = (j['done'] as List?) ?? const [];
    return FollowUp(
      id: j['id']! as int,
      label: j['label']! as String,
      kind: FollowUpKind.values.byName(j['kind']! as String),
      start: DateTime.parse(j['start']! as String),
      done: [
        for (var i = 0; i < followUpOffsets.length; i++)
          i < rawDone.length && rawDone[i] != null
              ? DateTime.parse(rawDone[i] as String)
              : null,
      ],
    );
  }
}
