import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tek bir dalga bileşeni: Gauss eğrisi (merkez saniye, genlik mV, genişlik).
class _G {
  const _G(this.center, this.amp, this.sigma);

  final double center;
  final double amp;
  final double sigma;

  double at(double t) {
    final x = (t - center) / sigma;
    if (x.abs() > 5) return 0;
    return amp * math.exp(-0.5 * x * x);
  }
}

/// Bir atımın R tepesine göre bileşenleri.
const _narrow = [
  _G(-0.03, -0.10, 0.008), // Q
  _G(0, 1.0, 0.012), // R
  _G(0.03, -0.25, 0.010), // S
  _G(0.30, 0.30, 0.050), // T
];

const _wide = [
  _G(0, 1.0, 0.040),
  _G(0.10, -0.45, 0.040),
  _G(0.36, -0.35, 0.070),
];

const _stemi = [
  _G(-0.03, -0.10, 0.008),
  _G(0, 1.0, 0.012),
  _G(0.025, -0.05, 0.008),
  _G(0.09, 0.42, 0.040), // yükselmiş ST
  _G(0.17, 0.45, 0.050),
  _G(0.27, 0.40, 0.060),
];

const _p = _G(0, 0.15, 0.025);

/// Sentetik EKG üreticisi: olaylardan (P, QRS) gerilim eğrisi oluşturur.
class EcgSignal {
  EcgSignal._(this._components, {this.baseline});

  final List<_G> _components;

  /// Atım dışı taban çizgisi (fibrilasyon dalgaları gibi).
  final double Function(double t)? baseline;

  double at(double t) {
    var v = baseline?.call(t) ?? 0;
    for (final c in _components) {
      v += c.at(t);
    }
    return v;
  }

  static List<_G> _beat(double r, List<_G> shape, {double? pBefore}) => [
    if (pBefore != null) _G(r - pBefore, _p.amp, _p.sigma),
    for (final c in shape) _G(r + c.center, c.amp, c.sigma),
  ];

  static List<double> _regular(
    double rate,
    double seconds, {
    double start = 0.3,
  }) => [for (var t = start; t < seconds + 1; t += 60 / rate) t];

  /// Sinüs ritmi; [pr] PR aralığı (sn).
  factory EcgSignal.sinus(
    double rate, {
    double pr = 0.16,
    bool stemi = false,
  }) => EcgSignal._([
    for (final r in _regular(rate, 8))
      ..._beat(r, stemi ? _stemi : _narrow, pBefore: pr - 0.04),
  ]);

  factory EcgSignal.atrialFib({int seed = 3}) {
    final rnd = math.Random(seed);
    final beats = <double>[];
    for (var t = 0.25; t < 9; t += 0.42 + rnd.nextDouble() * 0.5) {
      beats.add(t);
    }
    return EcgSignal._(
      [for (final r in beats) ..._beat(r, _narrow)],
      baseline: (t) =>
          0.05 * math.sin(2 * math.pi * 6.3 * t) +
          0.035 * math.sin(2 * math.pi * 8.7 * t + 1.3) +
          0.025 * math.sin(2 * math.pi * 4.9 * t + 0.4),
    );
  }

  /// Atriyal flutter, [ratio]:1 iletim (testere dişi F dalgaları 300/dk).
  factory EcgSignal.flutter({int ratio = 4}) => EcgSignal._(
    [
      for (final r in _regular(300 / ratio, 8, start: 0.36))
        for (final c in _narrow.take(3)) _G(r + c.center, c.amp, c.sigma),
    ],
    baseline: (t) {
      final ph = (t / 0.2) % 1;
      return -0.18 * (ph < 0.75 ? ph / 0.75 : (1 - ph) / 0.25) + 0.09;
    },
  );

  factory EcgSignal.svt() => EcgSignal._([
    for (final r in _regular(180, 8))
      for (final c in _narrow)
        c == _narrow.last
            ? _G(r + 0.20, 0.25, 0.04)
            : _G(r + c.center, c.amp, c.sigma),
  ]);

  factory EcgSignal.vt() => EcgSignal._([
    for (final r in _regular(170, 8))
      ..._beat(r, const [
        _G(0, 1.1, 0.045),
        _G(0.12, -0.55, 0.045),
        _G(0.25, -0.15, 0.05),
      ]),
  ]);

  factory EcgSignal.torsades() => EcgSignal._(
    const [],
    baseline: (t) {
      final env = 0.25 + 0.75 * math.sin(math.pi * t / 2.2).abs();
      return env * math.sin(2 * math.pi * 3.6 * t);
    },
  );

  factory EcgSignal.vf() => EcgSignal._(
    const [],
    baseline: (t) =>
        0.32 * math.sin(2 * math.pi * 5.1 * t) +
        0.22 * math.sin(2 * math.pi * 6.7 * t + 1.1) +
        0.15 *
            math.sin(2 * math.pi * 3.9 * t + 2.3) *
            math.sin(2 * math.pi * 0.4 * t),
  );

  factory EcgSignal.asystole() => EcgSignal._(
    const [],
    baseline: (t) =>
        0.02 * math.sin(2 * math.pi * 0.3 * t) +
        0.01 * math.sin(2 * math.pi * 1.7 * t),
  );

  /// 2. derece Mobitz I: PR uzar, sonra bir P iletilmez.
  factory EcgSignal.wenckebach() {
    final comps = <_G>[];
    const pp = 0.8;
    const prs = [0.16, 0.26, 0.34, null];
    for (var i = 0; i * pp < 9; i++) {
      final p = 0.2 + i * pp;
      comps.add(_G(p, _p.amp, _p.sigma));
      final pr = prs[i % prs.length];
      if (pr != null) {
        for (final c in _narrow) {
          comps.add(_G(p + pr + 0.04 + c.center, c.amp, c.sigma));
        }
      }
    }
    return EcgSignal._(comps);
  }

  /// 2. derece Mobitz II: PR sabit, bazı P'ler iletilmez.
  factory EcgSignal.mobitz2() {
    final comps = <_G>[];
    const pp = 0.75;
    for (var i = 0; i * pp < 9; i++) {
      final p = 0.2 + i * pp;
      comps.add(_G(p, _p.amp, _p.sigma));
      if (i % 3 != 2) {
        for (final c in _narrow) {
          comps.add(_G(p + 0.2 + c.center, c.amp, c.sigma));
        }
      }
    }
    return EcgSignal._(comps);
  }

  /// 3. derece (tam) AV blok: P ve QRS birbirinden bağımsız.
  factory EcgSignal.completeBlock() => EcgSignal._([
    for (final p in _regular(90, 8, start: 0.1)) _G(p, _p.amp, _p.sigma),
    for (final r in _regular(38, 8, start: 0.7)) ..._beat(r, _wide),
  ]);

  /// Sinüs ritmi arasında erken, geniş ventriküler ekstrasistoller.
  factory EcgSignal.pvc() {
    final comps = <_G>[];
    var t = 0.3;
    for (var i = 0; t < 9; i++) {
      if (i % 4 == 3) {
        comps.addAll(_beat(t - 0.3, _wide));
        t += 0.8 + 0.45; // tam kompansatuvar duraklama
      } else {
        comps.addAll(_beat(t, _narrow, pBefore: 0.12));
        t += 0.8;
      }
    }
    return EcgSignal._(comps);
  }
}

/// EKG kâğıdı üzerinde ritim şeridi (25 mm/sn, 10 mm/mV).
class EcgStripPainter extends CustomPainter {
  EcgStripPainter(
    this.signal, {
    this.seconds = 6,
    this.start = 0,
    this.dark = false,
  });

  final EcgSignal signal;
  final double seconds;

  /// Şeridin sol kenarına denk gelen an (sn).
  final double start;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final pxPerSec = size.width / seconds;
    final mm = pxPerSec / 25; // 1 mm küçük kare
    final bg = dark ? const Color(0xFF1B1F24) : const Color(0xFFFFF7F7);
    final minor = dark ? const Color(0xFF3A2A2E) : const Color(0xFFF8C9CF);
    final major = dark ? const Color(0xFF6B3A44) : const Color(0xFFEE8C99);
    final trace = dark ? const Color(0xFF7CFC9A) : const Color(0xFF1A1A1A);

    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final minorP = Paint()
      ..color = minor
      ..strokeWidth = 0.5;
    final majorP = Paint()
      ..color = major
      ..strokeWidth = 1;
    var i = 0;
    for (var x = 0.0; x <= size.width + 0.1; x += mm, i++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 5 == 0 ? majorP : minorP,
      );
    }
    i = 0;
    final mid = size.height * 0.6;
    // Yatay çizgileri taban çizgisinden yukarı ve aşağı hizala.
    for (var y = mid % (mm * 5); y <= size.height; y += mm, i++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 5 == 0 ? majorP : minorP,
      );
    }

    final path = Path();
    final n = (size.width).ceil() * 2;
    for (var k = 0; k <= n; k++) {
      final x = size.width * k / n;
      final t = start + x / pxPerSec;
      final y = mid - signal.at(t) * 10 * mm;
      if (k == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = trace,
    );
  }

  @override
  bool shouldRepaint(EcgStripPainter old) =>
      old.signal != signal ||
      old.dark != dark ||
      old.seconds != seconds ||
      old.start != start;
}

/// Hazır EKG şeridi kutusu.
class EcgStrip extends StatelessWidget {
  const EcgStrip(this.signal, {super.key, this.seconds = 6, this.height = 110});

  final EcgSignal signal;
  final double seconds;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(
      painter: EcgStripPainter(
        signal,
        seconds: seconds,
        dark: Theme.of(context).brightness == Brightness.dark,
      ),
    ),
  );
}
