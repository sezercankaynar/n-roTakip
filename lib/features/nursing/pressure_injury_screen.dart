import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/content_page.dart';
import '../../content/markdown_view.dart';
import '../../widgets/content_status.dart';

/// NPIAP 2016 sınıflamasına göre bir bası yarası evresi.
class PressureStage {
  const PressureStage(this.name, this.depth, this.summary, this.signs);

  final String name;
  final StageDepth depth;
  final String summary;
  final List<String> signs;
}

enum StageDepth { stage1, stage2, stage3, stage4, unstageable, deepTissue }

const pressureStages = <PressureStage>[
  PressureStage(
    'Evre 1',
    StageDepth.stage1,
    'Deri bütün; basmakla solmayan, sınırlı kızarıklık.',
    [
      'Parmakla 3 sn bastırıp bırakınca kızarıklık geçmez (solmayan eritem).',
      'Koyu tenli hastada kızarıklık seçilmeyebilir: renk değişikliği, '
          'ısı artışı, sertlik/yumuşaklık ve ağrıya bakın.',
      'Mor/bordo renk Evre 1 değildir → derin doku hasarı düşünün.',
    ],
  ),
  PressureStage(
    'Evre 2',
    StageDepth.stage2,
    'Dermisin açığa çıktığı kısmi kalınlıkta deri kaybı.',
    [
      'Yara yatağı canlı, pembe-kırmızı ve nemli.',
      'Serum dolu bütün ya da patlamış bül olarak görülebilir.',
      'Yağ dokusu, granülasyon, slough ve eskar görülmez.',
      'Nem ilişkili dermatit, flaster yaralanması ve sürtünme yarası '
          'Evre 2 olarak kaydedilmez.',
    ],
  ),
  PressureStage(
    'Evre 3',
    StageDepth.stage3,
    'Tam kalınlıkta deri kaybı; yağ dokusu görünür.',
    [
      'Granülasyon dokusu ve kıvrılmış yara kenarları (epibol) sık görülür.',
      'Slough veya eskar olabilir ama tam kalınlığı gizlemez.',
      'Derinlik bölgeye göre değişir: burun, kulak gibi yağsız bölgelerde '
          'yüzeysel olabilir.',
      'Altı oyuk (undermining) ve tünel olabilir.',
      'Fasya, kas, tendon, bağ, kıkırdak ya da kemik görünmez.',
    ],
  ),
  PressureStage(
    'Evre 4',
    StageDepth.stage4,
    'Tam kalınlıkta deri ve doku kaybı; kas, tendon veya kemik görünür.',
    [
      'Fasya, kas, tendon, bağ, kıkırdak veya kemik görülür ya da '
          'doğrudan ele gelir.',
      'Oyuk ve tünel sıktır; osteomiyelit riski yüksektir.',
      'Cerrahi değerlendirme (debridman, flep) gerekebilir.',
    ],
  ),
  PressureStage(
    'Evrelendirilemeyen',
    StageDepth.unstageable,
    'Tam kalınlıkta kayıp; yara tabanı slough veya eskarla kapalı.',
    [
      'Tabanı göremediğiniz için derinlik bilinmez; temizlenince '
          'Evre 3 ya da 4 çıkar.',
      'Topukta veya iskemik bacakta kuru, sabit, kızarıklığı olmayan '
          'eskar "doğal örtüdür": yumuşatılmaz, kaldırılmaz.',
      'Eskar yumuşar, akıntı, kızarıklık veya koku olursa hekime bildirin.',
    ],
  ),
  PressureStage(
    'Derin doku hasarı (DDH)',
    StageDepth.deepTissue,
    'Bütün ya da açık deride solmayan koyu kırmızı, mor veya bordo alan.',
    [
      'Kan dolu bül de olabilir; renk değişikliğinden önce ağrı ve '
          'ısı farkı hissedilebilir.',
      'Kemik-kas arasındaki derin dokuda başlar; günler içinde hızla '
          'açık yaraya (Evre 3/4) dönüşebilir.',
      'Basıyı hemen kaldırın; bölgeyi her vardiya değerlendirip kaydedin.',
    ],
  ),
];

/// Risk bölgesi işaretli vücut pozisyonu.
class BodyPosition {
  const BodyPosition(this.name, this.icon, this.sites);

  final String name;
  final IconData icon;
  final List<String> sites;
}

const riskPositions = <BodyPosition>[
  BodyPosition('Sırtüstü yatış', Icons.airline_seat_flat, [
    'Oksiput (başın arkası)',
    'Skapula (kürek kemikleri)',
    'Dirsek',
    'Sakrum ve koksiks',
    'Topuk',
  ]),
  BodyPosition('Yan yatış', Icons.hotel, [
    'Kulak',
    'Omuz (akromiyon)',
    'Kaburgalar',
    'Trokanter (kalça yanı)',
    'Diz iç-dış yanları',
    'Malleol (ayak bileği)',
  ]),
  BodyPosition('Oturma', Icons.event_seat, [
    'Skapula',
    'Sakrum ve koksiks',
    'İskial tüberositas (oturma kemikleri)',
    'Diz arkası',
    'Ayak tabanı',
  ]),
];

/// Bası yarası: evre görselleri, risk bölgeleri ve önleme/tedavi rehberi.
class PressureInjuryScreen extends StatelessWidget {
  const PressureInjuryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bası Yarası'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Evreler'),
              Tab(text: 'Risk bölgeleri'),
              Tab(text: 'Bakım'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_StagesTab(), _RiskAreasTab(), _CareTab()],
        ),
      ),
    );
  }
}

class _StagesTab extends StatelessWidget {
  const _StagesTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(status: ReviewStatus.draft),
        ),
        const SizedBox(height: 8),
        Text(
          'Şemalar derinin kesitini gösterir: üstte epidermis, altında '
          'dermis, sarı yağ dokusu, kırmızı kas ve kemik. Gerçek yara '
          'görünümü hastaya göre değişir.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        const _Legend(),
        for (final s in pressureStages) _StageCard(stage: s),
        const SizedBox(height: 8),
        const SourcesCard(
          status: ReviewStatus.draft,
          sources: [
            'Edsberg LE ve ark. Revised National Pressure Ulcer Advisory '
                'Panel Pressure Injury Staging System. J Wound Ostomy '
                'Continence Nurs. 2016;43(6):585-597.',
            'EPUAP/NPIAP/PPPIA. Prevention and Treatment of Pressure '
                'Ulcers/Injuries: Clinical Practice Guideline. 3. baskı, 2019.',
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c,
            border: Border.all(color: Colors.black26),
          ),
        ),
        const SizedBox(width: 4),
        Text(t, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        item(_Palette.epidermis, 'Epidermis'),
        item(_Palette.dermis, 'Dermis'),
        item(_Palette.fat, 'Yağ'),
        item(_Palette.muscle, 'Kas'),
        item(_Palette.bone, 'Kemik'),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage});

  final PressureStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 300 / 160,
            child: CustomPaint(painter: SkinSectionPainter(stage.depth)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(stage.summary, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                for (final s in stage.signs)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(s)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _Palette {
  static const background = Color(0xFFF4F7FA);
  static const epidermis = Color(0xFFE8C4A0);
  static const dermis = Color(0xFFF2A7A0);
  static const fat = Color(0xFFF7DC7A);
  static const fatLobule = Color(0xFFE9C55A);
  static const muscle = Color(0xFFB8463F);
  static const muscleFibre = Color(0xFF8E2F2A);
  static const bone = Color(0xFFF1EBDD);
  static const boneEdge = Color(0xFFBFB49C);
  static const woundBed = Color(0xFFD9363E);
  static const erythema = Color(0xFFE5534B);
  static const slough = Color(0xFFE3C565);
  static const eschar = Color(0xFF3B2A20);
  static const bruise = Color(0xFF6A2C5B);
  static const blister = Color(0xFFFCEFD9);
}

/// Derinin kesitini ve evreye göre doku kaybını çizer (300×160 birim).
class SkinSectionPainter extends CustomPainter {
  SkinSectionPainter(this.depth);

  final StageDepth depth;

  // Katman alt sınırları (y, 160 birimlik yükseklikte).
  static const _surface = 30.0;
  static const _epi = 38.0;
  static const _derm = 62.0;
  static const _fatBottom = 98.0;
  static const _muscleBottom = 132.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 160);

    final fill = Paint()..style = PaintingStyle.fill;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 300, 160),
      fill..color = _Palette.background,
    );

    // Katmanlar.
    void band(double top, double bottom, Color c) =>
        canvas.drawRect(Rect.fromLTRB(0, top, 300, bottom), fill..color = c);
    band(_surface, _epi, _Palette.epidermis);
    band(_epi, _derm, _Palette.dermis);
    band(_derm, _fatBottom, _Palette.fat);
    band(_fatBottom, _muscleBottom, _Palette.muscle);
    band(_muscleBottom, 160, _Palette.muscle);

    // Yağ lobülleri.
    final lobule = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _Palette.fatLobule;
    for (var x = 12.0; x < 300; x += 22) {
      for (final (dy, shift) in [(70.0, 0.0), (86.0, 11.0)]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x + shift, dy), width: 18, height: 12),
          lobule,
        );
      }
    }
    // Kas lifleri.
    final fibre = Paint()
      ..strokeWidth = 0.8
      ..color = _Palette.muscleFibre;
    for (var y = _fatBottom + 6; y < 160; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(300, y + 2), fibre);
    }
    // Kemik (alt ortada).
    final boneRect = Rect.fromCenter(
      center: const Offset(150, 152),
      width: 170,
      height: 40,
    );
    canvas.drawOval(boneRect, fill..color = _Palette.bone);
    canvas.drawOval(
      boneRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _Palette.boneEdge,
    );

    switch (depth) {
      case StageDepth.stage1:
        _erythema(canvas);
      case StageDepth.stage2:
        _stage2(canvas);
      case StageDepth.stage3:
        _crater(canvas, bottom: _fatBottom - 10, halfWidth: 62);
      case StageDepth.stage4:
        _crater(canvas, bottom: 186, halfWidth: 72, exposeBone: true);
      case StageDepth.unstageable:
        _crater(canvas, bottom: 120, halfWidth: 66);
        _cover(canvas, bottom: 120, halfWidth: 66);
      case StageDepth.deepTissue:
        _deepTissue(canvas);
    }

    canvas.restore();
  }

  void _erythema(Canvas canvas) {
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, _surface, 300, _derm));
    canvas.drawOval(
      const Rect.fromLTRB(95, _surface + 2, 205, _derm - 6),
      Paint()
        ..color = _Palette.erythema.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();
    // Deri yüzeyi sağlam: üst çizgi.
    canvas.drawLine(
      const Offset(0, _surface),
      const Offset(300, _surface),
      Paint()
        ..strokeWidth = 1.2
        ..color = const Color(0xFF9C6B45),
    );
  }

  void _stage2(Canvas canvas) {
    // Epidermis kaybı: sığ çanak, dermis içinde kalır.
    final bed = Path()
      ..moveTo(100, _surface)
      ..quadraticBezierTo(150, _derm - 4, 200, _surface)
      ..close();
    canvas.drawPath(bed, Paint()..color = _Palette.background);
    final floor = Path()
      ..moveTo(100, _surface)
      ..quadraticBezierTo(150, _derm - 4, 200, _surface);
    canvas.drawPath(
      floor,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFF07C84),
    );
    // Yanında serum dolu bül.
    final blister = Path()
      ..moveTo(218, _surface)
      ..quadraticBezierTo(240, _surface - 22, 262, _surface)
      ..close();
    canvas.drawPath(blister, Paint()..color = _Palette.blister);
    canvas.drawPath(
      blister,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFB08A63),
    );
  }

  Path _craterPath(double bottom, double halfWidth) {
    const cx = 150.0;
    return Path()
      ..moveTo(cx - halfWidth, _surface)
      ..cubicTo(
        cx - halfWidth + 10,
        bottom,
        cx + halfWidth - 10,
        bottom,
        cx + halfWidth,
        _surface,
      );
  }

  void _crater(
    Canvas canvas, {
    required double bottom,
    required double halfWidth,
    bool exposeBone = false,
  }) {
    final open = _craterPath(bottom, halfWidth)..close();
    canvas.drawPath(open, Paint()..color = _Palette.background);
    if (exposeBone) {
      // Kemik yüzeyi yara tabanında görünür.
      canvas.save();
      canvas.clipPath(open);
      final boneRect = Rect.fromCenter(
        center: const Offset(150, 152),
        width: 170,
        height: 40,
      );
      canvas.drawOval(boneRect, Paint()..color = _Palette.bone);
      canvas.restore();
    }
    canvas.drawPath(
      _craterPath(bottom, halfWidth),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = _Palette.woundBed,
    );
    // Granülasyon noktaları.
    final dot = Paint()..color = const Color(0xFFB0222B);
    final rnd = math.Random(depth.index);
    for (var i = 0; i < 14; i++) {
      final t = 0.12 + 0.76 * i / 13;
      final p = _cubicPoint(t, bottom, halfWidth);
      canvas.drawCircle(p.translate(0, -2 - rnd.nextDouble()), 1.6, dot);
    }
  }

  Offset _cubicPoint(double t, double bottom, double halfWidth) {
    const cx = 150.0;
    final p0 = Offset(cx - halfWidth, _surface);
    final p1 = Offset(cx - halfWidth + 10, bottom);
    final p2 = Offset(cx + halfWidth - 10, bottom);
    final p3 = Offset(cx + halfWidth, _surface);
    final u = 1 - t;
    return p0 * (u * u * u) +
        p1 * (3 * u * u * t) +
        p2 * (3 * u * t * t) +
        p3 * (t * t * t);
  }

  void _cover(
    Canvas canvas, {
    required double bottom,
    required double halfWidth,
  }) {
    // Yara tabanını tamamen örten slough (sarı) ve üstte eskar (siyah).
    final open = _craterPath(bottom, halfWidth)..close();
    canvas.save();
    canvas.clipPath(open);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 300, 160),
      Paint()..color = _Palette.slough,
    );
    final eschar = Path()..moveTo(70, _surface - 2);
    for (var x = 70.0; x <= 230; x += 10) {
      eschar.lineTo(x, _surface + 14 + ((x ~/ 10).isEven ? 5 : 0));
    }
    eschar
      ..lineTo(230, _surface - 2)
      ..close();
    canvas.drawPath(eschar, Paint()..color = _Palette.eschar);
    canvas.restore();
    canvas.drawPath(
      _craterPath(bottom, halfWidth),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8A5A2B),
    );
  }

  void _deepTissue(Canvas canvas) {
    // Deri bütün; kemiğe yakın derin dokuda mor hasar.
    final rect = Rect.fromCenter(
      center: const Offset(150, 108),
      width: 150,
      height: 70,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _Palette.bruise,
            _Palette.bruise.withValues(alpha: 0.55),
            _Palette.bruise.withValues(alpha: 0),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
    // Yüzeyde soluk mor-bordo renk.
    final top = Rect.fromLTRB(105, _surface - 1, 195, _epi + 4);
    canvas.drawOval(
      top,
      Paint()..color = _Palette.bruise.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(SkinSectionPainter old) => old.depth != depth;
}

class _RiskAreasTab extends StatelessWidget {
  const _RiskAreasTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
          'Kırmızı noktalar, kemik çıkıntısı üzerinde basının en çok '
          'yoğunlaştığı yerlerdir. Her pozisyon değişiminde bu bölgelere '
          'bakın ve elinizle ısı ile sertliği yoklayın.',
          style: theme.textTheme.bodyMedium,
        ),
        for (final (i, p) in riskPositions.indexed)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(p.icon),
                      const SizedBox(width: 8),
                      Text(
                        p.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 300 / 130,
                    child: CustomPaint(
                      painter: BodyRiskPainter(
                        i,
                        outline: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final (n, s) in p.sites.indexed)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('${n + 1}. $s'),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Cihazlara bağlı bası: nazal kanül ve oksijen maskesi (kulak, '
          'burun kökü), nazogastrik sonda (burun kanadı), idrar sondası '
          '(uyluk iç yanı), boyunluk, atel, çorap ve kan basıncı manşonu '
          'altını her vardiya kontrol edin.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Sade vücut silüeti ve numaralı risk noktaları (300×130 birim).
class BodyRiskPainter extends CustomPainter {
  BodyRiskPainter(this.position, {required this.outline});

  /// 0: sırtüstü, 1: yan yatış, 2: oturma.
  final int position;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 130);
    final body = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFCFD8DC);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..color = outline.withValues(alpha: 0.6);
    final surface = Paint()
      ..strokeWidth = 3
      ..color = outline.withValues(alpha: 0.35);

    final List<Offset> sites;
    switch (position) {
      case 0:
        canvas.drawLine(const Offset(4, 96), const Offset(296, 96), surface);
        final p = Path()
          ..addOval(
            Rect.fromCenter(
              center: const Offset(30, 76),
              width: 36,
              height: 36,
            ),
          )
          ..addRRect(
            RRect.fromLTRBR(52, 62, 170, 96, const Radius.circular(16)),
          )
          ..addRRect(
            RRect.fromLTRBR(160, 66, 280, 94, const Radius.circular(12)),
          )
          ..addRRect(
            RRect.fromLTRBR(266, 50, 282, 94, const Radius.circular(6)),
          );
        canvas.drawPath(p, body);
        canvas.drawPath(p, edge);
        // Kol.
        final arm = RRect.fromLTRBR(64, 82, 150, 96, const Radius.circular(7));
        canvas.drawRRect(arm, Paint()..color = const Color(0xFFB0BEC5));
        canvas.drawRRect(arm, edge);
        sites = [
          const Offset(16, 88),
          const Offset(76, 94),
          const Offset(110, 94),
          const Offset(160, 94),
          const Offset(280, 92),
        ];
      case 1:
        canvas.drawLine(const Offset(4, 96), const Offset(296, 96), surface);
        final p = Path()
          ..addOval(
            Rect.fromCenter(
              center: const Offset(32, 74),
              width: 36,
              height: 40,
            ),
          )
          ..addRRect(
            RRect.fromLTRBR(54, 58, 172, 96, const Radius.circular(18)),
          )
          ..addRRect(
            RRect.fromLTRBR(160, 66, 278, 96, const Radius.circular(14)),
          )
          ..addRRect(
            RRect.fromLTRBR(264, 76, 290, 96, const Radius.circular(8)),
          );
        canvas.drawPath(p, body);
        canvas.drawPath(p, edge);
        sites = [
          const Offset(32, 92),
          const Offset(70, 94),
          const Offset(112, 94),
          const Offset(154, 94),
          const Offset(214, 94),
          const Offset(270, 94),
        ];
      default:
        // Sandalye.
        canvas.drawLine(
          const Offset(120, 104),
          const Offset(220, 104),
          surface,
        );
        canvas.drawLine(const Offset(124, 104), const Offset(124, 20), surface);
        canvas.drawLine(const Offset(4, 126), const Offset(296, 126), surface);
        final p = Path()
          ..addOval(
            Rect.fromCenter(
              center: const Offset(146, 14),
              width: 26,
              height: 26,
            ),
          )
          ..addRRect(
            RRect.fromLTRBR(128, 28, 166, 104, const Radius.circular(14)),
          )
          ..addRRect(
            RRect.fromLTRBR(140, 80, 230, 104, const Radius.circular(10)),
          )
          ..addRRect(
            RRect.fromLTRBR(214, 90, 236, 124, const Radius.circular(8)),
          )
          ..addRRect(
            RRect.fromLTRBR(214, 114, 262, 126, const Radius.circular(5)),
          );
        canvas.drawPath(p, body);
        canvas.drawPath(p, edge);
        sites = [
          const Offset(130, 46),
          const Offset(134, 98),
          const Offset(158, 102),
          const Offset(218, 100),
          const Offset(246, 124),
        ];
    }

    final dot = Paint()..color = const Color(0xFFD32F2F);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;
    for (final (i, s) in sites.indexed) {
      canvas.drawCircle(s, 7.5, dot);
      canvas.drawCircle(s, 7.5, ring);
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, s - Offset(tp.width / 2, tp.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BodyRiskPainter old) =>
      old.position != position || old.outline != outline;
}

class _CareTab extends StatelessWidget {
  const _CareTab();

  static const asset = 'assets/content/hemsirelik/bas-yarasi-evreleri.md';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContentPage>(
      future: ContentPage.load(asset),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('İçerik yüklenemedi: ${snap.error}'));
        }
        final page = snap.data;
        if (page == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(status: page.status),
            ),
            MarkdownView(page.body),
            const SizedBox(height: 16),
            SourcesCard(
              status: page.status,
              sources: page.sources,
              lastReviewed: page.lastReviewed,
            ),
          ],
        );
      },
    );
  }
}
