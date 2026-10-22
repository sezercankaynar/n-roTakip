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

/// İş başında en sık açılan dört araç.
final _quick = <_Module>[
  _Module(
    'CPR',
    'Zamanlayıcı',
    Icons.monitor_heart_rounded,
    (_) => const CprScreen(),
  ),
  _Module(
    'EKG',
    'Ritim ve algoritma',
    Icons.show_chart_rounded,
    (_) => const EcgScreen(),
  ),
  _Module(
    'İnfüzyon',
    'mL/sa hesabı',
    Icons.calculate_rounded,
    (_) => const InfusionScreen(),
  ),
  _Module(
    'Ölçekler',
    'NIHSS, GKS, mRS',
    Icons.checklist_rounded,
    (_) => const ScalesScreen(),
  ),
];

final _guides = <_Module>[
  _Module(
    'İnme',
    'Damar haritası, trombolitik, izlem',
    Icons.psychology_rounded,
    (_) => const StrokeCenterScreen(),
  ),
  _Module(
    'İlaçlar',
    'Hazırlama, veriliş, yan etkiler',
    Icons.medication_rounded,
    (_) => const DrugGuideScreen(),
  ),
  _Module(
    'Hastalıklar',
    'Belirtiler, tedavi, bakım',
    Icons.menu_book_rounded,
    (_) => const DiseaseLibraryScreen(),
  ),
  _Module(
    'Nörolojik muayene',
    'Bilinç, pupil, motor, refleks',
    Icons.accessibility_new_rounded,
    (_) => const ExamScreen(),
  ),
  _Module(
    'Hemşirelik',
    'Bakım, hasta güvenliği, JCI',
    Icons.local_hospital_rounded,
    (_) => const NursingScreen(),
  ),
];

final _personal = <_Module>[
  _Module(
    'Ünite protokollerim',
    'Kendi akış ve talimatlarınız',
    Icons.edit_note_rounded,
    (_) => const ProtocolsScreen(),
  ),
  _Module(
    'Acil kodlarım',
    'Kod ve dahili numaralar',
    Icons.campaign_rounded,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', width: 30),
            ),
            const SizedBox(width: 10),
            Text(
              appName,
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const _SectionHeader('Hızlı erişim'),
          _QuickGrid(modules: _quick),
          const _SectionHeader('Rehberler'),
          _ListCard(modules: _guides),
          const _SectionHeader('Kişisel'),
          _ListCard(modules: _personal),
          const SizedBox(height: 20),
          Text(
            'İçerik kaynaklıdır ve hemşire onayı sürmektedir. '
            'Klinik karar için kurum protokolü esastır.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Simge kutusu: yuvarlatılmış kare zeminde simge.
class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, {this.inverted = false});

  final IconData icon;

  /// Bordo kart üzerinde (beyaz yarı saydam zemin).
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: inverted
            ? Colors.white.withValues(alpha: 0.16)
            : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: inverted ? Colors.white : scheme.onPrimaryContainer,
      ),
    );
  }
}

/// 2×2 hızlı erişim; ilk kart (CPR) acil olduğu için bordo.
class _QuickGrid extends StatelessWidget {
  const _QuickGrid({required this.modules});

  final List<_Module> modules;

  @override
  Widget build(BuildContext context) {
    Widget row(int a) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _QuickTile(modules[a], emphasized: a == 0)),
          const SizedBox(width: 12),
          Expanded(child: _QuickTile(modules[a + 1])),
        ],
      ),
    );
    return Column(children: [row(0), const SizedBox(height: 12), row(2)]);
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile(this.module, {this.emphasized = false});

  final _Module module;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final bg = emphasized
        ? (dark ? scheme.primaryContainer : scheme.primary)
        : scheme.surfaceContainerLowest;
    final fg = emphasized
        ? (dark ? scheme.onPrimaryContainer : scheme.onPrimary)
        : scheme.onSurface;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: emphasized
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, module),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(module.icon, inverted: emphasized),
              const SizedBox(height: 14),
              Text(
                module.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                module.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alt alta satırlardan oluşan kart.
class _ListCard extends StatelessWidget {
  const _ListCard({required this.modules});

  final List<_Module> modules;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, m) in modules.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 68,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: _IconBox(m.icon),
              title: Text(
                m.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                m.subtitle,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onTap: () => _open(context, m),
            ),
          ],
        ],
      ),
    );
  }
}
