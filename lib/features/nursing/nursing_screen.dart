import 'package:flutter/material.dart';

import '../../content/content_screen.dart';
import '../scales/scale.dart';
import '../scales/scale_screen.dart';
import 'emergency_codes_screen.dart';
import 'pressure_injury_screen.dart';

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

const _careGuides = [
  (Icons.local_drink, 'Yatak başı yutma taraması', 'yutma-taramasi.md'),
  (
    Icons.sentiment_dissatisfied,
    'Ağrı değerlendirmesi',
    'agri-degerlendirme.md',
  ),
  (Icons.hotel, 'İnme hastasında pozisyon', 'inme-pozisyon.md'),
  (Icons.restaurant, 'NG sonda ve enteral beslenme', 'ngs-beslenme.md'),
  (Icons.water_drop, 'İdrar sondası bakımı (CAUTI)', 'idrar-sondasi.md'),
  (Icons.clean_hands, 'Ağız bakımı', 'agiz-bakimi.md'),
  (Icons.bloodtype, 'DVT önlemleri', 'dvt-onlemleri.md'),
  (Icons.warning_amber, 'Düşme önlemleri', 'dusme-onlemleri.md'),
  (Icons.back_hand, 'Fiziksel kısıtlama', 'fiziksel-kisitlama.md'),
];

const _safetyGuides = [
  (Icons.medication_liquid, 'Güvenli ilaç uygulama', 'guvenli-ilac.md'),
  (Icons.masks, 'İzolasyon önlemleri', 'izolasyon.md'),
  (Icons.forum, 'SBAR ile iletişim ve örnekler', 'sbar-ornekleri.md'),
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
            Icons.healing,
            'Bası yarası: evreler (görsel) ve bakım',
            () => push(const PressureInjuryScreen()),
          ),
          for (final (icon, title, file) in _careGuides)
            tile(icon, title, () => page(file, title)),
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
          tile(
            Icons.quiz,
            'Denetim soruları ve cevapları (JCI, SKS)',
            () => page('jci-sss.md', 'Denetim Soruları'),
          ),
          for (final (icon, title, file) in _safetyGuides)
            tile(icon, title, () => page(file, title)),
          header('Hemşirelik tanıları'),
          for (final (title, file) in _diagnoses)
            tile(Icons.assignment, title, () => page('tanilar/$file', title)),
        ],
      ),
    );
  }
}
