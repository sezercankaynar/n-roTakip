import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../content/content_page.dart';
import '../infusion/infusion_screen.dart';
import 'drug_page.dart';
import '../../widgets/content_status.dart';

const drugAssetDir = 'assets/content/ilac/';

/// Kategorilerin listede görünme sırası (listede olmayanlar sona eklenir).
const drugCategoryOrder = [
  'Trombolitik',
  'Antikoagülan ve antidotlar',
  'Hemostatik',
  'Antiagregan',
  'Antihipertansif (acil)',
  'Subaraknoid kanama',
  'Kafa içi basınç',
  'Antiepileptik',
  'Nöroimmünoloji',
  'Parkinson',
  'Resüsitasyon',
  'Vazopressör ve inotrop',
  'Sedasyon ve deliryum',
  'Analjezik',
  'Transdermal (bant) ilaçlar',
  'Antidot',
  'Antibiyotik ve antiviral',
  'Antiemetik ve mide koruyucu',
  'Antihistaminik',
  'Kortikosteroid',
  'Sıvı ve kolloid',
  'Elektrolit ve glukoz',
  'Kan ve kan ürünleri',
  'Diüretik',
  'Endokrin',
];

class DrugEntry {
  const DrugEntry(this.asset, this.page);

  final String asset;
  final ContentPage page;

  String get category => page.category ?? 'Diğer';

  /// Büyük/küçük harf ve Türkçe karakterlerden bağımsız arama.
  bool matches(String query) {
    final q = normalizeForSearch(query);
    if (q.isEmpty) return true;
    return [
      page.title,
      category,
      ...page.aliases,
    ].any((s) => normalizeForSearch(s).contains(q));
  }
}

String normalizeForSearch(String s) {
  const map = {
    'İ': 'i', 'I': 'i', 'ı': 'i', 'Ş': 's', 'ş': 's', 'Ğ': 'g', 'ğ': 'g', //
    'Ü': 'u', 'ü': 'u', 'Ö': 'o', 'ö': 'o', 'Ç': 'c', 'ç': 'c',
  };
  final b = StringBuffer();
  for (final ch in s.trim().split('')) {
    b.write(map[ch] ?? ch.toLowerCase());
  }
  return b.toString();
}

/// Tüm ilaç kartlarını yükler, kategori sırasına ve ada göre sıralar.
Future<List<DrugEntry>> loadDrugs({AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  final manifest = await AssetManifest.loadFromAssetBundle(b);
  final assets = manifest
      .listAssets()
      .where((a) => a.startsWith(drugAssetDir) && a.endsWith('.md'))
      .toList();
  final entries = [
    for (final a in assets) DrugEntry(a, await ContentPage.load(a, bundle: b)),
  ];
  int rank(String c) {
    final i = drugCategoryOrder.indexOf(c);
    return i < 0 ? drugCategoryOrder.length : i;
  }

  entries.sort((x, y) {
    final c = rank(x.category).compareTo(rank(y.category));
    return c != 0
        ? c
        : normalizeForSearch(x.page.title)
              .compareTo(normalizeForSearch(y.page.title));
  });
  return entries;
}

class DrugGuideScreen extends StatefulWidget {
  const DrugGuideScreen({super.key});

  @override
  State<DrugGuideScreen> createState() => _DrugGuideScreenState();
}

class _DrugGuideScreenState extends State<DrugGuideScreen> {
  late final Future<List<DrugEntry>> _drugs = loadDrugs();
  final _search = TextEditingController();

  /// Seçili kategori; `null`: tümü.
  String? _category;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaç Rehberi'),
        actions: [
          IconButton(
            tooltip: 'İnfüzyon hesaplayıcı',
            icon: const Icon(Icons.calculate),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const InfusionScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<DrugEntry>>(
        future: _drugs,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Yüklenemedi: ${snap.error}'));
          }
          final all = snap.data;
          if (all == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = [
            for (final c in drugCategoryOrder)
              if (all.any((d) => d.category == c)) c,
          ];
          final shown = all
              .where(
                (d) =>
                    (_category == null || d.category == _category) &&
                    d.matches(_search.text),
              )
              .toList();
          final rows = <Widget>[];
          String? lastCategory;
          for (final d in shown) {
            if (d.category != lastCategory) {
              lastCategory = d.category;
              rows.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    d.category,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            }
            rows.add(
              ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: Text(d.page.title),
                subtitle: d.page.aliases.isEmpty
                    ? null
                    : Text(
                        d.page.aliases.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: d.page.status == ReviewStatus.draft
                    ? Icon(
                        ReviewStatus.draft.icon,
                        color: ReviewStatus.draft.color,
                        semanticLabel: ReviewStatus.draft.label,
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => drugPage(d.asset, d.page.title),
                  ),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'İlaç, ticari ad veya grup ara',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Temizle',
                            icon: const Icon(Icons.clear),
                            onPressed: _search.clear,
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Row(
                  children: [
                    for (final c in [null, ...categories])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(c ?? 'Tümü (${all.length})'),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Dozlar genel bilgidir. Hekim istemi, kurum protokolü ve '
                  'ilacın kısa ürün bilgisi esastır.',
                ),
              ),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Sonuç bulunamadı.', textAlign: TextAlign.center),
                ),
              ...rows,
            ],
          );
        },
      ),
    );
  }
}
