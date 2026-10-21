import 'package:flutter/material.dart';

import '../../content/content_screen.dart';
import 'thrombolysis_checklist.dart';

class _Entry {
  const _Entry(this.title, this.icon, {this.asset, this.screen, this.soon});

  final String title;
  final IconData icon;

  /// `assets/content/inme/` altındaki dosya adı.
  final String? asset;
  final WidgetBuilder? screen;

  /// Henüz yapılmadıysa hangi sürümde geleceği.
  final String? soon;
}

const _sections = <(String, List<_Entry>)>[
  (
    'Acil',
    [
      _Entry(
        'Hızlı Tanıma ve Zaman Hedefleri',
        Icons.timer,
        asset: 'hizli-tanima.md',
      ),
    ],
  ),
  (
    'İnme tipleri',
    [
      _Entry(
        'İskemik İnme',
        Icons.water_drop_outlined,
        asset: 'iskemik-inme.md',
      ),
      _Entry(
        'İntraserebral Kanama',
        Icons.bloodtype,
        asset: 'intraserebral-kanama.md',
      ),
      _Entry(
        'Subaraknoid Kanama',
        Icons.bloodtype_outlined,
        asset: 'subaraknoid-kanama.md',
      ),
      _Entry('Geçici İskemik Atak (TİA)', Icons.history, asset: 'tia.md'),
    ],
  ),
  (
    'Tedavi',
    [
      _Entry(
        'Trombolitik Tedavi',
        Icons.vaccines,
        asset: 'trombolitik-tedavi.md',
      ),
      _Entry(
        'Trombolitik Kontrol Listesi',
        Icons.checklist,
        screen: _checklist,
      ),
      _Entry('Mekanik Trombektomi', Icons.cable, asset: 'trombektomi.md'),
    ],
  ),
  (
    'İzlem',
    [
      _Entry(
        'Trombolitik ve Trombektomi Sonrası İzlem',
        Icons.monitor_heart,
        asset: 'tedavi-sonrasi-izlem.md',
      ),
    ],
  ),
  (
    'Hazırlanıyor',
    [
      _Entry('Beyin Damar Haritası', Icons.hub, soon: '0.2.1'),
      _Entry('Trombektomi: adım adım görsel', Icons.animation, soon: '0.2.2'),
      _Entry('İzlem Takip Zamanlayıcısı', Icons.alarm, soon: '0.2.2'),
    ],
  ),
];

Widget _checklist(BuildContext _) => const ThrombolysisChecklistScreen();

class StrokeCenterScreen extends StatelessWidget {
  const StrokeCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('İnme Merkezi')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final (title, entries) in _sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            for (final e in entries)
              ListTile(
                enabled: e.soon == null,
                leading: Icon(e.icon),
                title: Text(e.title),
                subtitle: e.soon == null
                    ? null
                    : Text('Sürüm ${e.soon} ile gelecek'),
                trailing: e.soon == null
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        e.screen ??
                        (_) => ContentScreen(
                          asset: 'assets/content/inme/${e.asset}',
                          title: e.title,
                        ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
