import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'shift.dart';
import 'shift_notifier.dart';

IconData taskKindIcon(TaskKind k) => switch (k) {
  TaskKind.drug => Icons.medication,
  TaskKind.monitor => Icons.monitor_heart,
  TaskKind.lab => Icons.biotech,
  TaskKind.care => Icons.healing,
  TaskKind.other => Icons.task_alt,
};

/// Vardiyam: o günün işleri, ilaç ve takip hatırlatmaları.
class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key, this.store, this.notifier, this.clock});

  final ShiftStore? store;
  final ShiftNotifier? notifier;

  /// Testlerde sabit saat vermek için.
  final DateTime Function()? clock;

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  late final ShiftStore _store = widget.store ?? ShiftStore();
  late final ShiftNotifier _notifier =
      widget.notifier ?? LocalShiftNotifier.instance;
  DateTime _now() => (widget.clock ?? DateTime.now)();

  bool _loaded = false;
  Shift? _shift;
  bool _byBed = false;
  bool _showDone = false;
  ShiftPreset _preset = shiftPresets.first;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    var s = await _store.load();
    if (s != null && _now().isAfter(s.end.add(ShiftStore.keepAfterEnd))) {
      // Eski vardiya kendiliğinden silinir (gereksiz veri tutulmaz).
      for (final t in s.tasks) {
        await _notifier.cancel(t);
      }
      await _store.save(null);
      s = null;
    }
    if (!mounted) return;
    setState(() {
      _shift = s;
      _loaded = true;
    });
  }

  Future<void> _save(Shift? s) async {
    setState(() => _shift = s);
    await _store.save(s);
  }

  Future<void> _start() async {
    final start = _preset.startFor(_now());
    await _save(
      Shift(
        start: start,
        end: start.add(Duration(hours: _preset.hours)),
      ),
    );
    await _notifier.ensurePermissions();
  }

  Future<void> _replace(ShiftTask t) async {
    final s = _shift!;
    await _save(s.withTasks([for (final e in s.tasks) e.id == t.id ? t : e]));
    await _notifier.schedule(t);
  }

  Future<void> _toggleDone(ShiftTask t) =>
      _replace(t.copyWith(doneAt: () => t.isDone ? null : _now()));

  Future<void> _snooze(ShiftTask t) =>
      _replace(t.copyWith(at: _now().add(const Duration(minutes: 10))));

  Future<void> _delete(ShiftTask t, {bool series = false}) async {
    final s = _shift!;
    final gone = [
      for (final e in s.tasks)
        if (e.id == t.id ||
            (series &&
                t.seriesId != null &&
                e.seriesId == t.seriesId &&
                !e.isDone))
          e,
    ];
    for (final e in gone) {
      await _notifier.cancel(e);
    }
    await _save(s.withTasks([...s.tasks]..removeWhere(gone.contains)));
  }

  Future<void> _add() async {
    final s = _shift!;
    final result = await Navigator.of(context).push<TaskDraft>(
      MaterialPageRoute(
        builder: (_) => TaskEditor(shift: s, now: _now()),
      ),
    );
    if (result == null) return;
    var id = s.nextId;
    final times = repeatTimes(result.at, result.repeatHours, s.end);
    final series = times.length > 1 ? id : null;
    final added = [
      for (final at in times)
        ShiftTask(
          id: id++,
          title: result.title,
          at: at,
          bed: result.bed,
          kind: result.kind,
          important: result.important,
          note: result.note,
          seriesId: series,
        ),
    ];
    await _save(s.withTasks([...s.tasks, ...added]));
    for (final t in added) {
      await _notifier.schedule(t);
    }
    if (!mounted || added.length < 2) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${added.length} hatırlatma eklendi '
          '(${hhmm(added.first.at)}–${hhmm(added.last.at)})',
        ),
      ),
    );
  }

  Future<void> _edit(ShiftTask t) async {
    final result = await Navigator.of(context).push<TaskDraft>(
      MaterialPageRoute(
        builder: (_) => TaskEditor(shift: _shift!, now: _now(), initial: t),
      ),
    );
    if (result == null) return;
    await _replace(
      t.copyWith(
        title: result.title,
        at: result.at,
        bed: result.bed,
        kind: result.kind,
        important: result.important,
        note: result.note,
      ),
    );
  }

  Future<void> _summary({bool ending = false}) async {
    final s = _shift!;
    final text = handoverText(s);
    final open = s.tasks.where((t) => !t.isDone).length;
    final end = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ending ? 'Vardiyayı bitir' : 'Vardiya özeti'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      open == 0
                          ? 'Bütün işler yapıldı. Özeti devir için '
                                'paylaşabilirsiniz. Bitirince liste ve '
                                'hatırlatmalar silinir.'
                          : '$open iş yapılmadı olarak görünüyor. Devir '
                                'için özeti paylaşmayı unutmayın. Bitirince '
                                'liste ve hatırlatmalar silinir.',
                    ),
                  ),
                SelectableText(text),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Özet kopyalandı')),
                );
              }
            },
            child: const Text('Kopyala'),
          ),
          TextButton(
            onPressed: () => SharePlus.instance.share(ShareParams(text: text)),
            child: const Text('Paylaş'),
          ),
          if (ending)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Bitir ve sil'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat'),
            ),
        ],
      ),
    );
    if (end == true) {
      for (final t in s.tasks) {
        await _notifier.cancel(t);
      }
      await _save(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _shift;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s == null ? 'Vardiyam' : 'Vardiyam ${hhmm(s.start)}–${hhmm(s.end)}',
        ),
        actions: [
          if (s != null) ...[
            IconButton(
              tooltip: 'Devir özeti',
              icon: const Icon(Icons.summarize),
              onPressed: _summary,
            ),
            IconButton(
              tooltip: 'Vardiyayı bitir',
              icon: const Icon(Icons.logout),
              onPressed: () => _summary(ending: true),
            ),
          ],
        ],
      ),
      floatingActionButton: s == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add_alarm),
              label: const Text('İş ekle'),
            ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : s == null
          ? _setup()
          : _tasks(s),
    );
  }

  Widget _setup() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(Icons.today, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'Vardiyanı başlat',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'İşe gelince vardiya saatini seç. Sonra ilaçları, takipleri ve '
          'yapılacak işleri saatiyle ekle; zamanı gelince telefon '
          'hatırlatsın. Vardiya bitince özeti devrede paylaşıp listeyi '
          'silebilirsin.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in shiftPresets)
              ChoiceChip(
                label: Text(p.label),
                selected: _preset == p,
                onSelected: (_) => setState(() => _preset = p),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: Text('${_preset.label} vardiyasını başlat'),
        ),
        const SizedBox(height: 16),
        const _PrivacyNote(),
      ],
    );
  }

  Widget _tasks(Shift s) {
    final now = _now();
    final overdue = s.overdue(now);
    final upcoming = s.upcoming(now);
    final done = s.done;
    final theme = Theme.of(context);

    Widget section(String title, List<ShiftTask> items, {Color? color}) =>
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            '$title (${items.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color ?? theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

    List<Widget> list(List<ShiftTask> items, {bool late = false}) {
      if (!_byBed) {
        return [for (final t in items) _tile(t, late: late, showBed: true)];
      }
      final byBed = <String, List<ShiftTask>>{};
      for (final t in items) {
        byBed.putIfAbsent(t.bedLabel, () => []).add(t);
      }
      final beds = byBed.keys.toList()..sort(_compareBeds);
      return [
        for (final b in beds) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(b, style: theme.textTheme.labelLarge),
          ),
          for (final t in byBed[b]!) _tile(t, late: late, showBed: false),
        ],
      ];
    }

    final total = s.tasks.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _ProgressCard(
          shift: s,
          now: now,
          next: upcoming.isEmpty ? null : upcoming.first,
        ),
        const _PrivacyNote(compact: true),
        if (total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.schedule),
                  label: Text('Saate göre'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.bed),
                  label: Text('Yatağa göre'),
                ),
              ],
              selected: {_byBed},
              onSelectionChanged: (v) => setState(() => _byBed = v.first),
            ),
          ),
        if (total == 0)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Henüz iş yok. "İş ekle" ile ilk hatırlatmanı ekle.',
              textAlign: TextAlign.center,
            ),
          ),
        if (overdue.isNotEmpty) ...[
          section('Zamanı geçti', overdue, color: theme.colorScheme.error),
          ...list(overdue, late: true),
        ],
        if (upcoming.isNotEmpty) ...[
          section('Sıradaki işler', upcoming),
          ...list(upcoming),
        ],
        if (done.isNotEmpty) ...[
          ListTile(
            title: Text(
              'Yapıldı (${done.length})',
              style: theme.textTheme.titleSmall,
            ),
            trailing: Icon(_showDone ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _showDone = !_showDone),
          ),
          if (_showDone) ...list(done),
        ],
      ],
    );
  }

  Widget _tile(ShiftTask t, {required bool late, required bool showBed}) {
    final theme = Theme.of(context);
    final color = late ? theme.colorScheme.error : null;
    final subtitle = [
      if (showBed) t.bedLabel,
      t.kind.label,
      if (t.isDone) 'yapıldı ${hhmm(t.doneAt!)}',
      if (t.note.isNotEmpty) t.note,
    ].join(' · ');
    return ListTile(
      leading: Checkbox(value: t.isDone, onChanged: (_) => _toggleDone(t)),
      title: Row(
        children: [
          Text(
            hhmm(t.at),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          if (t.important)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.priority_high, size: 18, color: Colors.orange),
            ),
          Expanded(
            child: Text(
              t.title,
              style: t.isDone
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
          ),
        ],
      ),
      subtitle: Text(subtitle),
      trailing: PopupMenuButton<String>(
        icon: Icon(taskKindIcon(t.kind), color: color),
        onSelected: (v) => switch (v) {
          'snooze' => _snooze(t),
          'edit' => _edit(t),
          'series' => _delete(t, series: true),
          _ => _delete(t),
        },
        itemBuilder: (_) => [
          if (!t.isDone)
            const PopupMenuItem(value: 'snooze', child: Text('10 dk ertele')),
          const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
          const PopupMenuItem(value: 'delete', child: Text('Sil')),
          if (t.seriesId != null)
            const PopupMenuItem(
              value: 'series',
              child: Text('Bu tekrarın kalanını sil'),
            ),
        ],
      ),
      onTap: () => _edit(t),
    );
  }
}

/// Yatak numaralarını sayı gibi sıralar; "Genel" en sona.
int _compareBeds(String a, String b) {
  if (a == b) return 0;
  if (a == 'Genel') return 1;
  if (b == 'Genel') return -1;
  final na = int.tryParse(a.replaceAll(RegExp(r'\D'), ''));
  final nb = int.tryParse(b.replaceAll(RegExp(r'\D'), ''));
  if (na != null && nb != null && na != nb) return na.compareTo(nb);
  return a.compareTo(b);
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.shift, required this.now, this.next});

  final Shift shift;
  final DateTime now;
  final ShiftTask? next;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = shift.tasks.length;
    final done = shift.done.length;
    final left = shift.end.difference(now);
    final leftText = left.isNegative
        ? 'Vardiya süresi doldu'
        : 'Bitişe ${left.inHours} sa ${left.inMinutes % 60} dk';
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$done / $total iş yapıldı',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(leftText, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: total == 0 ? 0 : done / total),
            if (next != null) ...[
              const SizedBox(height: 10),
              Text(
                'Sıradaki: ${hhmm(next!.at)} · ${next!.bedLabel} · '
                '${next!.title}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 0, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Hasta adı yazmayın; yatak veya oda numarası kullanın. Liste '
              'yalnızca bu telefonda tutulur ve vardiya bitince silinir.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// İş ekleme/düzenleme ekranının sonucu.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.at,
    required this.bed,
    required this.kind,
    required this.important,
    required this.note,
    this.repeatHours = 0,
  });

  final String title;
  final DateTime at;
  final String bed;
  final TaskKind kind;
  final bool important;
  final String note;
  final int repeatHours;
}

/// Bir sonraki tam veya yarım saat.
DateTime nextSlot(DateTime now) {
  final base = DateTime(now.year, now.month, now.day, now.hour);
  return now.minute < 30
      ? base.add(const Duration(minutes: 30))
      : base.add(const Duration(hours: 1));
}

class TaskEditor extends StatefulWidget {
  const TaskEditor({
    super.key,
    required this.shift,
    required this.now,
    this.initial,
  });

  final Shift shift;
  final DateTime now;
  final ShiftTask? initial;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _bed = TextEditingController(text: widget.initial?.bed);
  late final _note = TextEditingController(text: widget.initial?.note);
  late TaskKind _kind = widget.initial?.kind ?? TaskKind.drug;
  late bool _important = widget.initial?.important ?? false;
  late DateTime _at = widget.initial?.at ?? nextSlot(widget.now);
  int _repeat = 0;

  static const _repeats = [0, 1, 2, 4, 6, 8, 12];

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _title.dispose();
    _bed.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
      helpText: 'İşin saati',
    );
    if (picked == null) return;
    // Seçilen saati vardiya içine yerleştir (gece vardiyasında ertesi gün).
    final s = widget.shift.start;
    var at = DateTime(s.year, s.month, s.day, picked.hour, picked.minute);
    if (at.isBefore(s)) at = at.add(const Duration(days: 1));
    setState(() => _at = at);
  }

  void _quick((String, TaskKind, int) q) {
    setState(() {
      _title.text = q.$1;
      _kind = q.$2;
      if (!_editing) _repeat = q.$3;
    });
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yapılacak işi yazın')),
      );
      return;
    }
    Navigator.of(context).pop(
      TaskDraft(
        title: title,
        at: _at,
        bed: _bed.text.trim(),
        kind: _kind,
        important: _important,
        note: _note.text.trim(),
        repeatHours: _repeat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = repeatTimes(_at, _repeat, widget.shift.end).length;
    final outside =
        _at.isBefore(widget.shift.start) || !_at.isBefore(widget.shift.end);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'İşi düzenle' : 'İş ekle'),
        actions: [TextButton(onPressed: _save, child: const Text('Kaydet'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (!_editing) ...[
            Text('Hızlı seçim', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final q in quickTasks)
                  ActionChip(
                    avatar: Icon(taskKindIcon(q.$2), size: 18),
                    label: Text(q.$1),
                    onPressed: () => _quick(q),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Yapılacak iş',
              hintText: 'ör. Nimodipin, kan şekeri, BT\'ye götürme',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bed,
                  decoration: const InputDecoration(
                    labelText: 'Yatak / oda',
                    hintText: 'ör. 12',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _pickTime,
                  child: Text(
                    'Saat ${hhmm(_at)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          if (outside)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Bu saat vardiya dışında kalıyor.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskKind>(
            initialValue: _kind,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tür',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final k in TaskKind.values)
                DropdownMenuItem(
                  value: k,
                  child: Row(
                    children: [
                      Icon(taskKindIcon(k), size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(k.label, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (k) => setState(() => _kind = k ?? _kind),
          ),
          if (!_editing) ...[
            const SizedBox(height: 16),
            Text('Tekrar', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in _repeats)
                  ChoiceChip(
                    label: Text(r == 0 ? 'Bir kez' : '$r saatte bir'),
                    selected: _repeat == r,
                    onSelected: (_) => setState(() => _repeat = r),
                  ),
              ],
            ),
            if (_repeat > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Vardiya sonuna kadar $count hatırlatma kurulacak.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Önemli'),
            subtitle: const Text('10 dakika önce de hatırlat'),
            value: _important,
            onChanged: (v) => setState(() => _important = v),
          ),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Not (isteğe bağlı)',
              hintText: 'ör. istemdeki doz, aç karnına, ışıktan koru',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const _PrivacyNote(),
        ],
      ),
    );
  }
}
