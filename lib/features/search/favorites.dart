import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yıldızlanan sayfaların kimlikleri (yalnızca bu telefonda).
///
/// Uygulama boyunca tek nesne kullanılır; değişince dinleyiciler
/// (ana ekrandaki favoriler satırı, yıldız düğmeleri) yenilenir.
class Favorites extends ChangeNotifier {
  Favorites._();

  static final instance = Favorites._();

  static const _key = 'favorites_v1';

  List<String> _ids = const [];
  bool _loaded = false;

  List<String> get ids => _ids;

  bool contains(String id) => _ids.contains(id);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _ids = prefs.getStringList(_key) ?? const [];
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    await load();
    _ids = contains(id) ? [..._ids.where((e) => e != id)] : [..._ids, id];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids);
  }

  /// Testlerde baştan başlamak için.
  @visibleForTesting
  void reset() {
    _ids = const [];
    _loaded = false;
  }
}

/// Uygulama çubuğu için yıldız düğmesi.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton(this.id, {super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final fav = Favorites.instance;
    fav.load();
    return ListenableBuilder(
      listenable: fav,
      builder: (context, _) {
        final on = fav.contains(id);
        return IconButton(
          tooltip: on ? 'Favorilerden çıkar' : 'Favorilere ekle',
          icon: Icon(
            on ? Icons.star : Icons.star_border,
            color: on ? Colors.amber : null,
          ),
          onPressed: () => fav.toggle(id),
        );
      },
    );
  }
}
