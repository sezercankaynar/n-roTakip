import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Vardiya işinin türü.
enum TaskKind {
  drug('İlaç'),
  monitor('Takip / ölçüm'),
  lab('Tetkik / kan alma'),
  care('Bakım'),
  other('Diğer');

  const TaskKind(this.label);

  final String label;

  static TaskKind byName(String? name) => TaskKind.values.firstWhere(
    (k) => k.name == name,
    orElse: () => TaskKind.other,
  );
}

/// Vardiyadaki tek bir iş. Hasta adı değil yatak/oda numarası tutulur.
class ShiftTask {
  const ShiftTask({
    required this.id,
    required this.title,
    required this.at,
    this.bed = '',
    this.kind = TaskKind.other,
    this.important = false,
    this.note = '',
    this.doneAt,
    this.seriesId,
  });

  final int id;
  final String title;
  final DateTime at;

  /// Yatak veya oda (boşsa genel iş).
  final String bed;
  final TaskKind kind;

  /// Önemli işlere 10 dakika önce de hatırlatma yapılır.
  final bool important;
  final String note;
  final DateTime? doneAt;

  /// Tekrarlayan işlerde aynı seriyi paylaşan işlerin ortak numarası.
  final int? seriesId;

  bool get isDone => doneAt != null;

  String get bedLabel => bed.isEmpty ? 'Genel' : 'Yatak $bed';

  ShiftTask copyWith({
    String? title,
    DateTime? at,
    String? bed,
    TaskKind? kind,
    bool? important,
    String? note,
    DateTime? Function()? doneAt,
  }) => ShiftTask(
    id: id,
    title: title ?? this.title,
    at: at ?? this.at,
    bed: bed ?? this.bed,
    kind: kind ?? this.kind,
    important: important ?? this.important,
    note: note ?? this.note,
    doneAt: doneAt == null ? this.doneAt : doneAt(),
    seriesId: seriesId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'at': at.toIso8601String(),
    'bed': bed,
    'kind': kind.name,
    'imp': important,
    'note': note,
    'done': doneAt?.toIso8601String(),
    'series': seriesId,
  };

  factory ShiftTask.fromJson(Map<String, Object?> j) => ShiftTask(
    id: j['id']! as int,
    title: j['title']! as String,
    at: DateTime.parse(j['at']! as String),
    bed: (j['bed'] as String?) ?? '',
    kind: TaskKind.byName(j['kind'] as String?),
    important: (j['imp'] as bool?) ?? false,
    note: (j['note'] as String?) ?? '',
    doneAt: j['done'] == null ? null : DateTime.tryParse(j['done']! as String),
    seriesId: j['series'] as int?,
  );
}

/// Hazır vardiya saatleri.
class ShiftPreset {
  const ShiftPreset(this.startHour, this.hours);

  final int startHour;
  final int hours;

  String get label {
    String h(int x) => '${(x % 24).toString().padLeft(2, '0')}:00';
    return '${h(startHour)}–${h(startHour + hours)}';
  }

  /// [now] anını içeren vardiyanın başlangıcı; yoksa bugünkü başlangıç.
  DateTime startFor(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, startHour);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final s in [yesterday, today]) {
      if (!now.isBefore(s) && now.isBefore(s.add(Duration(hours: hours)))) {
        return s;
      }
    }
    return today;
  }
}

const shiftPresets = [
  ShiftPreset(8, 8),
  ShiftPreset(8, 12),
  ShiftPreset(20, 12),
  ShiftPreset(16, 16),
  ShiftPreset(8, 24),
];

/// Bir vardiya ve işleri.
class Shift {
  const Shift({required this.start, required this.end, this.tasks = const []});

  final DateTime start;
  final DateTime end;
  final List<ShiftTask> tasks;

  Shift withTasks(List<ShiftTask> tasks) =>
      Shift(start: start, end: end, tasks: tasks);

  int get nextId => tasks.fold(0, (m, t) => t.id > m ? t.id : m) + 1;

  List<ShiftTask> get sorted =>
      [...tasks]..sort((a, b) => a.at.compareTo(b.at));

  List<ShiftTask> overdue(DateTime now) => [
    for (final t in sorted)
      if (!t.isDone && t.at.isBefore(now)) t,
  ];

  List<ShiftTask> upcoming(DateTime now) => [
    for (final t in sorted)
      if (!t.isDone && !t.at.isBefore(now)) t,
  ];

  List<ShiftTask> get done => [
    for (final t in sorted)
      if (t.isDone) t,
  ];

  Map<String, Object?> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'tasks': [for (final t in tasks) t.toJson()],
  };

  factory Shift.fromJson(Map<String, Object?> j) => Shift(
    start: DateTime.parse(j['start']! as String),
    end: DateTime.parse(j['end']! as String),
    tasks: [
      for (final t in (j['tasks'] as List?) ?? const [])
        ShiftTask.fromJson((t as Map).cast<String, Object?>()),
    ],
  );
}

/// [first] anından başlayarak her [everyHours] saatte bir, vardiya sonuna
/// kadar iş zamanları. [everyHours] 0 ise yalnızca ilk zaman.
List<DateTime> repeatTimes(DateTime first, int everyHours, DateTime end) {
  if (everyHours <= 0) return [first];
  return [
    for (var t = first; t.isBefore(end); t = t.add(Duration(hours: everyHours)))
      t,
  ];
}

String hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Vardiya devri için düz metin özet (yatağa göre).
String handoverText(Shift s) {
  final byBed = <String, List<ShiftTask>>{};
  for (final t in s.sorted) {
    byBed.putIfAbsent(t.bedLabel, () => []).add(t);
  }
  final b = StringBuffer('Vardiya özeti ${hhmm(s.start)}–${hhmm(s.end)}\n');
  for (final e in byBed.entries) {
    b.writeln('\n${e.key}');
    for (final t in e.value) {
      final mark = t.isDone ? '✓' : '✗';
      final when = t.isDone ? ' (yapıldı ${hhmm(t.doneAt!)})' : ' (YAPILMADI)';
      b.writeln(
        '$mark ${hhmm(t.at)} ${t.title}${t.important ? ' ⚠' : ''}$when',
      );
      if (t.note.isNotEmpty) b.writeln('   Not: ${t.note}');
    }
  }
  return b.toString().trimRight();
}

/// Vardiyayı yalnızca bu telefonda saklar.
class ShiftStore {
  static const _key = 'shift_v1';

  /// Bittikten bu kadar sonra eski vardiya kendiliğinden silinir.
  static const keepAfterEnd = Duration(hours: 12);

  Future<Shift?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Shift.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return null;
    }
  }

  Future<void> save(Shift? s) async {
    final prefs = await SharedPreferences.getInstance();
    if (s == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(s.toJson()));
    }
  }
}

/// Sık kullanılan işler: ad, tür ve önerilen tekrar (saat; 0 tekrar yok).
/// Doz bilgisi bilerek yoktur; doz hekim istemine göre nota yazılır.
const quickTasks = <(String, TaskKind, int)>[
  ('Nörolojik takip', TaskKind.monitor, 1),
  ('Yaşam bulguları', TaskKind.monitor, 4),
  ('Nimodipin', TaskKind.drug, 4),
  ('Antibiyotik', TaskKind.drug, 0),
  ('İnsülin / kan şekeri', TaskKind.drug, 0),
  ('Antiepileptik', TaskKind.drug, 0),
  ('Pozisyon değişimi', TaskKind.care, 2),
  ('Aldığı-çıkardığı', TaskKind.monitor, 0),
  ('Kan alımı', TaskKind.lab, 0),
  ('BT / MR / tetkik', TaskKind.lab, 0),
  ('Konsültasyon takibi', TaskKind.other, 0),
  ('Hasta / yakın eğitimi', TaskKind.other, 0),
];
