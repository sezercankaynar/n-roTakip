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
  });

  final String hint;
  final Size size;
  final CustomPainter painter;
  final ValueChanged<Offset> onTapLogical;
  final List<Vessel> legend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.labelMedium;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Text(hint, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Center(child: Text('ÖN (alın)', style: small)),
        Row(
          children: [
            Flexible(child: Text('◀ Hastanın SAĞI', style: small)),
            const Spacer(),
            Flexible(
              child: Text(
                'Hastanın SOLU ▶',
                style: small,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AspectRatio(
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
        Center(child: Text('ARKA (ense)', style: small)),
        const SizedBox(height: 4),
        Text(
          'BT görüntüsündeki gibi: ekranın solu hastanın sağıdır.',
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
                avatar: CircleAvatar(backgroundColor: vesselColors[v]),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _MapScaffold(
      hint:
          'Bir bölgeye dokunun: o damar tıkanırsa görülecek belirtiler '
          'açılır.',
      size: axialSize,
      painter: _AxialPainter(
        _map,
        _selected,
        outlineColor: theme.colorScheme.onSurface,
        labelColor: theme.colorScheme.onSurface,
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

class _AxialPainter extends CustomPainter {
  _AxialPainter(
    this.map,
    this.selected, {
    required this.outlineColor,
    required this.labelColor,
  });

  final AxialMap map;
  final _Selection? selected;
  final Color outlineColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / axialSize.width);
    for (final r in map.regions.reversed) {
      final isSel = selected?.vessel == r.vessel && selected?.side == r.side;
      final color = vesselColors[r.vessel]!;
      canvas.drawPath(
        r.path,
        Paint()..color = color.withValues(alpha: isSel ? 0.95 : 0.55),
      );
      canvas.drawPath(
        r.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 3 : 1
          ..color = isSel ? outlineColor : color,
      );
    }
    canvas.drawPath(
      map.ventricles,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = outlineColor.withValues(alpha: 0.5),
    );
    canvas.drawPath(
      map.outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = outlineColor,
    );
    for (final r in map.regions) {
      if (r.labelAt != null) {
        _drawLabel(canvas, r.vessel.info.abbr, r.labelAt!, 14, labelColor);
      }
    }
  }

  @override
  bool shouldRepaint(_AxialPainter old) =>
      old.selected != selected || old.outlineColor != outlineColor;
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
    final theme = Theme.of(context);
    return _MapScaffold(
      hint: 'Bir damara dokunun. Alttan görünüm, ön taraf yukarıda.',
      size: willisSize,
      painter: _WillisPainter(
        _map,
        _selected,
        labelColor: theme.colorScheme.onSurface,
        highlight: theme.colorScheme.onSurface,
      ),
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
  _WillisPainter(
    this.map,
    this.selected, {
    required this.labelColor,
    required this.highlight,
  });

  final WillisMap map;
  final _Selection? selected;
  final Color labelColor;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / willisSize.width);
    bool isSel(Vessel v, Side? s) =>
        selected?.vessel == v && selected?.side == s;
    for (final s in map.segments) {
      final sel = isSel(s.vessel, s.side);
      final width = switch (s.vessel) {
        Vessel.basilar || Vessel.ica || Vessel.vertebral || Vessel.m1 => 9.0,
        Vessel.m2 || Vessel.a1a2 || Vessel.p1p2 => 7.0,
        _ => 5.0,
      };
      if (sel) {
        canvas.drawLine(
          s.a,
          s.b,
          Paint()
            ..color = highlight
            ..strokeWidth = width + 5
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawLine(
        s.a,
        s.b,
        Paint()
          ..color = vesselColors[s.vessel]!
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final c in WillisMap.icaPoints) {
      canvas.drawCircle(c, 9, Paint()..color = vesselColors[Vessel.ica]!);
    }
    for (final l in map.labels) {
      _drawLabel(canvas, l.text, l.at, 10, labelColor);
    }
  }

  @override
  bool shouldRepaint(_WillisPainter old) =>
      old.selected != selected || old.labelColor != labelColor;
}

void _drawLabel(Canvas canvas, String text, Offset at, double size, Color c) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: c, fontSize: size, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
}
