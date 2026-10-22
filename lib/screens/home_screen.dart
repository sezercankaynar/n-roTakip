import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../features/cpr/cpr_screen.dart';
import '../features/drugs/drug_guide_screen.dart';
import '../features/stroke/stroke_center_screen.dart';
import '../main.dart';
import 'coming_soon_screen.dart';
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
    'Ölçekler',
    Icons.checklist,
    const Color(0xFF00897B),
    (_) => const ScalesScreen(),
  ),
  _Module(
    'Nörolojik Muayene',
    Icons.accessibility_new,
    const Color(0xFF3949AB),
    (_) => const ComingSoonScreen(title: 'Nörolojik Muayene', version: '0.3'),
  ),
  _Module(
    'Hastalıklar',
    Icons.menu_book,
    const Color(0xFF6D4C41),
    (_) => const ComingSoonScreen(title: 'Hastalıklar', version: '0.4'),
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
    (_) => const ComingSoonScreen(
      title: 'Hemşirelik ve Hasta Güvenliği',
      version: '0.5',
    ),
  ),
  _Module(
    'Ünite Protokolleri',
    Icons.edit_note,
    const Color(0xFF546E7A),
    (_) => const ComingSoonScreen(title: 'Ünite Protokolleri', version: '0.4'),
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName), actions: const [_ThemeMenu()]),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [for (final m in _modules) _ModuleTile(module: m)],
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
