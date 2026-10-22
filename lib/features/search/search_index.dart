import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../content/content_page.dart';
import '../../content/content_screen.dart';
import '../cpr/cpr_screen.dart';
import '../drugs/drug_guide_screen.dart' show drugAssetDir, normalizeForSearch;
import '../drugs/drug_page.dart';
import '../ecg/ecg_screen.dart';
import '../ecg/rhythms.dart';
import '../exam/gcs_screen.dart';
import '../exam/mrs_screen.dart';
import '../exam/pupil_gauge_screen.dart';
import '../followup/follow_up_screen.dart';
import '../infusion/infusion.dart';
import '../infusion/infusion_screen.dart';
import '../labs/labs.dart';
import '../labs/labs_screen.dart';
import '../nihss/nihss_screen.dart';
import '../nursing/emergency_codes_screen.dart';
import '../nursing/pressure_injury_screen.dart';
import '../protocols/protocols_screen.dart';
import '../protocols/unit_protocol.dart';
import '../scales/scale.dart';
import '../scales/scale_screen.dart';
import '../shift/shift_screen.dart';
import '../stroke/thrombolysis_checklist.dart';
import '../stroke/thrombolytic_dose_screen.dart';
import '../stroke/vascular_map_screen.dart';

/// Aramada ve favorilerde görünen tek bir sayfa veya araç.
class SearchItem {
  const SearchItem({
    required this.id,
    required this.title,
    required this.section,
    required this.icon,
    required this.open,
    this.keywords = const [],
    this.body = '',
  });

  /// Kalıcı kimlik (favorilerde saklanır): içerik dosyası yolu veya
  /// "tool:..." / "rhythm:..." / "protocol:...".
  final String id;
  final String title;
  final String section;
  final IconData icon;
  final List<String> keywords;

  /// Metin içinde arama için (yalnızca içerik sayfalarında).
  final String body;
  final void Function(BuildContext context) open;

  /// 0 eşleşme yok; büyük puan daha iyi eşleşme.
  int score(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return 0;
    final t = normalizeForSearch(title);
    if (t.startsWith(normalizedQuery)) return 100;
    if (t.contains(normalizedQuery)) return 80;
    for (final k in keywords) {
      if (normalizeForSearch(k).contains(normalizedQuery)) return 60;
    }
    if (normalizeForSearch(section).contains(normalizedQuery)) return 30;
    if (body.isNotEmpty && normalizeForSearch(body).contains(normalizedQuery)) {
      return 10;
    }
    return 0;
  }
}

void _push(BuildContext context, Widget w) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

/// İçerik klasörüne göre bölüm adı ve simge.
(String, IconData) _sectionOf(String asset) {
  final parts = asset.split('/');
  final folder = parts.length > 3 ? parts[2] : '';
  return switch (folder) {
    'ilac' => ('İlaç', Icons.medication),
    'hastalik' => ('Hastalık', Icons.menu_book),
    'inme' => ('İnme', Icons.psychology),
    'muayene' => ('Nörolojik muayene', Icons.accessibility_new),
    'resusitasyon' => ('Resüsitasyon', Icons.monitor_heart),
    'hemsirelik' when asset.contains('/tanilar/') => (
      'Hemşirelik tanısı',
      Icons.assignment,
    ),
    'hemsirelik' => ('Hemşirelik', Icons.local_hospital),
    _ => ('İçerik', Icons.article),
  };
}

/// Sabit araçlar (hesaplayıcılar, ölçekler, zamanlayıcılar).
List<SearchItem> toolItems() => [
  SearchItem(
    id: 'tool:cpr',
    title: 'CPR Zamanlayıcı',
    section: 'Araç',
    icon: Icons.timer,
    keywords: const ['kpr', 'resüsitasyon', 'arrest', 'adrenalin', 'mavi kod'],
    open: (c) => _push(c, const CprScreen()),
  ),
  SearchItem(
    id: 'tool:ecg',
    title: 'EKG ritimleri',
    section: 'Araç',
    icon: Icons.show_chart,
    keywords: const ['ekg', 'ritim', 'monitör', 'aritmi'],
    open: (c) => _push(c, const EcgScreen()),
  ),
  SearchItem(
    id: 'tool:ecg-read',
    title: 'EKG okuma ve hız hesabı',
    section: 'Araç',
    icon: Icons.straighten,
    keywords: const ['ekg', 'pr', 'qrs', 'qt', 'kalp hızı'],
    open: (c) => _push(c, const EcgScreen(initialTab: 1)),
  ),
  SearchItem(
    id: 'tool:infusion',
    title: 'İnfüzyon hesaplayıcı',
    section: 'Araç',
    icon: Icons.calculate,
    keywords: const ['ml/sa', 'pompa', 'doz', 'mcg/kg/dk', 'damla', 'hız'],
    open: (c) => _push(c, const InfusionScreen()),
  ),
  SearchItem(
    id: 'tool:drip',
    title: 'Damla hesabı (mL/sa → damla/dk)',
    section: 'Araç',
    icon: Icons.water_drop,
    keywords: const ['damla', 'set', 'serum'],
    open: (c) => _push(c, const InfusionScreen(initialTab: 2)),
  ),
  SearchItem(
    id: 'tool:nihss',
    title: 'NIHSS',
    section: 'Ölçek',
    icon: Icons.psychology,
    keywords: const ['inme ölçeği', 'nih'],
    open: (c) => _push(c, const NihssScreen()),
  ),
  SearchItem(
    id: 'tool:gcs',
    title: 'Glasgow Koma Skalası (GKS)',
    section: 'Ölçek',
    icon: Icons.visibility,
    keywords: const ['gks', 'gcs', 'bilinç', 'koma'],
    open: (c) => _push(c, const GcsScreen()),
  ),
  SearchItem(
    id: 'tool:mrs',
    title: 'Modifiye Rankin Ölçeği (mRS)',
    section: 'Ölçek',
    icon: Icons.accessible,
    keywords: const ['mrs', 'rankin'],
    open: (c) => _push(c, const MrsScreen()),
  ),
  SearchItem(
    id: 'tool:morse',
    title: 'Morse Düşme Ölçeği',
    section: 'Ölçek',
    icon: Icons.elderly,
    keywords: const ['düşme'],
    open: (c) => _push(c, ScaleScreen(scale: morseFallScale)),
  ),
  SearchItem(
    id: 'tool:norton',
    title: 'Norton Bası Yarası Ölçeği',
    section: 'Ölçek',
    icon: Icons.airline_seat_flat,
    keywords: const ['bası yarası', 'dekübit'],
    open: (c) => _push(c, ScaleScreen(scale: nortonScale)),
  ),
  SearchItem(
    id: 'tool:pupil',
    title: 'Pupil cetveli',
    section: 'Araç',
    icon: Icons.remove_red_eye,
    keywords: const ['pupil', 'göz bebeği'],
    open: (c) => _push(c, const PupilGaugeScreen()),
  ),
  SearchItem(
    id: 'tool:vascular',
    title: 'Beyin damar haritası',
    section: 'İnme',
    icon: Icons.account_tree,
    keywords: const ['mca', 'aca', 'pca', 'willis', 'damar'],
    open: (c) => _push(c, const VascularMapScreen()),
  ),
  SearchItem(
    id: 'tool:tpa-dose',
    title: 'Alteplaz / tenekteplaz doz hesabı',
    section: 'İnme',
    icon: Icons.calculate,
    keywords: const ['tpa', 'actilyse', 'trombolitik', 'doz'],
    open: (c) => _push(c, const ThrombolyticDoseScreen()),
  ),
  SearchItem(
    id: 'tool:tpa-check',
    title: 'Trombolitik kontrol listesi',
    section: 'İnme',
    icon: Icons.checklist,
    keywords: const ['tpa', 'kontrendikasyon'],
    open: (c) => _push(c, const ThrombolysisChecklistScreen()),
  ),
  SearchItem(
    id: 'tool:followup',
    title: 'İzlem zamanlayıcı',
    section: 'İnme',
    icon: Icons.alarm,
    keywords: const ['nörolojik takip', 'trombektomi sonrası', 'tpa sonrası'],
    open: (c) => _push(c, const FollowUpListScreen()),
  ),
  SearchItem(
    id: 'tool:pressure',
    title: 'Bası yarası evreleri (görsel)',
    section: 'Hemşirelik',
    icon: Icons.healing,
    keywords: const ['dekübit', 'yara', 'evre'],
    open: (c) => _push(c, const PressureInjuryScreen()),
  ),
  SearchItem(
    id: 'tool:codes',
    title: 'Acil kodlarım',
    section: 'Hemşirelik',
    icon: Icons.campaign,
    keywords: const ['mavi kod', 'pembe kod', 'beyaz kod', 'dahili'],
    open: (c) => _push(c, const EmergencyCodesScreen()),
  ),
  SearchItem(
    id: 'tool:shift',
    title: 'Vardiyam',
    section: 'Araç',
    icon: Icons.today,
    keywords: const ['hatırlatma', 'nöbet', 'görev'],
    open: (c) => _push(c, const ShiftScreen()),
  ),
  SearchItem(
    id: 'tool:protocols',
    title: 'Ünite protokollerim',
    section: 'Araç',
    icon: Icons.edit_note,
    keywords: const ['not', 'talimat'],
    open: (c) => _push(c, const ProtocolsScreen()),
  ),
  SearchItem(
    id: 'tool:labs',
    title: 'Laboratuvar değerleri',
    section: 'Araç',
    icon: Icons.science,
    keywords: const ['lab', 'kritik değer', 'tahlil', 'referans', 'normal'],
    open: (c) => _push(c, const LabsScreen()),
  ),
  for (final t in labTests)
    SearchItem(
      id: 'lab:${t.name}',
      title: t.name,
      section: 'Laboratuvar · ${t.normalText} ${t.unit}'.trim(),
      icon: Icons.science,
      keywords: [...t.aliases, 'lab'],
      open: (c) => _push(c, LabsScreen(initialQuery: t.name)),
    ),
  for (final d in infusionDrugs)
    SearchItem(
      id: 'infusion:${d.name}',
      title: '${d.name} infüzyonu',
      section: 'İnfüzyon · ${d.unit.label}',
      icon: Icons.calculate,
      keywords: const ['infüzyon', 'pompa'],
      open: (c) => _push(c, InfusionScreen(drug: d)),
    ),
  for (final r in rhythms)
    SearchItem(
      id: 'rhythm:${r.name}',
      title: r.name,
      section: 'EKG ritmi',
      icon: Icons.show_chart,
      keywords: [r.aliases, 'ritim'],
      open: (c) => _push(c, RhythmDetailScreen(rhythm: r)),
    ),
];

/// Bütün içerik sayfalarını, araçları ve kullanıcının protokollerini
/// toplar.
Future<List<SearchItem>> buildSearchIndex({
  AssetBundle? bundle,
  UnitProtocolStore? protocols,
}) async {
  final b = bundle ?? rootBundle;
  final manifest = await AssetManifest.loadFromAssetBundle(b);
  final items = <SearchItem>[...toolItems()];
  for (final a in manifest.listAssets()) {
    if (!a.startsWith('assets/content/') || !a.endsWith('.md')) continue;
    final ContentPage page;
    try {
      page = await ContentPage.load(a, bundle: b);
    } on Object {
      continue;
    }
    final (section, icon) = _sectionOf(a);
    final isDrug = a.startsWith(drugAssetDir);
    items.add(
      SearchItem(
        id: a,
        title: page.title,
        section: page.category == null
            ? section
            : '$section · ${page.category}',
        icon: icon,
        keywords: page.aliases,
        body: page.body,
        open: (c) => _push(
          c,
          isDrug
              ? drugPage(a, page.title)
              : ContentScreen(asset: a, title: page.title),
        ),
      ),
    );
  }
  for (final p in await (protocols ?? UnitProtocolStore()).load()) {
    items.add(
      SearchItem(
        id: 'protocol:${p.id}',
        title: p.title,
        section: 'Protokolüm · ${p.kind.label}',
        icon: Icons.edit_note,
        body: p.body,
        open: (c) => openProtocol(c, p),
      ),
    );
  }
  return items;
}

/// Sorguya uyanları en iyi eşleşme önce olacak şekilde sıralar.
List<SearchItem> searchItems(List<SearchItem> all, String query) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return const [];
  final scored =
      [
        for (final i in all)
          if (i.score(q) case final s when s > 0) (s, i),
      ]..sort((a, b) {
        final c = b.$1.compareTo(a.$1);
        return c != 0 ? c : a.$2.title.compareTo(b.$2.title);
      });
  return [for (final (_, i) in scored) i];
}
