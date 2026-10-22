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
  const HomeScreen({super.key});

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
