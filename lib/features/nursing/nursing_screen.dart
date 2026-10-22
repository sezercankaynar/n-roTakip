import 'package:flutter/material.dart';

import '../../content/content_screen.dart';
import '../scales/scale.dart';
import '../scales/scale_screen.dart';
import 'emergency_codes_screen.dart';

const _dir = 'assets/content/hemsirelik/';

const _diagnoses = [
  ('Serebral doku perfüzyonunda etkisizlik riski', 'serebral-perfuzyon.md'),
  ('Yutmada bozulma', 'yutmada-bozulma.md'),
  ('Aspirasyon riski', 'aspirasyon-riski.md'),
  ('Bozulmuş fiziksel mobilite', 'fiziksel-mobilite.md'),
  ('Sözel iletişimde bozulma', 'sozel-iletisim.md'),
  ('Düşme riski', 'dusme-riski.md'),
  ('Bası yarası riski', 'bas-yarasi-riski.md'),
  ('Öz bakım eksikliği', 'oz-bakim.md'),
  ('Akut konfüzyon (deliryum)', 'akut-konfuzyon.md'),
];

class NursingScreen extends StatelessWidget {
  const NursingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void push(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    void page(String file, String title) =>
        push(ContentScreen(asset: '$_dir$file', title: title));
    Widget header(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        t,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
    Widget tile(IconData icon, String title, VoidCallback onTap) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Hemşirelik ve Hasta Güvenliği')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          header('Ölçekler'),
          tile(
            Icons.elderly,
            'Morse Düşme Ölçeği',
            () => push(ScaleScreen(scale: morseFallScale)),
          ),
          tile(
            Icons.airline_seat_flat,
            'Norton Bası Yarası Ölçeği',
            () => push(ScaleScreen(scale: nortonScale)),
          ),
          tile(
            Icons.info_outline,
            'Braden Ölçeği hakkında',
            () => page('braden-hakkinda.md', 'Braden Ölçeği'),
          ),
          header('Bakım rehberleri'),
          tile(
            Icons.local_drink,
            'Yatak başı yutma taraması',
            () => page('yutma-taramasi.md', 'Yutma Taraması'),
          ),
          tile(
            Icons.healing,
            'Bası yarası evreleri',
            () => page('bas-yarasi-evreleri.md', 'Bası Yarası Evreleri'),
          ),
          tile(
            Icons.warning_amber,
            'Düşme önlemleri',
            () => page('dusme-onlemleri.md', 'Düşme Önlemleri'),
          ),
          header('Hasta güvenliği'),
          tile(
            Icons.campaign,
            'Acil kodlarım',
            () => push(const EmergencyCodesScreen()),
          ),
          tile(
            Icons.verified_user,
            'Hasta güvenliği hedefleri (JCI, SKS)',
            () => page('jci-hasta-guvenligi.md', 'Hasta Güvenliği Hedefleri'),
          ),
          header('Hemşirelik tanıları'),
          for (final (title, file) in _diagnoses)
            tile(Icons.assignment, title, () => page('tanilar/$file', title)),
        ],
      ),
    );
  }
}
