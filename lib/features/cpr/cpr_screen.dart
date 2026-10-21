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
    WakelockPlus.disable();
    super.dispose();
  }

  void _start() {
    setState(_session.start);
    WakelockPlus.enable();
    HapticFeedback.heavyImpact();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    for (final alert in _session.pollAlerts()) {
      switch (alert) {
        case CprAlert.rhythmCheckDue:
        case CprAlert.adrenalineOverdue:
          _sounds.alarm();
        case CprAlert.adrenalineWindowOpen:
          _sounds.chime();
      }
    }
    setState(() {});
  }

  void _stopped() {
    _ticker?.cancel();
    _sounds.setMetronome(false);
    WakelockPlus.disable();
  }

  void _act(VoidCallback action) {
    HapticFeedback.selectionClick();
    setState(action);
    if (_session.hasEnded) _stopped();
  }

  Future<void> _rhythmCheck() async {
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
                'Ritim / nabız kontrolü sonucu',
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (rhythm != null) _act(() => _session.recordRhythmCheck(rhythm));
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
        _CycleCard(session: s, onCheck: _rhythmCheck),
        const SizedBox(height: 8),
        _AdrenalineCard(session: s, onGiven: () => _act(s.recordAdrenaline)),
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
        for (final e in s.events.reversed.take(5))
          ListTile(
            dense: true,
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
          '• Her 2 dakikada ritim/nabız kontrolü için sesli uyarı verilir.\n'
          '• "Adrenalin verildi" dediğinizde 3. dakikada hafif, 5. dakikada '
          'güçlü uyarı verilir.\n'
          '• Şok, amiodaron, havayolu ve ROSC tek dokunuşla saatiyle kaydedilir.\n'
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

class _CycleCard extends StatelessWidget {
  const _CycleCard({required this.session, required this.onCheck});

  final CprSession session;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final due = session.rhythmCheckDue;
    // Kontrol zamanı geldiğinde kart yarım saniyede bir yanıp söner.
    final flash = due && DateTime.now().millisecond < 500;
    final theme = Theme.of(context);
    final progress =
        (session.cycleElapsed.inMilliseconds /
                CprSession.cycleLength.inMilliseconds)
            .clamp(0.0, 1.0);
    return Card(
      color: due
          ? (flash ? Colors.red.shade700 : Colors.red.shade400)
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              due
                  ? 'RİTİM / NABIZ KONTROLÜ'
                  : '${session.cycleNumber}. döngü · kontrole kalan',
              style: theme.textTheme.titleMedium?.copyWith(
                color: due ? Colors.white : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              due
                  ? '+${formatDuration(-session.cycleRemaining)}'
                  : formatDuration(session.cycleRemaining),
              style: theme.textTheme.displaySmall?.copyWith(
                color: due ? Colors.white : null,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: due
                    ? FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade800,
                      )
                    : null,
                onPressed: onCheck,
                icon: const Icon(Icons.monitor_heart),
                label: const Text('Kontrol yapıldı · ritmi seç'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdrenalineCard extends StatelessWidget {
  const _AdrenalineCard({required this.session, required this.onGiven});

  final CprSession session;
  final VoidCallback onGiven;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final since = session.sinceAdrenaline;
    final (Color? bg, String status) = switch (session.adrenalineStatus) {
      AdrenalineStatus.notGiven => (null, 'Henüz verilmedi'),
      AdrenalineStatus.waiting => (
        null,
        '3. dakikaya kalan: ${formatDuration(CprSession.adrenalineMinInterval - since!)}',
      ),
      AdrenalineStatus.window => (
        Colors.amber.shade300,
        'Doz verilebilir (3–5 dk aralığı)',
      ),
      AdrenalineStatus.overdue => (
        Colors.orange.shade400,
        'ADRENALİN ZAMANI: 5 dk geçti',
      ),
    };
    final onColor = bg != null ? Colors.black : null;
    return Card(
      color: bg ?? theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vaccines, color: onColor),
                const SizedBox(width: 8),
                Text(
                  'Adrenalin · ${session.adrenalineCount} doz',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (since != null)
                  Text(
                    'son: ${formatDuration(since)} önce',
                    style: TextStyle(color: onColor),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: theme.textTheme.titleSmall?.copyWith(color: onColor),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onGiven,
                icon: const Icon(Icons.add),
                label: const Text('Adrenalin verildi (1 mg)'),
              ),
            ),
          ],
        ),
      ),
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
        Text(
          'Başlangıç: ${formatClock(session.startedAt!)} · '
          'Toplam süre: ${formatDuration(session.elapsed)}',
        ),
        Text(
          'Adrenalin: ${session.adrenalineCount} doz · '
          'Şok: ${session.shockCount} · '
          'Amiodaron: ${session.amiodaroneCount} doz',
        ),
        const Divider(height: 24),
        for (final e in session.events)
          ListTile(
            dense: true,
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
            'sonra).',
      ),
      (
        'Amiodaron',
        'Şoka dirençli VF/nabızsız VT\'de 300 mg IV/IO bolus '
            '(3. şoktan sonra), gerekirse 150 mg (5. şoktan sonra).',
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
