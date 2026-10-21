import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'vascular_data.dart';

/// Haritaların çizim alanı (mantıksal birim). Ekrana ölçeklenerek çizilir.
const axialSize = Size(300, 340);
const willisSize = Size(300, 380);

/// Görüntüler BT'deki gibi radyolojik düzendedir: ekranın solu hastanın
/// sağıdır. Yapılar önce ekranın sağ yarısı (hastanın solu) için çizilir,
/// sonra aynalanır.
Float64List _mirror(double width) => Float64List.fromList([
  -1, 0, 0, 0, //
  0, 1, 0, 0, //
  0, 0, 1, 0, //
  width, 0, 0, 1, //
]);

/// Noktalardan geçen yumuşak, kapalı eğri (Catmull-Rom).
Path _smoothClosed(List<Offset> p) {
  final path = Path()..moveTo(p[0].dx, p[0].dy);
  final n = p.length;
  for (var i = 0; i < n; i++) {
    final p0 = p[(i - 1 + n) % n], p1 = p[i];
    final p2 = p[(i + 1) % n], p3 = p[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path..close();
}

/// Noktalardan geçen yumuşak, açık eğri.
Path _smoothOpen(List<Offset> p) {
  final path = Path()..moveTo(p[0].dx, p[0].dy);
  for (var i = 0; i < p.length - 1; i++) {
    final p0 = p[math.max(i - 1, 0)], p1 = p[i];
    final p2 = p[i + 1], p3 = p[math.min(i + 2, p.length - 1)];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}

Offset _mirrorPoint(Offset o, double w) => Offset(w - o.dx, o.dy);

class AxialRegion {
  const AxialRegion(this.vessel, this.side, this.path, this.labelAt);

  final Vessel vessel;
  final Side side;
  final Path path;

  /// Etiket konumu; `null` ise bölgeye etiket yazılmaz.
  final Offset? labelAt;
}

/// Beyin kesitindeki anatomik yapılar (yalnızca çizim için).
class AxialAnatomy {
  const AxialAnatomy({
    required this.skull,
    required this.brain,
    required this.whiteMatter,
    required this.sulci,
    required this.fissures,
    required this.ventricles,
    required this.deepGrey,
    required this.labels,
  });

  final Path skull;
  final Path brain;
  final Path whiteMatter;

  /// Korteks olukları (açık çizgiler).
  final Path sulci;

  /// Hemisferler arası ve Sylvius yarıkları.
  final Path fissures;
  final Path ventricles;

  /// Kaudat, lentiform çekirdek ve talamus.
  final Path deepGrey;

  /// Bölgeler kapalıyken gösterilen yapı adları.
  final List<(String, Offset)> labels;
}

/// Bazal ganglion ve talamus düzeyinde yatay beyin kesiti.
class AxialMap {
  AxialMap._(this.regions, this.anatomy);

  /// Dokunma önceliğine göre sıralı (küçük derin bölgeler önce).
  final List<AxialRegion> regions;
  final AxialAnatomy anatomy;

  factory AxialMap.build() {
    const w = 300.0;
    const c = Offset(150, 170);
    final m = _mirror(w);

    // Korteks: kenarı kıvrımlı (giruslar) bir elips.
    List<Offset> ring(double rx, double ry, double bump, int n) => [
      for (var i = 0; i < n; i++)
        () {
          final t = 2 * math.pi * i / n;
          final r =
              1 + bump * math.sin(t * 23) + bump * 0.5 * math.sin(t * 41 + 1.3);
          return c + Offset(rx * r * math.cos(t), ry * r * math.sin(t));
        }(),
    ];
    final brain = _smoothClosed(ring(114, 150, 0.022, 180));
    final whiteMatter = _smoothClosed(ring(92, 126, 0.03, 90));
    final skull = Path()
      ..addOval(Rect.fromCenter(center: c, width: 252, height: 326))
      ..addOval(Rect.fromCenter(center: c, width: 240, height: 314))
      ..fillType = PathFillType.evenOdd;

    // Oluklar: kenardan içe doğru kısa, hafif kıvrık çizgiler.
    final sulci = Path();
    final rnd = math.Random(7);
    for (var i = 0; i < 64; i++) {
      final t = 2 * math.pi * i / 64 + rnd.nextDouble() * 0.05;
      final dir = Offset(math.cos(t), math.sin(t));
      final edge = c + Offset(dir.dx * 113, dir.dy * 149);
      final len = 10 + rnd.nextDouble() * 12;
      final inner = edge - Offset(dir.dx * len, dir.dy * len * 1.1);
      final bend = Offset(-dir.dy, dir.dx) * (rnd.nextDouble() * 6 - 3);
      sulci
        ..moveTo(edge.dx, edge.dy)
        ..quadraticBezierTo(
          (edge.dx + inner.dx) / 2 + bend.dx,
          (edge.dy + inner.dy) / 2 + bend.dy,
          inner.dx,
          inner.dy,
        );
    }

    // Ekranın sağ yarısı (hastanın solu) için yapılar.
    final sylvian = _smoothOpen(const [
      Offset(262, 172),
      Offset(240, 168),
      Offset(222, 160),
      Offset(214, 150),
    ]);
    final frontalHorn = _smoothClosed(const [
      Offset(152, 112),
      Offset(166, 116),
      Offset(172, 136),
      Offset(166, 160),
      Offset(156, 172),
      Offset(152, 168),
    ]);
    final atrium = _smoothClosed(const [
      Offset(162, 222),
      Offset(176, 230),
      Offset(184, 252),
      Offset(176, 258),
      Offset(166, 240),
    ]);
    final caudate = _smoothClosed(const [
      Offset(170, 118),
      Offset(184, 126),
      Offset(186, 146),
      Offset(176, 158),
      Offset(170, 140),
    ]);
    final lentiform = _smoothClosed(const [
      Offset(198, 132),
      Offset(214, 146),
      Offset(216, 172),
      Offset(204, 192),
      Offset(190, 176),
      Offset(192, 150),
    ]);
    final thalamus = _smoothClosed(const [
      Offset(154, 180),
      Offset(170, 176),
      Offset(182, 194),
      Offset(178, 216),
      Offset(162, 220),
      Offset(154, 206),
    ]);

    Path both(Path p) => Path()
      ..addPath(p, Offset.zero)
      ..addPath(p.transform(m), Offset.zero);

    final ventricles = both(frontalHorn)
      ..addPath(both(atrium), Offset.zero)
      ..addRect(const Rect.fromLTRB(148.5, 182, 151.5, 212));
    final fissures = both(sylvian)
      ..moveTo(150, 20)
      ..lineTo(150, 108)
      ..moveTo(150, 236)
      ..lineTo(150, 320);
    final deepGrey = both(caudate)
      ..addPath(both(lentiform), Offset.zero)
      ..addPath(both(thalamus), Offset.zero);

    // Damar bölgeleri (hastanın solu).
    final half = Path.combine(
      PathOperation.intersect,
      brain,
      Path()..addRect(const Rect.fromLTRB(w / 2 + 1, 0, w, 340)),
    );
    Path clip(Path p) => Path.combine(PathOperation.intersect, half, p);
    final aca = clip(
      _smoothClosed(const [
        Offset(151, 6),
        Offset(196, 14),
        Offset(214, 30),
        Offset(204, 70),
        Offset(186, 104),
        Offset(170, 112),
        Offset(151, 108),
      ]),
    );
    final pca = clip(
      _smoothClosed(const [
        Offset(151, 230),
        Offset(182, 226),
        Offset(214, 244),
        Offset(244, 272),
        Offset(240, 320),
        Offset(180, 336),
        Offset(151, 336),
      ]),
    );
    final deep = _smoothClosed(const [
      Offset(170, 120),
      Offset(198, 128),
      Offset(218, 148),
      Offset(218, 176),
      Offset(204, 196),
      Offset(184, 184),
      Offset(172, 162),
    ]);
    var mca = half;
    for (final p in [aca, pca, thalamus, deep]) {
      mca = Path.combine(PathOperation.difference, mca, p);
    }

    final regions = <AxialRegion>[];
    final shapes = <(Vessel, Path, Offset?)>[
      (Vessel.thalamus, thalamus, null),
      (Vessel.lenticulostriate, deep, null),
      (Vessel.aca, aca, const Offset(176, 60)),
      (Vessel.pca, pca, const Offset(200, 300)),
      (Vessel.mca, mca, const Offset(236, 214)),
    ];
    for (final (vessel, path, label) in shapes) {
      regions.add(AxialRegion(vessel, Side.left, path, label));
      regions.add(
        AxialRegion(
          vessel,
          Side.right,
          path.transform(m),
          label == null ? null : _mirrorPoint(label, w),
        ),
      );
    }

    return AxialMap._(
      regions,
      AxialAnatomy(
        skull: skull,
        brain: brain,
        whiteMatter: whiteMatter,
        sulci: sulci,
        fissures: fissures,
        ventricles: ventricles,
        deepGrey: deepGrey,
        labels: const [
          ('Lateral ventrikül', Offset(150, 96)),
          ('Kaudat', Offset(232, 116)),
          ('Lentiform\nçekirdek', Offset(240, 146)),
          ('Talamus', Offset(206, 222)),
          ('Sylvius\nyarığı', Offset(246, 192)),
        ],
      ),
    );
  }

  AxialRegion? hitTest(Offset p) {
    for (final r in regions) {
      if (r.path.contains(p)) return r;
    }
    return null;
  }
}

/// Willis poligonundaki bir damar parçası.
class WillisVessel {
  WillisVessel(this.vessel, this.side, this.path, this.width)
    : samples = _sample(path);

  final Vessel vessel;

  /// Orta hattaki damarlarda `null`.
  final Side? side;
  final Path path;

  /// Çizim kalınlığı (mantıksal birim).
  final double width;

  /// Dokunma testi için eğri üzerinden alınmış noktalar.
  final List<Offset> samples;

  static List<Offset> _sample(Path path) => [
    for (final metric in path.computeMetrics())
      for (var d = 0.0; d <= metric.length; d += 2)
        metric.getTangentForOffset(d)!.position,
  ];

  double distanceTo(Offset p) =>
      samples.fold(double.infinity, (m, s) => math.min(m, (s - p).distance));
}

class WillisLabel {
  const WillisLabel(this.text, this.at);

  final String text;
  final Offset at;
}

/// Beyin tabanının alttan görünümü: Willis poligonu ve arka dolaşım
/// (ön taraf yukarıda).
class WillisMap {
  WillisMap._(this.vessels, this.labels, this.anatomy, this.nerves);

  final List<WillisVessel> vessels;
  final List<WillisLabel> labels;

  /// Beyin tabanı yapıları: (yol, açıklık 0–1) çiftleri, çizim sırasıyla.
  final List<(Path, double)> anatomy;

  /// Optik sinirler ve 3. kraniyal sinir (yalnızca çizim).
  final Path nerves;

  /// ICA kesit noktaları (daire olarak çizilir).
  static const icaPoints = [Offset(176, 150), Offset(124, 150)];

  factory WillisMap.build() {
    const w = 300.0;
    final m = _mirror(w);
    Path both(Path p) => Path()
      ..addPath(p, Offset.zero)
      ..addPath(p.transform(m), Offset.zero);

    // Beyin tabanı (hastanın solu, sonra aynalanır).
    final frontal = _smoothClosed(const [
      Offset(152, 14),
      Offset(200, 10),
      Offset(248, 34),
      Offset(270, 84),
      Offset(262, 130),
      Offset(222, 140),
      Offset(176, 128),
      Offset(152, 110),
    ]);
    final temporal = _smoothClosed(const [
      Offset(206, 158),
      Offset(248, 146),
      Offset(280, 176),
      Offset(286, 232),
      Offset(270, 280),
      Offset(232, 290),
      Offset(204, 262),
      Offset(196, 210),
    ]);
    final cerebellum = _smoothClosed(const [
      Offset(162, 292),
      Offset(206, 280),
      Offset(252, 296),
      Offset(270, 330),
      Offset(242, 366),
      Offset(192, 372),
      Offset(158, 352),
    ]);
    final pons = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(150, 248), width: 76, height: 72),
      );
    final medulla = _smoothClosed(const [
      Offset(130, 278),
      Offset(170, 278),
      Offset(164, 340),
      Offset(160, 376),
      Offset(140, 376),
      Offset(136, 340),
    ]);
    final midbrain = _smoothClosed(const [
      Offset(124, 196),
      Offset(176, 196),
      Offset(182, 218),
      Offset(118, 218),
    ]);
    final chiasm = Path()
      ..addPolygon(const [
        Offset(134, 128),
        Offset(166, 128),
        Offset(160, 140),
        Offset(140, 140),
      ], true);
    final mammillary = Path()
      ..addOval(Rect.fromCircle(center: const Offset(144, 186), radius: 5))
      ..addOval(Rect.fromCircle(center: const Offset(156, 186), radius: 5));
    final stalk = Path()
      ..addOval(Rect.fromCircle(center: const Offset(150, 152), radius: 6));

    final nerves =
        both(
            _smoothOpen(const [
              Offset(162, 130),
              Offset(172, 108),
              Offset(184, 90),
            ]),
          )
          ..addPath(
            both(
              _smoothOpen(const [
                Offset(160, 140),
                Offset(178, 162),
                Offset(196, 176),
              ]),
            ),
            Offset.zero,
          )
          // 3. kraniyal sinir: PCA ile SCA arasından çıkar.
          ..addPath(
            both(
              _smoothOpen(const [
                Offset(158, 214),
                Offset(170, 196),
                Offset(184, 172),
              ]),
            ),
            Offset.zero,
          );

    final anatomy = <(Path, double)>[
      (both(cerebellum), 0.55),
      (both(temporal), 0.72),
      (both(frontal), 0.72),
      (medulla, 0.62),
      (pons, 0.66),
      (midbrain, 0.6),
      (chiasm, 0.82),
      (mammillary, 0.7),
      (stalk, 0.78),
    ];

    // Damarlar (hastanın solu).
    const sided = <(Vessel, List<Offset>, double)>[
      (Vessel.ica, [Offset(176, 150), Offset(186, 164), Offset(192, 182)], 8),
      (Vessel.a1a2, [Offset(176, 150), Offset(166, 132), Offset(157, 120)], 5),
      (
        Vessel.a1a2,
        [Offset(157, 120), Offset(158, 90), Offset(156, 50), Offset(154, 18)],
        5,
      ),
      (
        Vessel.m1,
        [
          Offset(176, 150),
          Offset(198, 148),
          Offset(222, 146),
          Offset(238, 144),
        ],
        7,
      ),
      (
        Vessel.m2,
        [Offset(238, 144), Offset(252, 128), Offset(266, 112), Offset(274, 96)],
        5,
      ),
      (
        Vessel.m2,
        [
          Offset(238, 144),
          Offset(254, 158),
          Offset(268, 176),
          Offset(276, 196),
        ],
        5,
      ),
      (Vessel.pcomm, [Offset(176, 152), Offset(180, 176), Offset(174, 202)], 3),
      (Vessel.p1p2, [Offset(150, 208), Offset(162, 204), Offset(174, 202)], 5),
      (
        Vessel.p1p2,
        [
          Offset(174, 202),
          Offset(196, 208),
          Offset(222, 226),
          Offset(244, 250),
        ],
        5,
      ),
      (
        Vessel.sca,
        [
          Offset(150, 216),
          Offset(170, 218),
          Offset(196, 228),
          Offset(220, 246),
        ],
        3.5,
      ),
      (
        Vessel.aica,
        [
          Offset(150, 262),
          Offset(172, 266),
          Offset(196, 276),
          Offset(214, 290),
        ],
        3,
      ),
      (
        Vessel.vertebral,
        [
          Offset(150, 282),
          Offset(158, 300),
          Offset(166, 330),
          Offset(170, 370),
        ],
        6,
      ),
      (
        Vessel.pica,
        [
          Offset(166, 330),
          Offset(184, 322),
          Offset(206, 330),
          Offset(222, 346),
        ],
        3,
      ),
    ];

    final vessels = <WillisVessel>[
      WillisVessel(
        Vessel.acomm,
        null,
        Path()
          ..moveTo(143, 120)
          ..lineTo(157, 120),
        4,
      ),
      WillisVessel(
        Vessel.basilar,
        null,
        _smoothOpen(const [
          Offset(150, 208),
          Offset(151, 246),
          Offset(150, 282),
        ]),
        8,
      ),
      for (final (v, pts, width) in sided) ...[
        WillisVessel(v, Side.left, _smoothOpen(pts), width),
        WillisVessel(
          v,
          Side.right,
          _smoothOpen([for (final p in pts) _mirrorPoint(p, w)]),
          width,
        ),
      ],
    ];

    const sidedLabels = <(String, Offset)>[
      ('ICA', Offset(214, 194)),
      ('A1', Offset(178, 124)),
      ('A2', Offset(172, 62)),
      ('M1', Offset(212, 136)),
      ('M2', Offset(282, 84)),
      ('PComm', Offset(206, 168)),
      ('P1', Offset(166, 194)),
      ('P2', Offset(236, 232)),
      ('SCA', Offset(214, 258)),
      ('AICA', Offset(224, 298)),
      ('Vertebral', Offset(198, 372)),
      ('PICA', Offset(236, 354)),
    ];
    final labels = <WillisLabel>[
      const WillisLabel('AComm', Offset(150, 108)),
      const WillisLabel('Baziler', Offset(174, 268)),
      for (final (t, at) in sidedLabels) ...[
        WillisLabel(t, at),
        WillisLabel(t, _mirrorPoint(at, w)),
      ],
    ];
    return WillisMap._(vessels, labels, anatomy, nerves);
  }

  /// [p] noktasına [tolerance] içinde en yakın damar.
  WillisVessel? hitTest(Offset p, {double tolerance = 12}) {
    WillisVessel? best;
    var bestD = double.infinity;
    for (final v in vessels) {
      final d = v.distanceTo(p) - v.width / 2;
      if (d < bestD) {
        best = v;
        bestD = d;
      }
    }
    return bestD <= tolerance ? best : null;
  }
}
