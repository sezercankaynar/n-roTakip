import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/stroke/vascular_data.dart';
import 'package:norocep/features/stroke/vascular_geometry.dart';
import 'package:norocep/features/stroke/vascular_map_screen.dart';

void main() {
  group('beyin kesiti', () {
    final map = AxialMap.build();

    // Ekranın sağ yarısı hastanın solu (radyolojik düzen).
    const cases = <(Offset, Vessel?, Side?)>[
      (Offset(234, 172), Vessel.mca, Side.left),
      (Offset(66, 172), Vessel.mca, Side.right),
      (Offset(178, 70), Vessel.aca, Side.left),
      (Offset(122, 70), Vessel.aca, Side.right),
      (Offset(200, 296), Vessel.pca, Side.left),
      (Offset(167, 206), Vessel.thalamus, Side.left),
      (Offset(109, 168), Vessel.lenticulostriate, Side.right),
      (Offset(5, 5), null, null),
    ];
    for (final (p, vessel, side) in cases) {
      test('$p → $vessel $side', () {
        final hit = map.hitTest(p);
        expect(hit?.vessel, vessel);
        expect(hit?.side, side);
      });
    }

    test('her damar iki tarafta da var', () {
      for (final v in [
        Vessel.aca,
        Vessel.mca,
        Vessel.pca,
        Vessel.thalamus,
        Vessel.lenticulostriate,
      ]) {
        expect(
          map.regions.where((r) => r.vessel == v).map((r) => r.side).toSet(),
          {Side.left, Side.right},
        );
      }
    });
  });

  group('Willis poligonu', () {
    final map = WillisMap.build();
    const cases = <(Offset, Vessel?, Side?)>[
      (Offset(212, 150), Vessel.m1, Side.left),
      (Offset(88, 150), Vessel.m1, Side.right),
      (Offset(150, 112), Vessel.acomm, null),
      (Offset(150, 260), Vessel.basilar, null),
      (Offset(186, 344), Vessel.pica, Side.left),
      (Offset(285, 20), null, null),
    ];
    for (final (p, vessel, side) in cases) {
      test('$p → $vessel $side', () {
        final hit = map.hitTest(p);
        expect(hit?.vessel, vessel);
        expect(hit?.side, side);
      });
    }
  });

  group('taraf metinleri', () {
    test('sol MCA: sağ tarafta güçsüzlük, sola bakış', () {
      final s = Vessel.mca.info.resolvedSymptoms(Side.left);
      expect(s.first, startsWith('Sağ yüz ve kolda'));
      expect(s, contains(startsWith('Gözlerde sola bakış')));
    });

    test('sağ PICA: sağ yüzde, sol gövdede', () {
      final s = Vessel.pica.info.resolvedSymptoms(Side.right);
      expect(s, contains(startsWith('Sağ yüzde, sol gövde')));
    });

    test('taraf seçilmeden: karşı / aynı', () {
      final s = Vessel.pica.info.resolvedSymptoms(null);
      expect(s, contains(startsWith('Aynı yüzde, karşı gövde')));
      for (final v in Vessel.values) {
        for (final side in [null, ...Side.values]) {
          for (final t in v.info.resolvedSymptoms(side)) {
            expect(t, isNot(contains('{')), reason: '$v $side: $t');
          }
        }
      }
    });
  });

  testWidgets('bölgeye dokununca taraflı bilgi açılır', (tester) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: VascularMapScreen()));
    await tester.pumpAndSettle();

    final paint = find.descendant(
      of: find.byType(AspectRatio),
      matching: find.byType(CustomPaint),
    );
    final box = tester.getRect(paint);
    final scale = box.width / axialSize.width;
    await tester.tapAt(box.topLeft + const Offset(234, 172) * scale);
    await tester.pumpAndSettle();

    expect(find.text('Sol MCA tıkanırsa'), findsOneWidget);
    expect(find.textContaining('Sağ yüz ve kolda'), findsOneWidget);
    // Sayfayı yukarı çekip altta kalan bölümleri göster.
    await tester.drag(find.text('Sol MCA tıkanırsa'), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Ek olarak (sol yarıküre)'), findsOneWidget);
    expect(find.text('Ek olarak (sağ yarıküre)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
