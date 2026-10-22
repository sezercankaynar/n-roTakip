import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../main.dart';

/// Tema ve yazı boyutu.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final theme = Theme.of(context);
    Widget header(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        t,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          header('Yazı boyutu'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<double>(
              segments: [
                for (final (label, scale) in AppSettings.textScales)
                  ButtonSegment(value: scale, label: Text(label)),
              ],
              selected: {settings.textScale},
              onSelectionChanged: (v) => settings.setTextScale(v.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Örnek metin: Nimodipin 60 mg, 4 saatte bir. Yazı boyutu '
                  'bütün ekranlarda geçerlidir.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          header('Görünüm'),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (m) => settings.setThemeMode(m!),
            child: Column(
              children: [
                for (final (mode, label, icon) in const [
                  (
                    ThemeMode.system,
                    'Telefon ayarına göre',
                    Icons.brightness_auto,
                  ),
                  (ThemeMode.light, 'Açık tema', Icons.light_mode),
                  (ThemeMode.dark, 'Koyu tema (gece nöbeti)', Icons.dark_mode),
                ])
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(label),
                    secondary: Icon(icon),
                  ),
              ],
            ),
          ),
          header('Hakkında'),
          ListTile(
            leading: Image.asset('assets/images/logo.png', width: 36),
            title: const Text(appName),
            subtitle: const Text(
              'Nöroloji hemşire ve hekimleri için cep rehberi. Kişisel veri '
              'toplamaz; bilgiler yalnızca bu telefonda tutulur.',
            ),
          ),
        ],
      ),
    );
  }
}
