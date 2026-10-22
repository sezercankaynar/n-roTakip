import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda saklanan uygulama ayarları: tema, yazı boyutu ve açılış
/// uyarısının onayı.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  static const _themeKey = 'theme_mode';
  static const _disclaimerKey = 'disclaimer_accepted_v1';
  static const _textScaleKey = 'text_scale';

  /// Seçilebilen yazı boyutları (ad, çarpan).
  static const textScales = [
    ('Normal', 1.0),
    ('Büyük', 1.15),
    ('Çok büyük', 1.3),
  ];

  /// `null` ise ayarlar yalnızca bellekte tutulur (cihaz deposu açılamadı).
  final SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  bool _disclaimerAccepted = false;
  double _textScale = 1.0;

  static Future<AppSettings> load() async {
    final settings = AppSettings._(await SharedPreferences.getInstance());
    settings._readFromPrefs();
    return settings;
  }

  /// Cihaz deposu kullanılamadığında yedek: ayarlar uygulama kapanınca unutulur.
  factory AppSettings.inMemory() => AppSettings._(null);

  void _readFromPrefs() {
    final prefs = _prefs!;
    final name = prefs.getString(_themeKey);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
    _disclaimerAccepted = prefs.getBool(_disclaimerKey) ?? false;
    _textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
  }

  /// Telefonun yazı boyutunun üstüne uygulanan çarpan.
  double get textScale => _textScale;

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    notifyListeners();
    await _save(() => _prefs?.setDouble(_textScaleKey, scale));
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _save(() => _prefs?.setString(_themeKey, mode.name));
  }

  bool get disclaimerAccepted => _disclaimerAccepted;

  Future<void> acceptDisclaimer() async {
    _disclaimerAccepted = true;
    notifyListeners();
    await _save(() => _prefs?.setBool(_disclaimerKey, true));
  }

  Future<void> _save(Future<bool>? Function() write) async {
    try {
      await write();
    } catch (e) {
      debugPrint('Ayar kaydedilemedi: $e');
    }
  }
}

/// Ayarlara widget ağacının her yerinden erişim sağlar.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()!
        .notifier!;
  }
}
