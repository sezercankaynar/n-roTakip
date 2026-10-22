import 'dart:async';

import 'package:flutter/material.dart';

import '../features/search/favorites.dart';
import '../features/search/search_index.dart';
import '../features/search/search_screen.dart';
import '../features/shift/shift.dart';
import '../features/shift/shift_screen.dart';
import 'home_screen.dart';

/// Alt menülü ana kabuk: Ana sayfa, Ara, Favoriler, Vardiyam.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  /// Her sekmeye dönüşte artar; o sekmenin içeriği yeniden yüklenir.
  /// 0 olan sekme henüz açılmamıştır ve hiç oluşturulmaz.
  final _visits = [1, 0, 0, 0];

  /// Vardiyada zamanı geçmiş iş sayısı (alt menüde rozet olarak).
  int _late = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadLate();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _loadLate());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadLate() async {
    final s = await ShiftStore().load();
    final n = s?.overdue(DateTime.now()).length ?? 0;
    if (mounted && n != _late) setState(() => _late = n);
  }

  void _select(int i) {
    setState(() {
      if (i != _tab) _visits[i]++;
      _tab = i;
    });
    _loadLate();
  }

  Widget _page(int i) {
    final v = _visits[i];
    if (v == 0) return const SizedBox.shrink();
    return switch (i) {
      0 => const HomeScreen(),
      1 => SearchScreen(key: ValueKey('s$v'), autofocus: false),
      2 => FavoritesScreen(key: ValueKey('f$v')),
      _ => ShiftScreen(key: ValueKey('v$v')),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [for (var i = 0; i < 4; i++) _page(i)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana sayfa',
          ),
          const NavigationDestination(icon: Icon(Icons.search), label: 'Ara'),
          const NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favoriler',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: _late,
              isLabelVisible: _late > 0,
              child: const Icon(Icons.today_outlined),
            ),
            selectedIcon: Badge.count(
              count: _late,
              isLabelVisible: _late > 0,
              child: const Icon(Icons.today),
            ),
            label: 'Vardiyam',
          ),
        ],
      ),
    );
  }
}

/// Yıldızlanan sayfalar.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.index});

  final Future<List<SearchItem>>? index;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final Future<List<SearchItem>> _index =
      widget.index ?? buildSearchIndex();

  @override
  void initState() {
    super.initState();
    Favorites.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: FutureBuilder<List<SearchItem>>(
        future: _index,
        builder: (context, snap) {
          final all = snap.data;
          if (all == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListenableBuilder(
            listenable: Favorites.instance,
            builder: (context, _) {
              final favs = favoriteItems(all, Favorites.instance.ids);
              if (favs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_border,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz favori yok',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sık baktığınız bir sayfanın sağ üstündeki ☆ '
                        'yıldızına veya arama sonucundaki yıldıza dokunun.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final i in favs)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Icon(i.icon),
                      ),
                      title: Text(i.title),
                      subtitle: Text(i.section),
                      trailing: IconButton(
                        tooltip: 'Favorilerden çıkar',
                        icon: const Icon(Icons.star, color: Colors.amber),
                        onPressed: () => Favorites.instance.toggle(i.id),
                      ),
                      onTap: () => i.open(context),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
