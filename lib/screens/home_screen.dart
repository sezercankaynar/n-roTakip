import 'package:flutter/material.dart';

import '../features/cpr/cpr_screen.dart';
import '../features/diseases/disease_library_screen.dart';
import '../features/drugs/drug_guide_screen.dart';
import '../features/ecg/ecg_screen.dart';
import '../features/exam/exam_screen.dart';
import '../features/infusion/infusion_screen.dart';
import '../features/nursing/emergency_codes_screen.dart';
import '../features/nursing/nursing_screen.dart';
import '../features/protocols/protocols_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shift/shift.dart';
import '../features/shift/shift_screen.dart';
import '../features/stroke/stroke_center_screen.dart';
import '../main.dart';
import 'scales_screen.dart';
import 'settings_screen.dart';

/// Ana ekrandaki bir bölüm kısayolu.
class _Module {
  const _Module(this.title, this.subtitle, this.icon, this.builder);

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}

final _urgent = <_Module>[
  _Module(
    'CPR Zamanlayıcı',
    'Adrenalin · nabız · siklus',
    Icons.monitor_heart,
    (_) => const CprScreen(),
  ),
  _Module(
    'EKG ve Resüsitasyon',
    'Ritimler · algoritmalar',
    Icons.show_chart,
    (_) => const EcgScreen(),
  ),
];

final _calculators = <_Module>[
  _Module(
    'İnfüzyon Hesaplayıcı',
    'mL/sa · yükleme · damla',
    Icons.calculate,
    (_) => const InfusionScreen(),
  ),
  _Module(
    'Ölçekler',
    'NIHSS · GKS · mRS · Morse',
    Icons.checklist,
    (_) => const ScalesScreen(),
  ),
];

final _reference = <_Module>[
  _Module(
    'İnme Merkezi',
    'Damar haritası, trombolitik, izlem',
    Icons.psychology,
    (_) => const StrokeCenterScreen(),
  ),
  _Module(
    'İlaç Rehberi',
    'Hazırlama, veriliş, yan etkiler',
    Icons.medication,
    (_) => const DrugGuideScreen(),
  ),
  _Module(
    'Hastalıklar',
    'Belirtiler, tedavi, bakım',
    Icons.menu_book,
    (_) => const DiseaseLibraryScreen(),
  ),
  _Module(
    'Nörolojik Muayene',
    'Bilinç, pupil, motor, refleks',
    Icons.accessibility_new,
    (_) => const ExamScreen(),
  ),
  _Module(
    'Hemşirelik ve Hasta Güvenliği',
    'Bakım rehberleri, tanılar, JCI',
    Icons.local_hospital,
    (_) => const NursingScreen(),
  ),
];

final _mine = <_Module>[
  _Module(
    'Ünite Protokollerim',
    'Kendi akış ve talimatlarınız',
    Icons.edit_note,
    (_) => const ProtocolsScreen(),
  ),
  _Module(
    'Acil Kodlarım',
    'Hastanenizin kod ve dahilileri',
    Icons.campaign,
    (_) => const EmergencyCodesScreen(),
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.refresh = 0});

  /// Değişince vardiya kartı yeniden yüklenir (sekmeye dönüşte).
  final int refresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 30, height: 30),
            const SizedBox(width: 10),
            Text(
              appName,
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const HomeSearchBar(),
          ShiftBanner(key: ValueKey(refresh)),
          const _SectionHeader('ACİL'),
          _CardRow(modules: _urgent, strong: true),
          const _SectionHeader('HESAPLA'),
          _CardRow(modules: _calculators),
          const _SectionHeader('BİLGİ'),
          _ListCard(modules: _reference),
          const _SectionHeader('BENİM'),
          _ListCard(modules: _mine),
        ],
      ),
    );
  }
}

void _open(BuildContext context, _Module m) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: m.builder));

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Yan yana iki büyük kart (acil araçlar ve hesaplayıcılar).
class _CardRow extends StatelessWidget {
  const _CardRow({required this.modules, this.strong = false});

  final List<_Module> modules;

  /// Acil kartlar: dolu bordo zemin.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Koyu temada açık bordo yerine koyu bordo zemin.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = switch ((strong, dark)) {
      (true, false) => (scheme.primary, scheme.onPrimary),
      (true, true) => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, m) in modules.indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _open(context, m),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(m.icon, size: 34, color: fg),
                          const SizedBox(height: 14),
                          Text(
                            m.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: fg.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alt alta satırlardan oluşan kart (bilgi bölümleri).
class _ListCard extends StatelessWidget {
  const _ListCard({required this.modules});

  final List<_Module> modules;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, m) in modules.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(m.icon),
              ),
              title: Text(
                m.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(m.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, m),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ana ekranın üstündeki "Vardiyam" kartı: sıradaki işi gösterir.
class ShiftBanner extends StatefulWidget {
  const ShiftBanner({super.key});

  @override
  State<ShiftBanner> createState() => _ShiftBannerState();
}

class _ShiftBannerState extends State<ShiftBanner> {
  Shift? _shift;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ShiftStore().load();
    if (mounted) setState(() => _shift = s);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _shift;
    final now = DateTime.now();
    final String title;
    final String subtitle;
    if (s == null) {
      title = 'Vardiyam';
      subtitle = 'Bugünün ilaç ve iş hatırlatmalarını kur';
    } else {
      final late = s.overdue(now).length;
      final next = s.upcoming(now);
      title =
          'Vardiyam ${hhmm(s.start)}–${hhmm(s.end)}'
          '${late > 0 ? ' · $late iş gecikti' : ''}';
      subtitle = next.isEmpty
          ? '${s.done.length}/${s.tasks.length} iş yapıldı'
          : 'Sıradaki: ${hhmm(next.first.at)} · ${next.first.bedLabel} · '
                '${next.first.title}';
    }
    final late = s != null && s.overdue(now).isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: late
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ShiftScreen()),
            );
            await _load();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.today, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, maxLines: 2),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
