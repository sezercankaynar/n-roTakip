import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/app_settings.dart';
import 'package:norocep/features/cpr/cpr_screen.dart';
import 'package:norocep/features/diseases/disease_library_screen.dart';
import 'package:norocep/features/drugs/drug_guide_screen.dart';
import 'package:norocep/features/ecg/ecg_screen.dart';
import 'package:norocep/features/exam/exam_screen.dart';
import 'package:norocep/features/exam/gcs_screen.dart';
import 'package:norocep/features/exam/mrs_screen.dart';
import 'package:norocep/features/exam/pupil_gauge_screen.dart';
import 'package:norocep/features/infusion/infusion_screen.dart';
import 'package:norocep/features/labs/labs_screen.dart';
import 'package:norocep/features/nihss/nihss_screen.dart';
import 'package:norocep/features/nursing/nursing_screen.dart';
import 'package:norocep/features/nursing/pressure_injury_screen.dart';
import 'package:norocep/features/protocols/protocols_screen.dart';
import 'package:norocep/features/shift/shift_screen.dart';
import 'package:norocep/features/stroke/stroke_center_screen.dart';
import 'package:norocep/features/stroke/thrombolytic_dose_screen.dart';
import 'package:norocep/features/stroke/vascular_map_screen.dart';
import 'package:norocep/main.dart';
import 'package:norocep/screens/disclaimer_screen.dart';
import 'package:norocep/screens/root_shell.dart';
import 'package:norocep/screens/scales_screen.dart';
import 'package:norocep/screens/settings_screen.dart';
import 'package:norocep/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ekran boyutu (mantıksal piksel) ve telefonun alt çubuk yüksekliği.
const sizes = <String, (Size, double)>{
  'küçük telefon': (Size(320, 568), 48),
  'yatay telefon': (Size(740, 360), 48),
  'tablet dikey': (Size(800, 1280), 48),
  'tablet yatay': (Size(1280, 800), 48),
};

final screens = <String, Widget Function()>{
  'ana sayfa': () => const RootShell(),
  'açılış uyarısı': () => const DisclaimerScreen(),
  'CPR': () => const CprScreen(),
  'EKG': () => const EcgScreen(),
  'EKG okuma': () => const EcgScreen(initialTab: 1),
  'infüzyon': () => const InfusionScreen(),
  'yükleme dozu': () => const InfusionScreen(initialTab: 1),
  'damla': () => const InfusionScreen(initialTab: 2),
  'laboratuvar': () => const LabsScreen(),
  'ölçekler': () => const ScalesScreen(),
  'NIHSS': () => const NihssScreen(),
  'GKS': () => const GcsScreen(),
  'mRS': () => const MrsScreen(),
  'pupil': () => const PupilGaugeScreen(),
  'muayene': () => const ExamScreen(),
  'inme merkezi': () => const StrokeCenterScreen(),
  'damar haritası': () => const VascularMapScreen(),
  'tPA doz': () => const ThrombolyticDoseScreen(),
  'ilaçlar': () => const DrugGuideScreen(),
  'hastalıklar': () => const DiseaseLibraryScreen(),
  'hemşirelik': () => const NursingScreen(),
  'bası yarası': () => const PressureInjuryScreen(),
  'vardiyam': () => const ShiftScreen(),
  'protokoller': () => const ProtocolsScreen(),
  'ayarlar': () => const SettingsScreen(),
};

void main() {
  for (final MapEntry(key: sizeName, value: (size, navBar)) in sizes.entries) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('$sizeName, yazı ×$scale: hiçbir ekran taşmaz', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final settings = await AppSettings.load();
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        tester.view.padding = FakeViewPadding(bottom: navBar * 2);
        tester.view.viewPadding = FakeViewPadding(bottom: navBar * 2);
        addTearDown(tester.view.reset);

        final failures = <String>[];
        for (final MapEntry(key: name, value: build) in screens.entries) {
          await tester.pumpWidget(
            AppSettingsScope(
              settings: settings,
              child: MaterialApp(
                key: ValueKey(name),
                theme: buildTheme(Brightness.light),
                builder: (context, child) =>
                    AppFrame(textScale: scale, child: child!),
                home: build(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          final e = tester.takeException();
          if (e != null) failures.add('$name: $e');

          // İçerik telefonun alt çubuğunun üstünde kalmalı.
          final scaffold = tester.getRect(find.byType(Scaffold).first);
          if (scaffold.bottom > size.height - navBar + 0.5) {
            failures.add('$name: alt çubuğun altına taşıyor');
          }
        }
        await tester.pumpWidget(const SizedBox());
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  }
}
