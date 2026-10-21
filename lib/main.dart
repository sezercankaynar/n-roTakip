import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_settings.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/home_screen.dart';

const appName = 'NöroCep';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const _Bootstrap());
    },
    (error, stack) {
      debugPrint('Yakalanmamış hata: $error\n$stack');
    },
  );
}

/// Ayarları yüklerken bir şey ters giderse uygulama açılış ekranında
/// takılı kalmasın diye önce bu widget çizilir, ayarlar sonra yüklenir.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  AppSettings? _settings;
  Object? _error;

  @override
  void initState() {
    super.initState();
    AppSettings.load()
        .timeout(const Duration(seconds: 5))
        .then((s) => setState(() => _settings = s))
        .catchError(
          (Object e) => setState(() {
            _error = e;
            _settings = AppSettings.inMemory();
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return NoroCepApp(settings: settings, startupError: _error);
  }
}

class NoroCepApp extends StatelessWidget {
  const NoroCepApp({super.key, required this.settings, this.startupError});

  final AppSettings settings;

  /// Ayarlar yüklenemediyse hata; uygulama yine de ayarlar kaydedilmeden açılır.
  final Object? startupError;

  ThemeData _theme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3949AB),
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: settings.themeMode,
          locale: const Locale('tr'),
          supportedLocales: const [Locale('tr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => startupError == null
              ? child!
              : Column(
                  children: [
                    Expanded(child: child!),
                    Material(
                      color: Colors.orange.shade200,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Ayarlar kaydedilemiyor: $startupError',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          home: settings.disclaimerAccepted
              ? const HomeScreen()
              : const DisclaimerScreen(),
        ),
      ),
    );
  }
}
