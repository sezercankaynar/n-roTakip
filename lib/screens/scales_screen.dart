import 'package:flutter/material.dart';

import '../features/exam/gcs_screen.dart';
import '../features/exam/mrs_screen.dart';
import '../features/nihss/nihss_screen.dart';

/// Klinik ölçeklerin listesi.
class ScalesScreen extends StatelessWidget {
  const ScalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const upcoming = [
      ('İtaki Düşme Riski Ölçeği', '0.5'),
      ('Morse Düşme Ölçeği', '0.5'),
      ('Braden Bası Yarası Ölçeği', '0.5'),
      ('Yatak başı yutma taraması (GUSS)', '0.5'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Ölçekler')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('NIHSS'),
            subtitle: const Text('NIH İnme Ölçeği · 15 madde · 0–42 puan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NihssScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Glasgow Koma Skalası (GKS)'),
            subtitle: const Text('Göz, sözel, motor · 3–15 puan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const GcsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.accessible),
            title: const Text('Modifiye Rankin Ölçeği (mRS)'),
            subtitle: const Text('İşlevsel bağımsızlık · 0–6'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const MrsScreen())),
          ),
          const Divider(),
          for (final (name, version) in upcoming)
            ListTile(
              enabled: false,
              leading: const Icon(Icons.schedule),
              title: Text(name),
              subtitle: Text('Sürüm $version ile gelecek'),
            ),
        ],
      ),
    );
  }
}
