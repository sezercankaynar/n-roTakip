import 'dart:typed_data';
import 'dart:ui';

import 'vascular_data.dart';

/// Haritaların çizim alanı (mantıksal birim). Ekrana ölçeklenerek çizilir.
const axialSize = Size(300, 340);
const willisSize = Size(300, 380);

/// Görüntüler BT'deki gibi radyolojik düzendedir: ekranın solu hastanın
/// sağıdır. Bölgeler önce ekranın sağ yarısı (hastanın solu) için çizilir,
/// sonra aynalanır.
Float64List _mirror(double width) => Float64List.fromList([
  -1, 0, 0, 0, //
  0, 1, 0, 0, //
  0, 0, 1, 0, //
  width, 0, 0, 1, //
]);

Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);

class AxialRegion {
  const AxialRegion(this.vessel, this.side, this.path, this.labelAt);

  final Vessel vessel;
  final Side side;
  final Path path;

  /// Etiket konumu; `null` ise bölgeye etiket yazılmaz.
  final Offset? labelAt;
}

/// Bazal ganglion düzeyinde yatay beyin kesiti.
class AxialMap {
  AxialMap._(this.regions, this.outline, this.ventricles);

  /// Dokunma önceliğine göre sıralı (küçük derin bölgeler önce).
  final List<AxialRegion> regions;
  final Path outline;

  /// Yalnızca yön bulmak için çizilen yan ventriküller (dokunulmaz).
  final Path ventricles;

  factory AxialMap.build() {
    const w = 300.0;
    final outline = Path()..addOval(const Rect.fromLTRB(30, 12, 270, 328));
    final half = Path.combine(
      PathOperation.intersect,
      outline,
      Path()..addRect(const Rect.fromLTRB(w / 2 + 2, 0, w, 340)),
    );
    Path clip(Path p) => Path.combine(PathOperation.intersect, half, p);

    final aca = clip(
      _polygon(const [
        Offset(150, 8),
        Offset(214, 24),
        Offset(206, 92),
        Offset(184, 148),
        Offset(162, 182),
        Offset(150, 186),
      ]),
    );
    final pca = clip(
      _polygon(const [
        Offset(150, 236),
        Offset(170, 226),
        Offset(210, 248),
        Offset(252, 288),
        Offset(252, 340),
        Offset(150, 340),
      ]),
    );
    final thalamus = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(167, 206), width: 24, height: 34),
      );
    final deep = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(191, 168), width: 26, height: 52),
      );
    var mca = half;
    for (final p in [aca, pca, thalamus, deep]) {
      mca = Path.combine(PathOperation.difference, mca, p);
    }
    final ventricle = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(161, 150), width: 14, height: 58),
      );

    final m = _mirror(w);
    final regions = <AxialRegion>[];
    final shapes = <(Vessel, Path, Offset?)>[
      (Vessel.thalamus, thalamus, null),
      (Vessel.lenticulostriate, deep, null),
      (Vessel.aca, aca, const Offset(178, 70)),
      (Vessel.pca, pca, const Offset(200, 296)),
      (Vessel.mca, mca, const Offset(234, 172)),
    ];
    for (final (vessel, path, label) in shapes) {
      regions.add(AxialRegion(vessel, Side.left, path, label));
      regions.add(
        AxialRegion(
          vessel,
          Side.right,
          path.transform(m),
          label == null ? null : Offset(w - label.dx, label.dy),
        ),
      );
    }
    return AxialMap._(
      regions,
      outline,
      Path()
        ..addPath(ventricle, Offset.zero)
        ..addPath(ventricle.transform(m), Offset.zero),
    );
  }

  AxialRegion? hitTest(Offset p) {
    for (final r in regions) {
      if (r.path.contains(p)) return r;
    }
    return null;
  }
}

class WillisSegment {
  const WillisSegment(this.vessel, this.side, this.a, this.b);

  final Vessel vessel;

  /// Orta hattaki damarlarda `null`.
  final Side? side;
  final Offset a;
  final Offset b;

  double distanceTo(Offset p) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final t = len2 == 0
        ? 0.0
        : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }
}

class WillisLabel {
  const WillisLabel(this.text, this.at, this.vessel);

  final String text;
  final Offset at;
  final Vessel vessel;
}

/// Willis poligonu ve arka dolaşımın şematik çizimi (alttan görünüm,
/// ön taraf yukarıda).
class WillisMap {
  WillisMap._(this.segments, this.labels);

  final List<WillisSegment> segments;
  final List<WillisLabel> labels;

  /// ICA kesit noktaları (daire olarak çizilir).
  static const icaPoints = [Offset(185, 150), Offset(115, 150)];

  factory WillisMap.build() {
    const w = 300.0;
    // Ekranın sağ yarısı (hastanın solu) için damar parçaları.
    const sided = <(Vessel, Offset, Offset)>[
      (Vessel.ica, Offset(185, 150), Offset(210, 180)),
      (Vessel.a1a2, Offset(185, 150), Offset(163, 112)),
      (Vessel.a1a2, Offset(163, 112), Offset(163, 36)),
      (Vessel.m1, Offset(185, 150), Offset(240, 150)),
      (Vessel.m2, Offset(240, 150), Offset(272, 116)),
      (Vessel.m2, Offset(240, 150), Offset(272, 184)),
      (Vessel.pcomm, Offset(185, 150), Offset(185, 212)),
      (Vessel.p1p2, Offset(150, 222), Offset(185, 212)),
      (Vessel.p1p2, Offset(185, 212), Offset(242, 246)),
      (Vessel.sca, Offset(150, 232), Offset(198, 242)),
      (Vessel.aica, Offset(150, 278), Offset(200, 286)),
      (Vessel.vertebral, Offset(150, 300), Offset(172, 370)),
      (Vessel.pica, Offset(164, 336), Offset(208, 350)),
    ];
    const sidedLabels = <(String, Offset, Vessel)>[
      ('ICA', Offset(226, 184), Vessel.ica),
      ('A1', Offset(181, 124), Vessel.a1a2),
      ('A2', Offset(172, 60), Vessel.a1a2),
      ('M1', Offset(212, 140), Vessel.m1),
      ('M2', Offset(262, 100), Vessel.m2),
      ('PComm', Offset(203, 200), Vessel.pcomm),
      ('P1', Offset(166, 208), Vessel.p1p2),
      ('P2', Offset(232, 228), Vessel.p1p2),
      ('SCA', Offset(206, 248), Vessel.sca),
      ('AICA', Offset(208, 292), Vessel.aica),
      ('Vertebral', Offset(200, 372), Vessel.vertebral),
      ('PICA', Offset(214, 356), Vessel.pica),
    ];

    Offset mirror(Offset o) => Offset(w - o.dx, o.dy);
    final segments = <WillisSegment>[
      const WillisSegment(
        Vessel.acomm,
        null,
        Offset(137, 112),
        Offset(163, 112),
      ),
      const WillisSegment(
        Vessel.basilar,
        null,
        Offset(150, 222),
        Offset(150, 300),
      ),
      for (final (v, a, b) in sided) ...[
        WillisSegment(v, Side.left, a, b),
        WillisSegment(v, Side.right, mirror(a), mirror(b)),
      ],
    ];
    final labels = <WillisLabel>[
      const WillisLabel('AComm', Offset(150, 100), Vessel.acomm),
      const WillisLabel('Baziler', Offset(174, 264), Vessel.basilar),
      for (final (t, at, v) in sidedLabels) ...[
        WillisLabel(t, at, v),
        WillisLabel(t, mirror(at), v),
      ],
    ];
    return WillisMap._(segments, labels);
  }

  /// [p] noktasına [tolerance] içinde en yakın damar parçası.
  WillisSegment? hitTest(Offset p, {double tolerance = 14}) {
    WillisSegment? best;
    var bestD = double.infinity;
    for (final s in segments) {
      final d = s.distanceTo(p);
      if (d < bestD) {
        best = s;
        bestD = d;
      }
    }
    if (best != null && bestD <= tolerance) return best;
    return null;
  }
}
