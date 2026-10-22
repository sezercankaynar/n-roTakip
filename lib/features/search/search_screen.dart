import 'package:flutter/material.dart';

import 'favorites.dart';
import 'search_index.dart';

/// Uygulamanın tamamında arama; boşken favorileri gösterir.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.index, this.autofocus = true});

  /// Alt menü sekmesinde klavye kendiliğinden açılmaz.
  final bool autofocus;

  /// Testlerde hazır dizin vermek için.
  final Future<List<SearchItem>>? index;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final Future<List<SearchItem>> _index =
      widget.index ?? buildSearchIndex();
  final _query = TextEditingController();

  static const _suggestions = [
    'nimodipin',
    'noradrenalin',
    'status',
    'VF',
    'GKS',
    'bası yarası',
    'NG sonda',
    'SBAR',
  ];

  @override
  void initState() {
    super.initState();
    Favorites.instance.load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'İlaç, hastalık, ritim, ölçek ara',
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (_query.text.isNotEmpty)
            IconButton(
              tooltip: 'Temizle',
              icon: const Icon(Icons.close),
              onPressed: () => setState(_query.clear),
            ),
        ],
      ),
      body: FutureBuilder<List<SearchItem>>(
        future: _index,
        builder: (context, snap) {
          final all = snap.data;
          if (snap.hasError) {
            return Center(child: Text('Arama hazırlanamadı: ${snap.error}'));
          }
          if (all == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListenableBuilder(
            listenable: Favorites.instance,
            builder: (context, _) => _query.text.trim().isEmpty
                ? _empty(all)
                : _results(searchItems(all, _query.text)),
          );
        },
      ),
    );
  }

  Widget _tile(SearchItem i) {
    final fav = Favorites.instance;
    final on = fav.contains(i.id);
    return ListTile(
      leading: Icon(i.icon),
      title: Text(i.title),
      subtitle: Text(i.section),
      trailing: IconButton(
        tooltip: on ? 'Favorilerden çıkar' : 'Favorilere ekle',
        icon: Icon(
          on ? Icons.star : Icons.star_border,
          color: on ? Colors.amber : null,
        ),
        onPressed: () => fav.toggle(i.id),
      ),
      onTap: () => i.open(context),
    );
  }

  Widget _results(List<SearchItem> found) {
    if (found.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Sonuç bulunamadı. Başka bir yazımla deneyin '
          '(ör. ticari ad veya kısaltma).',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '${found.length} sonuç',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final i in found) _tile(i),
      ],
    );
  }

  Widget _empty(List<SearchItem> all) {
    final theme = Theme.of(context);
    final favs = favoriteItems(all, Favorites.instance.ids);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Sık aranan', style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s),
                  onPressed: () => setState(() => _query.text = s),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Favorilerim', style: theme.textTheme.titleSmall),
        ),
        if (favs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sık baktığınız sayfaları ☆ yıldızına dokunarak buraya '
              'ekleyin. Ana ekranda da görünürler.',
            ),
          )
        else
          for (final i in favs) _tile(i),
      ],
    );
  }
}

/// Favori kimliklerini dizindeki öğelere çevirir (sırayı korur; artık
/// olmayan sayfaları atlar).
List<SearchItem> favoriteItems(List<SearchItem> all, List<String> ids) {
  final byId = {for (final i in all) i.id: i};
  return [for (final id in ids) ?byId[id]];
}

/// Ana ekranın üstündeki arama kutusu ve favori kısayolları.
class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  // Favori satırı için dizin bir kez, ilk favori görününce hazırlanır.
  Future<List<SearchItem>>? _index;

  @override
  void initState() {
    super.initState();
    Favorites.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Favorites.instance,
      builder: (context, _) {
        final ids = Favorites.instance.ids;
        if (ids.isNotEmpty) _index ??= buildSearchIndex();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Material(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                    // Yeni protokol veya favori eklenmiş olabilir.
                    if (mounted && ids.isNotEmpty) {
                      setState(() => _index = buildSearchIndex());
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Ara: ilaç, hastalık, ritim, ölçek…'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (ids.isNotEmpty)
              FutureBuilder<List<SearchItem>>(
                future: _index,
                builder: (context, snap) {
                  final favs = favoriteItems(snap.data ?? const [], ids);
                  if (favs.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      children: [
                        for (final f in favs)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: const Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.amber,
                              ),
                              label: Text(f.title),
                              onPressed: () => f.open(context),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
