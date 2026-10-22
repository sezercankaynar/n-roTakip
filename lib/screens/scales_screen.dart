import 'package:flutter/material.dart';

import '../features/exam/gcs_screen.dart';
import '../features/exam/mrs_screen.dart';
import '../features/nihss/nihss_screen.dart';
import '../features/scales/scale.dart';
import '../features/scales/scale_screen.dart';

/// Klinik ölçeklerin listesi.
class ScalesScreen extends StatelessWidget {
  const ScalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const upcoming = [
      ('İtaki Düşme Riski Ölçeği', 'kurum formu bekleniyor'),
      ('ICH skoru, Hunt-Hess, FOUR', 'sonraki sürüm'),
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
          ListTile(
            leading: const Icon(Icons.elderly),
            title: const Text('Morse Düşme Ölçeği'),
            subtitle: const Text('Düşme riski · 0–125'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ScaleScreen(scale: morseFallScale),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.airline_seat_flat),
            title: const Text('Norton Bası Yarası Ölçeği'),
            subtitle: const Text('Bası yarası riski · 5–20'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ScaleScreen(scale: nortonScale),
              ),
            ),
          ),
          const Divider(),
          for (final (name, version) in upcoming)
            ListTile(
              enabled: false,
              leading: const Icon(Icons.schedule),
              title: Text(name),
              subtitle: Text(version),
            ),
        ],
      ),
    );
  }
}
