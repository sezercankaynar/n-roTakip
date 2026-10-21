import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/content_status.dart';
import 'vascular_data.dart';
import 'vascular_geometry.dart';

const vesselColors = <Vessel, Color>{
  Vessel.aca: Color(0xFF1E88E5),
  Vessel.mca: Color(0xFF43A047),
  Vessel.pca: Color(0xFFFB8C00),
  Vessel.lenticulostriate: Color(0xFF8E24AA),
  Vessel.thalamus: Color(0xFFE53935),
  Vessel.ica: Color(0xFFD81B60),
  Vessel.m1: Color(0xFF43A047),
  Vessel.m2: Color(0xFF7CB342),
  Vessel.a1a2: Color(0xFF1E88E5),
  Vessel.acomm: Color(0xFF00ACC1),
  Vessel.pcomm: Color(0xFF8D6E63),
  Vessel.p1p2: Color(0xFFFB8C00),
  Vessel.basilar: Color(0xFF5E35B1),
  Vessel.vertebral: Color(0xFF3949AB),
  Vessel.pica: Color(0xFF00897B),
  Vessel.aica: Color(0xFFC0CA33),
  Vessel.sca: Color(0xFFF4511E),
};

typedef _Selection = ({Vessel vessel, Side? side});

class VascularMapScreen extends StatelessWidget {
  const VascularMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Beyin Damar Haritası'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Beyin kesiti'),
              Tab(text: 'Willis poligonu'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [_AxialTab(), _WillisTab()],
        ),
      ),
    );
  }
}

void _showInfo(BuildContext context, Vessel vessel, Side? side) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) =>
          VesselInfoView(vessel: vessel, side: side, controller: controller),
    ),
  );
}

/// Bir damarın beslediği alan ve tıkanınca görülen belirtiler.
class VesselInfoView extends StatelessWidget {
  const VesselInfoView({
    super.key,
    required this.vessel,
    required this.side,
    this.controller,
  });

  final Vessel vessel;
  final Side? side;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = vessel.info;
    final color = vesselColors[vessel]!;
    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        t,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
    Widget bullets(Iterable<String> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 14, child: Text('•')),
                Expanded(child: Text(s, style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
      ],
    );

    final showLeft =
        info.leftSymptoms.isNotEmpty && (side == null || side == Side.left);
    final showRight =
        info.rightSymptoms.isNotEmpty && (side == null || side == Side.right);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(info.title(side), style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        heading('Beslediği alan'),
        Text(info.supplies, style: theme.textTheme.bodyLarge),
        heading(
          side == null || info.midline
              ? 'Tıkanırsa görülebilecek belirtiler'
              : '${side!.label} ${info.abbr} tıkanırsa',
        ),
        bullets(info.resolvedSymptoms(side)),
        if (showLeft) ...[
          heading(
            side == null ? 'Sol tarafta ek olarak' : 'Ek olarak (sol yarıküre)',
          ),
          bullets(info.leftSymptoms),
        ],
        if (showRight) ...[
          heading(
            side == null ? 'Sağ tarafta ek olarak' : 'Ek olarak (sağ yarıküre)',
          ),
          bullets(info.rightSymptoms),
        ],
        if (showLeft || showRight) ...[
          const SizedBox(height: 8),
          Text(dominanceNote, style: theme.textTheme.bodySmall),
        ],
        if (info.notes.isNotEmpty) ...[
          heading('Önemli notlar'),
          bullets(info.notes),
        ],
        const SizedBox(height: 16),
        const SourcesCard(status: ReviewStatus.draft, sources: vascularSources),
      ],
    );
  }
}

/// Harita sekmelerinin ortak düzeni: yön etiketleri, dokunulabilir çizim ve
/// renk açıklaması.
class _MapScaffold extends StatelessWidget {
  const _MapScaffold({
    required this.hint,
    required this.size,
    required this.painter,
    required this.onTapLogical,
    required this.legend,
    this.legendColors = true,
    this.extra,
    required this.orientationNote,
  });

  final String hint;
  final Size size;
  final CustomPainter painter;
  final ValueChanged<Offset> onTapLogical;
  final List<Vessel> legend;

  /// Bakış yönünü anlatan kısa açıklama.
  final String orientationNote;

  /// Açıklama düğmelerinde renk noktası gösterilsin mi.
  final bool legendColors;

  /// Haritanın üstünde gösterilen ek denetim (ör. bölgeleri aç/kapat).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.labelMedium;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Text(hint, textAlign: TextAlign.center),
        ?extra,
        const SizedBox(height: 8),
        Center(child: Text('ÖN (alın)', style: small)),
        Row(
          children: [
            const Icon(Icons.arrow_back, size: 14),
            Flexible(child: Text(' Hastanın SAĞI', style: small)),
            const Spacer(),
            Flexible(
              child: Text(
                'Hastanın SOLU ',
                style: small,
                textAlign: TextAlign.end,
              ),
            ),
            const Icon(Icons.arrow_forward, size: 14),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: const Color(0xFF0B0B0B),
            child: AspectRatio(
              aspectRatio: size.width / size.height,
              child: LayoutBuilder(
                builder: (context, c) {
                  final scale = c.maxWidth / size.width;
                  return GestureDetector(
                    onTapUp: (d) => onTapLogical(d.localPosition / scale),
                    child: CustomPaint(size: c.biggest, painter: painter),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(child: Text('ARKA (ense)', style: small)),
        const SizedBox(height: 4),
        Text(
          '$orientationNote Çizimler şematiktir.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final v in legend)
              ActionChip(
                avatar: legendColors
                    ? CircleAvatar(backgroundColor: vesselColors[v])
                    : null,
                label: Text(v.info.abbr),
                onPressed: () => _showInfo(context, v, null),
              ),
          ],
        ),
      ],
    );
  }
}

class _AxialTab extends StatefulWidget {
  const _AxialTab();

  @override
  State<_AxialTab> createState() => _AxialTabState();
}

class _AxialTabState extends State<_AxialTab> {
  final _map = AxialMap.build();
  _Selection? _selected;
  bool _showRegions = true;

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      hint:
          'Bir bölgeye dokunun: o damar tıkanırsa görülecek belirtiler '
          'açılır.',
      size: axialSize,
      orientationNote:
          'BT kesiti gibi, hastaya ayak ucundan bakılıyor: ekranın solu '
          'hastanın sağıdır.',
      painter: _AxialPainter(_map, _selected, showRegions: _showRegions),
      extra: SwitchListTile(
        dense: true,
        value: _showRegions,
        onChanged: (v) => setState(() => _showRegions = v),
        title: const Text('Damar bölgelerini göster'),
        subtitle: const Text('Kapatınca anatomik yapıların adları görünür'),
      ),
      legend: const [
        Vessel.aca,
        Vessel.mca,
        Vessel.pca,
        Vessel.lenticulostriate,
        Vessel.thalamus,
      ],
      onTapLogical: (p) {
        final hit = _map.hitTest(p);
        if (hit == null) return;
        setState(() => _selected = (vessel: hit.vessel, side: hit.side));
        _showInfo(context, hit.vessel, hit.side);
      },
    );
  }
}

/// Kesikli çizgi.
Path _dashed(Path source, {double dash = 5, double gap = 4}) {
  final out = Path();
  for (final metric in source.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += dash + gap) {
      out.addPath(metric.extractPath(d, d + dash), Offset.zero);
    }
  }
  return out;
}

class _AxialPainter extends CustomPainter {
  _AxialPainter(this.map, this.selected, {required this.showRegions});

  final AxialMap map;
  final _Selection? selected;
  final bool showRegions;

  static const _grey = Color(0xFFA2A2A2);
  static const _white = Color(0xFF858585);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / axialSize.width);
    final a = map.anatomy;

    // Kafatası, gri ve beyaz cevher (BT tonlarında).
    canvas.drawPath(a.skull, Paint()..color = const Color(0xFFE6E6E6));
    canvas.drawPath(a.brain, Paint()..color = _grey);
    canvas.drawPath(
      a.whiteMatter,
      Paint()
        ..color = _white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      a.sulci,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF353535),
    );
    canvas.drawPath(
      a.fissures,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF242424),
    );
    canvas.drawPath(a.deepGrey, Paint()..color = _grey);
    canvas.drawPath(
      a.deepGrey,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = const Color(0xFF6A6A6A),
    );

    for (final r in map.regions.reversed) {
      final isSel = selected?.vessel == r.vessel && selected?.side == r.side;
      final color = vesselColors[r.vessel]!;
      if (showRegions || isSel) {
        canvas.drawPath(
          r.path,
          Paint()
            ..color = color.withValues(
              alpha: isSel ? 0.62 : (showRegions ? 0.36 : 0),
            ),
        );
      }
      if (showRegions) {
        canvas.drawPath(
          _dashed(r.path),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = color,
        );
      }
      if (isSel) {
        canvas.drawPath(
          r.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Colors.white,
        );
      }
    }

    // Ventriküller (BOS) bölgelerin üstünde: renklenmez.
    canvas.drawPath(a.ventricles, Paint()..color = const Color(0xFF1E1E1E));

    _drawOrientation(canvas, axialSize);

    if (showRegions) {
      for (final r in map.regions) {
        if (r.labelAt != null) {
          _drawLabel(canvas, r.vessel.info.abbr, r.labelAt!, 14);
        }
      }
    } else {
      for (final (text, at) in a.labels) {
        _drawLabel(canvas, text, at, 8.5);
      }
    }
  }

  @override
  bool shouldRepaint(_AxialPainter old) =>
      old.selected != selected || old.showRegions != showRegions;
}

class _WillisTab extends StatefulWidget {
  const _WillisTab();

  @override
  State<_WillisTab> createState() => _WillisTabState();
}

class _WillisTabState extends State<_WillisTab> {
  final _map = WillisMap.build();
  _Selection? _selected;

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      hint: 'Bir damara dokunun.',
      size: willisSize,
      orientationNote:
          'Beyin tabanına alttan bakılıyor, ön taraf yukarıda: ekranın solu '
          'hastanın sağıdır.',
      painter: _WillisPainter(_map, _selected),
      legendColors: false,
      legend: const [
        Vessel.ica,
        Vessel.m1,
        Vessel.m2,
        Vessel.a1a2,
        Vessel.acomm,
        Vessel.pcomm,
        Vessel.p1p2,
        Vessel.basilar,
        Vessel.vertebral,
        Vessel.sca,
        Vessel.aica,
        Vessel.pica,
      ],
      onTapLogical: (p) {
        final hit = _map.hitTest(p);
        if (hit == null) return;
        setState(() => _selected = (vessel: hit.vessel, side: hit.side));
        _showInfo(context, hit.vessel, hit.side);
      },
    );
  }
}

class _WillisPainter extends CustomPainter {
  _WillisPainter(this.map, this.selected);

  final WillisMap map;
  final _Selection? selected;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / willisSize.width);

    // Beyin tabanı: kenarları koyulaşan gri dokular.
    for (final (path, tone) in map.anatomy) {
      final b = path.getBounds();
      final base = (tone * 255).round();
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.fromARGB(255, base + 20, base + 12, base + 10),
              Color.fromARGB(255, base - 60, base - 64, base - 66),
            ],
          ).createShader(b),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF3A3A3A),
      );
    }

    // Sinirler.
    canvas.drawPath(
      map.nerves,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF8D7F57),
    );
    canvas.drawPath(
      map.nerves,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFEADCAE),
    );

    // Arterler: koyu kenar, kırmızı gövde ve parlak orta çizgi.
    bool isSel(Vessel v, Side? s) =>
        selected?.vessel == v && selected?.side == s;
    for (final v in map.vessels) {
      if (isSel(v.vessel, v.side)) {
        canvas.drawPath(
          v.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = v.width + 8
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xCCFFEB3B)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
    for (final v in map.vessels) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        v.path,
        stroke
          ..strokeWidth = v.width + 1.6
          ..color = const Color(0xFF5E0B0B),
      );
      canvas.drawPath(
        v.path,
        stroke
          ..strokeWidth = v.width
          ..color = const Color(0xFFC62828),
      );
      canvas.drawPath(
        v.path,
        stroke
          ..strokeWidth = math.max(v.width * 0.3, 1)
          ..color = const Color(0xFFF4A3A3),
      );
    }
    for (final c in WillisMap.icaPoints) {
      canvas.drawCircle(
        c,
        8,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFF4A3A3), Color(0xFFC62828), Color(0xFF5E0B0B)],
            stops: [0, 0.6, 1],
          ).createShader(Rect.fromCircle(center: c, radius: 8)),
      );
    }
    for (final l in map.labels) {
      _drawLabel(canvas, l.text, l.at, 9.5);
    }
    _drawOrientation(canvas, willisSize);
  }

  @override
  bool shouldRepaint(_WillisPainter old) => old.selected != selected;
}

/// Koyu zemin üzerinde okunaklı, gölgeli beyaz etiket.
void _drawLabel(Canvas canvas, String text, Offset at, double size) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontFamily: 'Roboto',
        fontSize: size,
        fontWeight: FontWeight.bold,
        height: 1.1,
        shadows: const [
          Shadow(blurRadius: 3, color: Colors.black),
          Shadow(blurRadius: 1, color: Colors.black),
        ],
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
}

/// BT görüntülerindeki gibi köşelerde taraf işaretleri.
void _drawOrientation(Canvas canvas, Size size) {
  void mark(String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFFD54F),
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, 0));
  }

  mark('SAĞ', const Offset(16, 4));
  mark('SOL', Offset(size.width - 16, 4));
}
