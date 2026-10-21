import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda saklanan uygulama ayarları: tema ve açılış uyarısının onayı.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  static const _themeKey = 'theme_mode';
  static const _disclaimerKey = 'disclaimer_accepted_v1';

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async {
    return AppSettings._(await SharedPreferences.getInstance());
  }

  ThemeMode get themeMode {
    final name = _prefs.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  bool get disclaimerAccepted => _prefs.getBool(_disclaimerKey) ?? false;

  Future<void> acceptDisclaimer() async {
    await _prefs.setBool(_disclaimerKey, true);
    notifyListeners();
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
