import 'package:flutter/material.dart';

import '../../content/content_screen.dart';
import 'gcs_screen.dart';
import 'pupil_gauge_screen.dart';

const _contentDir = 'assets/content/muayene/';

const _pages = [
  ('Hızlı Nörolojik Kontrol', Icons.flash_on, 'hizli-noro-kontrol.md'),
  ('Bilinç Düzeyi ve GKS', Icons.visibility, 'bilinc-gks.md'),
  ('Pupil Muayenesi', Icons.remove_red_eye, 'pupil.md'),
  ('Kraniyal Sinirler', Icons.face, 'kraniyal-sinirler.md'),
  ('Motor Muayene ve Kas Gücü', Icons.fitness_center, 'motor-muayene.md'),
  ('Duyu Muayenesi', Icons.touch_app, 'duyu.md'),
  ('Refleksler ve Babinski', Icons.gavel, 'refleksler.md'),
  (
    'Serebellar Testler, Denge ve Yürüme',
    Icons.directions_walk,
    'serebellar.md',
  ),
  ('Meningeal İrritasyon Bulguları', Icons.warning_amber, 'meningeal.md'),
  ('Konuşma ve Dil', Icons.record_voice_over, 'konusma-dil.md'),
];

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget header(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        t,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
    void push(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: const Text('Nörolojik Muayene')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          header('Araçlar'),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Glasgow Koma Skalası'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const GcsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.radio_button_checked),
            title: const Text('Pupil cetveli (mm)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const PupilGaugeScreen()),
          ),
          header('Muayene rehberi'),
          for (final (title, icon, file) in _pages)
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  push(ContentScreen(asset: '$_contentDir$file', title: title)),
            ),
        ],
      ),
    );
  }
}
