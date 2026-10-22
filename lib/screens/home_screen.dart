import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../features/cpr/cpr_screen.dart';
import '../features/diseases/disease_library_screen.dart';
import '../features/drugs/drug_guide_screen.dart';
import '../features/ecg/ecg_screen.dart';
import '../features/exam/exam_screen.dart';
import '../features/infusion/infusion_screen.dart';
import '../features/nursing/nursing_screen.dart';
import '../features/protocols/protocols_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shift/shift.dart';
import '../features/shift/shift_screen.dart';
import '../features/stroke/stroke_center_screen.dart';
import '../main.dart';
import 'scales_screen.dart';

class _Module {
  const _Module(this.title, this.icon, this.color, this.builder);

  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}

final _modules = <_Module>[
  _Module(
    'İnme Merkezi',
    Icons.psychology,
    const Color(0xFF5E35B1),
    (_) => const StrokeCenterScreen(),
  ),
  _Module(
    'CPR Zamanlayıcı',
    Icons.monitor_heart,
    const Color(0xFFC62828),
    (_) => const CprScreen(),
  ),
  _Module(
    'EKG ve Resüsitasyon',
    Icons.show_chart,
    const Color(0xFFD84315),
    (_) => const EcgScreen(),
  ),
  _Module(
    'İnfüzyon Hesaplayıcı',
    Icons.calculate,
    const Color(0xFF00838F),
    (_) => const InfusionScreen(),
  ),
  _Module(
    'Ölçekler',
    Icons.checklist,
    const Color(0xFF00897B),
    (_) => const ScalesScreen(),
  ),
  _Module(
    'Nörolojik Muayene',
    Icons.accessibility_new,
    const Color(0xFF3949AB),
    (_) => const ExamScreen(),
  ),
  _Module(
    'Hastalıklar',
    Icons.menu_book,
    const Color(0xFF6D4C41),
    (_) => const DiseaseLibraryScreen(),
  ),
  _Module(
    'İlaç Rehberi',
    Icons.medication,
    const Color(0xFF2E7D32),
    (_) => const DrugGuideScreen(),
  ),
  _Module(
    'Hemşirelik',
    Icons.local_hospital,
    const Color(0xFFAD1457),
    (_) => const NursingScreen(),
  ),
  _Module(
    'Ünite Protokolleri',
    Icons.edit_note,
    const Color(0xFF546E7A),
    (_) => const ProtocolsScreen(),
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName), actions: const [_ThemeMenu()]),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: HomeSearchBar()),
            const SliverToBoxAdapter(child: ShiftBanner()),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [for (final m in _modules) _ModuleTile(module: m)],
              ),
            ),
          ],
        ),
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

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module});

  final _Module module;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = module.color;
    return Material(
      color: color.withValues(alpha: dark ? 0.30 : 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: module.builder)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(module.icon, size: 44, color: dark ? Colors.white : color),
              const SizedBox(height: 10),
              Text(
                module.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeMenu extends StatelessWidget {
  const _ThemeMenu();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    const labels = {
      ThemeMode.system: 'Telefon ayarına göre',
      ThemeMode.light: 'Açık tema',
      ThemeMode.dark: 'Koyu tema (gece nöbeti)',
    };
    return PopupMenuButton<ThemeMode>(
      icon: const Icon(Icons.brightness_6),
      tooltip: 'Tema',
      initialValue: settings.themeMode,
      onSelected: settings.setThemeMode,
      itemBuilder: (_) => [
        for (final e in labels.entries)
          PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
    );
  }
}
