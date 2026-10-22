import 'package:flutter/material.dart';

import '../../content/content_page.dart';
import '../../content/content_screen.dart';
import '../drugs/drug_guide_screen.dart' show normalizeForSearch;

/// Kütüphanedeki hastalıklar: (grup, içerik dosyası). İnme sayfaları İnme
/// Merkezi ile ortaktır.
const diseaseEntries = <(String, String)>[
  ('Serebrovasküler hastalıklar', 'assets/content/inme/iskemik-inme.md'),
  (
    'Serebrovasküler hastalıklar',
    'assets/content/inme/intraserebral-kanama.md',
  ),
  ('Serebrovasküler hastalıklar', 'assets/content/inme/subaraknoid-kanama.md'),
  ('Serebrovasküler hastalıklar', 'assets/content/inme/tia.md'),
  ('Serebrovasküler hastalıklar', 'assets/content/hastalik/svst.md'),
  ('Nöbet ve kafa içi basınç', 'assets/content/hastalik/epilepsi-status.md'),
  ('Nöbet ve kafa içi basınç', 'assets/content/hastalik/kibas.md'),
  ('Nöromüsküler hastalıklar', 'assets/content/hastalik/miyastenia.md'),
  ('Nöromüsküler hastalıklar', 'assets/content/hastalik/guillain-barre.md'),
  ('Nöromüsküler hastalıklar', 'assets/content/hastalik/als.md'),
  (
    'Nöroimmünoloji ve enfeksiyon',
    'assets/content/hastalik/multipl-skleroz.md',
  ),
  (
    'Nöroimmünoloji ve enfeksiyon',
    'assets/content/hastalik/menenjit-ensefalit.md',
  ),
  ('Hareket bozukluğu ve demans', 'assets/content/hastalik/parkinson.md'),
  ('Hareket bozukluğu ve demans', 'assets/content/hastalik/demans-deliryum.md'),
  ('Baş ağrısı', 'assets/content/hastalik/bas-agrisi.md'),
];

class DiseaseLibraryScreen extends StatefulWidget {
  const DiseaseLibraryScreen({super.key});

  @override
  State<DiseaseLibraryScreen> createState() => _DiseaseLibraryScreenState();
}

class _DiseaseLibraryScreenState extends State<DiseaseLibraryScreen> {
  late final Future<List<ContentPage>> _pages = Future.wait([
    for (final (_, asset) in diseaseEntries) ContentPage.load(asset),
  ]);
  final _search = TextEditingController();

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

  bool _matches(String group, ContentPage p) {
    final q = normalizeForSearch(_search.text);
    if (q.isEmpty) return true;
    return [
      p.title,
      group,
      ...p.aliases,
    ].any((s) => normalizeForSearch(s).contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hastalık Kütüphanesi')),
      body: FutureBuilder<List<ContentPage>>(
        future: _pages,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Yüklenemedi: ${snap.error}'));
          }
          final pages = snap.data;
          if (pages == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = <Widget>[];
          String? lastGroup;
          for (var i = 0; i < diseaseEntries.length; i++) {
            final (group, asset) = diseaseEntries[i];
            final page = pages[i];
            if (!_matches(group, page)) continue;
            if (group != lastGroup) {
              lastGroup = group;
              rows.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    group,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            }
            rows.add(
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(page.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ContentScreen(asset: asset, title: page.title),
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
                    hintText: 'Hastalık ara (ör. MS, GBS, menenjit)',
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
              if (rows.isEmpty)
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
