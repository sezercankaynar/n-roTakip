import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_settings.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/root_shell.dart';
import 'theme.dart';

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
        .then((s) {
          // Sanal telefon testi (CI) bu satırı logcat'te arar.
          debugPrint('NOROCEP_READY');
          setState(() => _settings = s);
        })
        .catchError((Object e) {
          debugPrint('NOROCEP_SETTINGS_ERROR: $e');
          setState(() {
            _error = e;
            _settings = AppSettings.inMemory();
          });
        });
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

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: settings.themeMode,
          locale: const Locale('tr'),
          supportedLocales: const [Locale('tr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) {
            // Kullanıcının seçtiği yazı boyutu telefon ayarının üstüne eklenir.
            final mq = MediaQuery.of(context);
            child = MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(
                  mq.textScaler.scale(10) / 10 * settings.textScale,
                ),
              ),
              child: child!,
            );
            return startupError == null
                ? child
                : Column(
                    children: [
                      Expanded(child: child),
                      Material(
                        color: Colors.orange.shade200,
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Ayarlar kaydedilemiyor; tema ve onay seçimi '
                              'hatırlanmayacak. ($startupError)',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
          },
          home: settings.disclaimerAccepted
              ? const RootShell()
              : const DisclaimerScreen(),
        ),
      ),
    );
  }
}
