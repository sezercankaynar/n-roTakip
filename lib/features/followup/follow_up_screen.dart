import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../content/content_screen.dart';
import '../cpr/cpr_session.dart' show formatClock;
import 'follow_up.dart';
import 'follow_up_notifier.dart';
import 'follow_up_store.dart';

String _hm(DateTime t) => formatClock(t).substring(0, 5);

/// "12 dk sonra", "1 sa 5 dk sonra", "3 dk önce".
String _relative(DateTime t, DateTime now) {
  final d = t.difference(now);
  final m = d.inMinutes.abs();
  final text = m >= 60 ? '${m ~/ 60} sa ${m % 60} dk' : '$m dk';
  if (m == 0) return 'şimdi';
  return d.isNegative ? '$text önce' : '$text sonra';
}

/// İzlem takip zamanlayıcısı: aktif izlemlerin listesi.
class FollowUpListScreen extends StatefulWidget {
  const FollowUpListScreen({
    super.key,
    this.store,
    this.notifier,
    this.clock = DateTime.now,
  });

  final FollowUpStore? store;
  final FollowUpNotifier? notifier;
  final DateTime Function() clock;

  @override
  State<FollowUpListScreen> createState() => _FollowUpListScreenState();
}

class _FollowUpListScreenState extends State<FollowUpListScreen>
    with WidgetsBindingObserver {
  late final FollowUpStore _store = widget.store ?? FollowUpStore();
  late final FollowUpNotifier _notifier =
      widget.notifier ?? LocalFollowUpNotifier.instance;
  List<FollowUp>? _items;
  bool _exact = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _ticker = Timer.periodic(
      const Duration(seconds: 15),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı ayarlardan tam zamanlı alarm iznini verip döndüyse yeniden kur.
    if (state == AppLifecycleState.resumed) _refreshExact(reschedule: true);
  }

  Future<void> _load() async {
    final items = await _store.load();
    if (!mounted) return;
    setState(() => _items = items);
    if (items.isNotEmpty) _refreshExact();
  }

  Future<void> _refreshExact({bool reschedule = false}) async {
    final exact = await _notifier.canScheduleExact();
    if (!mounted) return;
    final gained = exact && !_exact;
    setState(() => _exact = exact);
    if (reschedule && gained) {
      for (final f in _items ?? const <FollowUp>[]) {
        await _notifier.schedule(f);
      }
    }
  }

  Future<void> _save() => _store.save(_items!);

  Future<void> _create() async {
    final result = await showModalBottomSheet<FollowUp>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewFollowUpSheet(
        id: FollowUpStore.nextId(_items!),
        clock: widget.clock,
      ),
    );
    if (result == null) return;
    setState(() => _items!.add(result));
    await _save();
    final exact = await _notifier.ensurePermissions();
    await _notifier.schedule(result);
    if (mounted) setState(() => _exact = exact);
  }

  Future<void> _open(FollowUp f) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FollowUpDetailScreen(
          followUp: f,
          clock: widget.clock,
          onChanged: _save,
          onDelete: () async {
            await _notifier.cancel(f);
            setState(() => _items!.remove(f));
            await _save();
          },
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final now = widget.clock();
    return Scaffold(
      appBar: AppBar(title: const Text('İzlem Takip Zamanlayıcısı')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: items == null ? null : _create,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Yeni izlem'),
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                if (!_exact)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.alarm_off),
                      title: const Text('Bildirimler gecikebilir'),
                      subtitle: const Text(
                        'Telefon "tam zamanlı alarm" iznini vermedi. '
                        'Dokunup izin verin.',
                      ),
                      onTap: () async {
                        await _notifier.ensurePermissions();
                        await _refreshExact(reschedule: true);
                      },
                    ),
                  ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aktif izlem yok.\n\n"Yeni izlem" ile trombolitik veya '
                      'trombektomi sonrası 24 saatlik kontrol takvimini '
                      'başlatın. Her kontrol zamanında telefon bildirim verir.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final f in items) _FollowUpCard(f, now, () => _open(f)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: const Text('Her kontrolde neye bakılır?'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ContentScreen(
                        asset: 'assets/content/inme/tedavi-sonrasi-izlem.md',
                        title: 'Tedavi Sonrası İzlem',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard(this.f, this.now, this.onTap);

  final FollowUp f;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = f.nextPending();
    final overdue = f.overdueCount(now);
    final finished = f.isFinished(now);
    final current = f.currentIndex(now);
    final dueNow = current != null && f.done[current] == null;
    final String status;
    final Color? color;
    if (finished) {
      status = 'İzlem tamamlandı';
      color = Colors.green.shade700;
    } else if (dueNow) {
      status = 'KONTROL ZAMANI (${_hm(f.timeOf(current))})';
      color = Colors.red.shade700;
    } else {
      final upcoming = [
        for (var i = 0; i < f.total; i++)
          if (f.done[i] == null && f.timeOf(i).isAfter(now)) i,
      ];
      final n = upcoming.isEmpty ? next! : upcoming.first;
      status =
          'Sonraki kontrol: ${_hm(f.timeOf(n))} '
          '(${_relative(f.timeOf(n), now)})';
      color = null;
    }
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f.label, style: theme.textTheme.titleLarge),
                  ),
                  Text('${f.completedCount}/${f.total}'),
                ],
              ),
              Text(
                '${f.kind.label} · başlangıç ${_hm(f.start)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                status,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (overdue > 0)
                Text(
                  '$overdue kontrol gecikti veya yapılmadı',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: f.completedCount / f.total),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yeni izlem: etiket, tedavi türü ve başlangıç zamanı.
class _NewFollowUpSheet extends StatefulWidget {
  const _NewFollowUpSheet({required this.id, required this.clock});

  final int id;
  final DateTime Function() clock;

  @override
  State<_NewFollowUpSheet> createState() => _NewFollowUpSheetState();
}

class _NewFollowUpSheetState extends State<_NewFollowUpSheet> {
  final _label = TextEditingController(text: 'Yatak ');
  FollowUpKind _kind = FollowUpKind.thrombolysis;
  TimeOfDay? _startTime; // null: şimdi
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  DateTime? _resolveStart() {
    final now = widget.clock();
    final t = _startTime;
    if (t == null) return now;
    final start = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return start.isAfter(now) ? null : start;
  }

  void _submit() {
    final label = _label.text.trim();
    final start = _resolveStart();
    setState(() {
      _error = label.isEmpty || label == 'Yatak'
          ? 'Bir etiket yazın (ör. Yatak 3).'
          : start == null
          ? 'Başlangıç saati şu andan sonra olamaz.'
          : null;
    });
    if (_error != null) return;
    Navigator.pop(
      context,
      FollowUp(id: widget.id, label: label, kind: _kind, start: start!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni izlem', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'Etiket',
                helperText: 'Hasta adı yazmayın; yatak/oda numarası yeterli.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tedavi', style: theme.textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final k in FollowUpKind.values)
                  ChoiceChip(
                    label: Text(k.label),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Başlangıç', style: theme.textTheme.titleSmall),
            Text(
              'Trombolitik bolus dozunun verildiği veya trombektominin bittiği '
              'an.',
              style: theme.textTheme.bodySmall,
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Şimdi'),
                  selected: _startTime == null,
                  onSelected: (_) => setState(() => _startTime = null),
                ),
                ChoiceChip(
                  label: Text(
                    _startTime == null
                        ? 'Saat seç'
                        : 'Saat: ${_startTime!.format(context)}',
                  ),
                  selected: _startTime != null,
                  onSelected: (_) async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(widget.clock()),
                    );
                    if (picked != null) setState(() => _startTime = picked);
                  },
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.play_arrow),
                label: const Text('İzlemi başlat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek bir izlemin kontrol listesi.
class FollowUpDetailScreen extends StatefulWidget {
  const FollowUpDetailScreen({
    super.key,
    required this.followUp,
    required this.onChanged,
    required this.onDelete,
    this.clock = DateTime.now,
  });

  final FollowUp followUp;
  final Future<void> Function() onChanged;
  final Future<void> Function() onDelete;
  final DateTime Function() clock;

  @override
  State<FollowUpDetailScreen> createState() => _FollowUpDetailScreenState();
}

class _FollowUpDetailScreenState extends State<FollowUpDetailScreen> {
  Timer? _ticker;

  FollowUp get f => widget.followUp;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _markCurrent() {
    final now = widget.clock();
    final i = f.markDone(now);
    if (i == null) return;
    HapticFeedback.mediumImpact();
    setState(() {});
    widget.onChanged();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${i + 1}. kontrol kaydedildi (${_hm(now)})'),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () {
              setState(() => f.undo(i));
              widget.onChanged();
            },
          ),
        ),
      );
  }

  Future<void> _tapCheck(int i) async {
    final now = widget.clock();
    final done = f.done[i];
    if (done == null && f.statusOf(i, now) == CheckStatus.upcoming) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${i + 1}. kontrol (${_hm(f.timeOf(i))})'),
        content: Text(
          done == null
              ? 'Bu kontrol şimdi (${_hm(now)}) yapıldı olarak kaydedilsin mi?'
              : '${_hm(done)} saatindeki kayıt silinsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(done == null ? 'Kaydet' : 'Kaydı sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => done == null ? f.markIndexDone(i, now) : f.undo(i));
    widget.onChanged();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzlem bitirilsin mi?'),
        content: const Text('Kalan bildirimler iptal edilir ve kayıt silinir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.onDelete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = widget.clock();
    final current = f.currentIndex(now);
    final dueNow = current != null && f.done[current] == null;
    final upcoming = [
      for (var i = 0; i < f.total; i++)
        if (f.done[i] == null && f.timeOf(i).isAfter(now)) i,
    ];
    final next = upcoming.isEmpty ? null : upcoming.first;

    var index = 0;
    final rows = <Widget>[];
    for (final phase in followUpPhases) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            phase.label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
      for (var k = 0; k < phase.count; k++, index++) {
        rows.add(_CheckTile(f, index, now, _tapCheck));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(f.label),
        actions: [
          IconButton(
            tooltip: 'İzlemi bitir',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            color: dueNow
                ? Colors.red.shade700
                : theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${f.kind.label} · başlangıç ${_hm(f.start)} · '
                    '${f.completedCount}/${f.total} kontrol',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: dueNow ? Colors.white : null),
                  ),
                  const SizedBox(height: 8),
                  if (dueNow) ...[
                    const Text(
                      'KONTROL ZAMANI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${current + 1}. kontrol · planlanan '
                      '${_hm(f.timeOf(current))}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ] else if (next != null) ...[
                    const Text('Sonraki kontrol'),
                    Text(
                      _hm(f.timeOf(next)),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_relative(f.timeOf(next), now)),
                  ] else
                    Text(
                      'İzlem tamamlandı',
                      style: theme.textTheme.headlineSmall,
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: dueNow
                          ? FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade800,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            )
                          : null,
                      onPressed: dueNow ? _markCurrent : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Kontrol yapıldı'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Geciken bir kontrolü işaretlemek veya bir kaydı silmek için '
              'listeden o kontrole dokunun.',
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile(this.f, this.i, this.now, this.onTap);

  final FollowUp f;
  final int i;
  final DateTime now;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final status = f.statusOf(i, now);
    final done = f.done[i];
    final (IconData icon, Color color, String text) = switch (status) {
      CheckStatus.done => (
        Icons.check_circle,
        Colors.green.shade700,
        'Yapıldı ${_hm(done!)}',
      ),
      CheckStatus.due => (Icons.alarm, Colors.red.shade700, 'Şimdi'),
      CheckStatus.overdue => (
        Icons.error_outline,
        Colors.orange.shade800,
        'Gecikti / yapılmadı',
      ),
      CheckStatus.upcoming => (Icons.schedule, Colors.grey, ''),
    };
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text('${i + 1}. kontrol · ${_hm(f.timeOf(i))}'),
      trailing: Text(text, style: TextStyle(color: color)),
      onTap: () => onTap(i),
    );
  }
}
