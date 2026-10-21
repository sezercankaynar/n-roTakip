import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../widgets/content_status.dart';
import 'cpr_session.dart';
import 'cpr_sounds.dart';

const _cprSources = [
  'American Heart Association. 2025 AHA Guidelines for Cardiopulmonary '
      'Resuscitation and Emergency Cardiovascular Care. Circulation. 2025.',
  'European Resuscitation Council Guidelines 2025: Adult Advanced Life '
      'Support. Resuscitation. 2025.',
];

/// CPR sırasında ekranın kapanmasını engeller; başarısız olursa sessizce geçer.
void _setWakelock(bool on) {
  WakelockPlus.toggle(enable: on).catchError((Object e) {
    debugPrint('Ekran kilidi ayarlanamadı: $e');
  });
}

class CprScreen extends StatefulWidget {
  const CprScreen({super.key});

  @override
  State<CprScreen> createState() => _CprScreenState();
}

class _CprScreenState extends State<CprScreen> {
  var _session = CprSession();
  final _sounds = CprSounds();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _sounds.dispose();
    _setWakelock(false);
    super.dispose();
  }

  void _start() {
    setState(_session.start);
    _setWakelock(true);
    HapticFeedback.heavyImpact();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (_session.pollAlerts().isNotEmpty) _sounds.alarm();
    setState(() {});
  }

  void _stopped() {
    _ticker?.cancel();
    _sounds.setMetronome(false);
    _setWakelock(false);
  }

  void _act(VoidCallback action) {
    HapticFeedback.selectionClick();
    setState(action);
    if (_session.hasEnded) _stopped();
  }

  Future<void> _pulseCheck() async {
    // Kayıt basış anında yapılır; ritim seçimi isteğe bağlıdır.
    _act(_session.recordPulseCheck);
    final rhythm = await showModalBottomSheet<Rhythm>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Nabız kontrolü kaydedildi. Ritim? (isteğe bağlı)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            for (final r in Rhythm.values)
              ListTile(
                leading: Icon(switch (r) {
                  Rhythm.shockable => Icons.bolt,
                  Rhythm.nonShockable => Icons.horizontal_rule,
                  Rhythm.pulse => Icons.favorite,
                }),
                title: Text(r.label),
                onTap: () => Navigator.pop(context, r),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Ritim belirtmeden devam et'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (rhythm != null) _act(() => _session.setLastPulseRhythm(rhythm));
  }

  Future<void> _otherDrug() async {
    // Zaman butona basıldığı an alınır; ilaç adını yazmak kaydı geciktirmez.
    final pressedAt = _session.elapsed;
    HapticFeedback.selectionClick();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _OtherDrugDialog(at: pressedAt),
    );
    if (result == null) return;
    final (name, dose) = result;
    _act(() => _session.recordOtherDrug(name, dose: dose, at: pressedAt));
  }

  Future<void> _confirmEnd() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CPR sonlandırılsın mı?'),
        content: const Text('Sayaçlar durur ve özet gösterilir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sonlandır'),
          ),
        ],
      ),
    );
    if (ok == true) _act(_session.end);
  }

  void _reset() {
    setState(() => _session = CprSession());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_session.isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CPR Zamanlayıcı'),
          actions: [
            IconButton(
              tooltip: 'Geri döndürülebilir nedenler (4H 4T)',
              icon: const Text(
                '4H4T',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showSheet(context, const _ReversibleCauses()),
            ),
            IconButton(
              tooltip: 'Hatırlatmalar ve kaynaklar',
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showSheet(context, const _CprInfo()),
            ),
          ],
        ),
        body: SafeArea(
          child: !_session.hasStarted
              ? _StartView(onStart: _start)
              : _session.hasEnded
              ? _SummaryView(session: _session, onReset: _reset)
              : _buildRunning(context),
        ),
      ),
    );
  }

  Widget _buildRunning(BuildContext context) {
    final s = _session;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Center(child: Text('Toplam süre', style: theme.textTheme.titleSmall)),
        Center(
          child: Text(
            formatDuration(s.elapsed),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ScheduleCard(
          session: s,
          task: ScheduledTask.pulseCheck,
          icon: Icons.monitor_heart,
          count: s.pulseCheckCount,
          buttonLabel: 'Nabız kontrolü yapıldı',
          onPressed: _pulseCheck,
        ),
        const SizedBox(height: 8),
        _ScheduleCard(
          session: s,
          task: ScheduledTask.adrenaline,
          icon: Icons.vaccines,
          count: s.adrenalineCount,
          buttonLabel: 'Adrenalin yapıldı (1 mg)',
          onPressed: () => _act(s.recordAdrenaline),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: [
            _ActionButton(
              icon: Icons.bolt,
              label: 'Şok (${s.shockCount})',
              onPressed: () => _act(s.recordShock),
            ),
            _ActionButton(
              icon: Icons.vaccines,
              label: 'Amiodaron (${s.amiodaroneCount})',
              onPressed: () => _act(s.recordAmiodarone),
            ),
            _ActionButton(
              icon: Icons.medication_liquid,
              label: 'Atropin (${s.atropineCount})',
              onPressed: () => _act(s.recordAtropine),
            ),
            _ActionButton(
              icon: Icons.add_circle_outline,
              label: 'Diğer ilaç',
              onPressed: _otherDrug,
            ),
            _ActionButton(
              icon: Icons.air,
              label: 'Havayolu',
              onPressed: () => _act(s.recordAirway),
            ),
            _ActionButton(
              icon: Icons.favorite,
              label: 'ROSC',
              color: Colors.green,
              onPressed: () => _act(s.recordRosc),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          value: _sounds.metronomeOn,
          onChanged: (v) => setState(() => _sounds.setMetronome(v)),
          secondary: const Icon(Icons.graphic_eq),
          title: const Text('Kompresyon metronomu (110/dk)'),
        ),
        const Divider(),
        Text('Son kayıtlar', style: theme.textTheme.titleSmall),
        for (final e in s.timeline.reversed.take(6))
          ListTile(
            dense: true,
            textColor: e.confirmed ? null : theme.colorScheme.error,
            leading: Text(
              formatDuration(e.elapsed),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            title: Text(e.label),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _confirmEnd,
          icon: const Icon(Icons.stop),
          label: const Text('CPR\'ı sonlandır'),
        ),
      ],
    );
  }
}

void _showSheet(BuildContext context, Widget child) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: child,
      ),
    ),
  );
}

class _StartView extends StatelessWidget {
  const _StartView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
              ),
              onPressed: onStart,
              child: const Text(
                'BAŞLAT',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Başlattığınızda:\n'
          '• İlk adrenalin dozu CPR başlangıcında (00:00), sonrakiler 3., 6., '
          '9. dakikalarda; nabız kontrolü 2., 4., 6. dakikalarda planlanır ve '
          'zamanı gelince sesli uyarı verilir.\n'
          '• İşlemi yaptığınızda ilgili butona basın. Planlanan zamandan en '
          'fazla 30 sn önce veya 60 sn sonra basarsanız kayda planlanan tam '
          'zaman yazılır. Basılmayan işlemler kayıtta "onaylanmadı" görünür.\n'
          '• Şok, amiodaron, atropin, havayolu ve ROSC tek dokunuşla saatiyle '
          'kaydedilir. Listede olmayan ilaçlar "Diğer ilaç" ile adı ve dozu '
          'yazılarak eklenir.\n'
          '• CPR süresince ekran kapanmaz.\n'
          '• Sonunda saat saat özet çıkar. Hasta bilgisi istenmez ve '
          'kayıt saklanmaz.',
        ),
        const SizedBox(height: 16),
        const SourcesCard(status: ReviewStatus.draft, sources: _cprSources),
      ],
    );
  }
}

/// Planlı bir işlemin (nabız kontrolü veya adrenalin) geri sayım kartı.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.session,
    required this.task,
    required this.icon,
    required this.count,
    required this.buttonLabel,
    required this.onPressed,
  });

  final CprSession session;
  final ScheduledTask task;
  final IconData icon;
  final int count;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = session.dueSlot(task);
    final isDue = due != null;
    // Zamanı geldiğinde kart yarım saniyede bir yanıp söner.
    final flash = isDue && DateTime.now().millisecond < 500;
    final baseColor = task == ScheduledTask.pulseCheck
        ? Colors.red
        : Colors.deepOrange;
    final fg = isDue ? Colors.white : null;
    final remaining = session.untilNext(task);
    final progress =
        1 - remaining.inMilliseconds / task.interval.inMilliseconds;
    return Card(
      color: isDue
          ? (flash ? baseColor.shade700 : baseColor.shade400)
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${task.label} · $count kez',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'her ${task.interval.inMinutes} dk',
                  style: TextStyle(color: fg),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isDue
                  ? 'ŞİMDİ · planlanan: '
                        '${formatDuration(CprSession.slotTime(task, due))}'
                  : 'Sonrakine kalan',
              style: theme.textTheme.titleSmall?.copyWith(
                color: fg,
                fontWeight: isDue ? FontWeight.bold : null,
              ),
            ),
            if (!isDue)
              Text(
                formatDuration(remaining),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            const SizedBox(height: 8),
            if (!isDue)
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 6,
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: isDue
                    ? FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: baseColor.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      )
                    : null,
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Diğer ilaç" kaydı: ilaç adı (zorunlu) ve doz (isteğe bağlı).
class _OtherDrugDialog extends StatefulWidget {
  const _OtherDrugDialog({required this.at});

  final Duration at;

  @override
  State<_OtherDrugDialog> createState() => _OtherDrugDialogState();
}

class _OtherDrugDialogState extends State<_OtherDrugDialog> {
  static const _suggestions = [
    'Sodyum bikarbonat',
    'Kalsiyum glukonat',
    'Kalsiyum klorür',
    'Magnezyum sülfat',
    'Lidokain',
    'Sıvı bolus (SF)',
  ];

  final _name = TextEditingController();
  final _dose = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(context, (_name.text, _dose.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Diğer ilaç · ${formatDuration(widget.at)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final n in _suggestions)
                  ChoiceChip(
                    label: Text(n),
                    selected: _name.text == n,
                    onSelected: (_) => _name.text = n,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'İlaç adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dose,
              decoration: const InputDecoration(
                labelText: 'Doz (isteğe bağlı), ör. 2 g',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Text(
              'Kayda butona bastığınız an (${formatDuration(widget.at)}) '
              'yazılır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : _save,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: color != null
          ? FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            )
          : null,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, textAlign: TextAlign.center),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.session, required this.onReset});

  final CprSession session;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('CPR Özeti', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        for (final line in session.summaryLines())
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              line,
              style: line == 'UYGULANAN İLAÇLAR'
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodyLarge,
            ),
          ),
        const Divider(height: 24),
        for (final e in session.timeline)
          ListTile(
            dense: true,
            textColor: e.confirmed ? null : theme.colorScheme.error,
            contentPadding: EdgeInsets.zero,
            leading: Text(
              formatClock(e.time),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            title: Text(e.label),
            trailing: Text('+${formatDuration(e.elapsed)}'),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: session.summaryText()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Özet kopyalandı. Kayıt sistemine '
                  'yapıştırabilirsiniz.',
                ),
              ),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Özeti kopyala'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Yeni CPR'),
        ),
        const SizedBox(height: 8),
        Text(
          'Bu özet uygulamayı kapattığınızda silinir.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReversibleCauses extends StatelessWidget {
  const _ReversibleCauses();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const h = [
      ('Hipoksi', 'Havayolu, oksijenizasyon, ventilasyon'),
      ('Hipovolemi', 'Kanama, sıvı kaybı → sıvı/kan replasmanı'),
      ('Hipo/hiperkalemi ve metabolik', 'K⁺, Ca²⁺, glukoz, asidoz'),
      ('Hipotermi / hipertermi', 'Vücut ısısını ölç'),
    ];
    const t = [
      ('Tromboz', 'Koroner (MI) veya pulmoner (PE)'),
      ('Tansiyon pnömotoraks', 'Tek taraflı solunum sesi, trakea deviasyonu'),
      ('Tamponad (kardiyak)', 'Boyun venlerinde dolgunluk, EKO'),
      ('Toksinler', 'İlaç/zehirlenme öyküsü, antidot'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Geri döndürülebilir nedenler', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Text('4H', style: theme.textTheme.titleMedium),
        for (final (a, b) in h) ListTile(title: Text(a), subtitle: Text(b)),
        Text('4T', style: theme.textTheme.titleMedium),
        for (final (a, b) in t) ListTile(title: Text(a), subtitle: Text(b)),
        const SizedBox(height: 8),
        const SourcesCard(status: ReviewStatus.draft, sources: _cprSources),
      ],
    );
  }
}

class _CprInfo extends StatelessWidget {
  const _CprInfo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const points = [
      (
        'Kompresyon',
        'Hız 100–120/dk, derinlik 5–6 cm, her basıdan sonra '
            'göğsün tam geri gelmesi. Kesintiler en aza indirilmeli (<10 sn).',
      ),
      (
        'Ventilasyon',
        'İleri havayolu yoksa 30:2. İleri havayolu varsa '
            'kesintisiz kompresyon ve 6 saniyede bir (10/dk) solunum.',
      ),
      (
        'Ritim/nabız kontrolü',
        '2 dakikada bir, 10 saniyeyi geçmeden. '
            'Kontrol sırasında kompresyon yapan kişi değiştirilir.',
      ),
      (
        'Adrenalin',
        '1 mg IV/IO, 3–5 dakikada bir. Şoklanamaz ritimde '
            'mümkün olan en kısa sürede; şoklanabilir ritimde ilk şoklar '
            'başarısız olduktan sonra (AHA: 2. şoktan sonra, ERC: 3. şoktan '
            'sonra). Zamanlayıcı ilk dozu başlangıçta, sonrakileri kılavuz '
            'aralığının alt sınırı olan 3 dakikada bir planlar; ekip liderinin '
            'istemine göre "ek" doz da kaydedilebilir.',
      ),
      (
        'Amiodaron',
        'Şoka dirençli VF/nabızsız VT\'de 300 mg IV/IO bolus '
            '(3. şoktan sonra), gerekirse 150 mg (5. şoktan sonra).',
      ),
      (
        'Atropin',
        'Güncel erişkin kardiyak arrest algoritmalarında rutin olarak '
            'önerilmez (asistoli/NEA dahil). Bradikardi tedavisinde '
            'kullanılır. Kayıt butonu ekip liderinin istemi için vardır.',
      ),
      (
        'Kurum protokolü',
        'Doz ve uygulamalarda kurumunuzun protokolü ve '
            'ekip liderinin istemi esastır.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Erişkin İleri Yaşam Desteği: hatırlatmalar',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final (a, b) in points)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(a, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(b),
          ),
        const SizedBox(height: 8),
        const SourcesCard(status: ReviewStatus.draft, sources: _cprSources),
      ],
    );
  }
}
