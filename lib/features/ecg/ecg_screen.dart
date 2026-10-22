import 'package:flutter/material.dart';

import '../../content/content_screen.dart';
import '../../widgets/content_status.dart';
import '../cpr/cpr_screen.dart';
import '../infusion/infusion_screen.dart';
import 'ecg_wave.dart';
import 'rhythms.dart';

const _res = 'assets/content/resusitasyon/';

const ecgSources = [
  'Panchal AR, Bartos JA, Cabañas JG, et al. Part 3: Adult Basic and '
      'Advanced Life Support: 2020 AHA Guidelines for CPR and ECC. '
      'Circulation. 2020;142(16 suppl 2):S366-S468.',
  'Soar J, Böttiger BW, Carli P, et al. European Resuscitation Council '
      'Guidelines 2021: Adult advanced life support. Resuscitation. '
      '2021;161:115-151.',
  'Kusumoto FM, Schoenfeld MH, Barrett C, et al. 2018 ACC/AHA/HRS '
      'Guideline on the Evaluation and Management of Patients With '
      'Bradycardia and Cardiac Conduction Delay. Circulation. '
      '2019;140:e382-e482.',
];

/// Resüsitasyon sayfaları (başlık, dosya, simge).
const resusPages = [
  ('Kardiyak arrest algoritması', 'kardiyak-arrest.md', Icons.monitor_heart),
  ('Nabızlı bradikardi', 'bradikardi.md', Icons.trending_down),
  ('Nabızlı taşikardi', 'tasikardi.md', Icons.trending_up),
  ('Defibrilasyon ve kardiyoversiyon', 'sok-kardiyoversiyon.md', Icons.bolt),
  ('Resüsitasyon ilaçları', 'resusitasyon-ilaclari.md', Icons.medication),
  ('Dolaşım döndükten sonra (ROSC)', 'rosc-sonrasi.md', Icons.favorite),
];

/// EKG ritimleri, EKG okuma ve resüsitasyon.
class EcgScreen extends StatelessWidget {
  const EcgScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EKG ve Resüsitasyon'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ritimler'),
              Tab(text: 'EKG okuma'),
              Tab(text: 'Resüsitasyon'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_RhythmsTab(), _ReadingTab(), _ResusTab()],
        ),
      ),
    );
  }
}

class UrgencyChip extends StatelessWidget {
  const UrgencyChip(this.urgency, {super.key});

  final RhythmUrgency urgency;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: urgency.color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      urgency.label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _RhythmsTab extends StatelessWidget {
  const _RhythmsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
          'Monitörde gördüğün ritme en çok benzeyeni seç. Her zaman önce '
          'hastaya bak: bilinç, solunum, nabız.',
          style: theme.textTheme.bodyMedium,
        ),
        for (final r in rhythms)
          Card(
            margin: const EdgeInsets.only(top: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RhythmDetailScreen(rhythm: r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        UrgencyChip(r.urgency),
                      ],
                    ),
                  ),
                  EcgStrip(r.signal(), seconds: 4, height: 80),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: Text(r.recognize),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        const SourcesCard(status: ReviewStatus.draft, sources: ecgSources),
      ],
    );
  }
}

class RhythmDetailScreen extends StatelessWidget {
  const RhythmDetailScreen({super.key, required this.rhythm});

  final Rhythm rhythm;

  @override
  Widget build(BuildContext context) {
    final r = rhythm;
    final theme = Theme.of(context);
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(r.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          Align(alignment: Alignment.centerLeft, child: UrgencyChip(r.urgency)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: EcgStrip(r.signal(), seconds: 6, height: 150),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '6 saniyelik şerit · 1 büyük kare = 0,2 sn · 25 mm/sn',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.recognize, style: theme.textTheme.titleSmall),
                  const Divider(),
                  row('Hız', r.rate),
                  row('Düzen', r.regular),
                  row('P dalgası', r.p),
                  row('QRS', r.qrs),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Ne yapmalı', style: theme.textTheme.titleMedium),
          for (final (i, a) in r.actions.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: r.urgency.color,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (r.urgency != RhythmUrgency.report &&
              r.urgency != RhythmUrgency.normal &&
              r.urgency != RhythmUrgency.urgent)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CprScreen()),
              ),
              icon: const Icon(Icons.timer),
              label: const Text('CPR Zamanlayıcıyı aç'),
            ),
          if (r.page != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ContentScreen(asset: r.page!, title: 'Algoritma'),
                  ),
                ),
                icon: const Icon(Icons.account_tree),
                label: const Text('İlgili algoritma'),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Ritim tek derivasyondan değerlendirildi; kesin tanı 12 '
            'derivasyonlu EKG ve hekim değerlendirmesiyle konur.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Etiketli normal EKG kompleksi.
class _NormalComplexPainter extends CustomPainter {
  _NormalComplexPainter({required this.dark, required this.labelColor});

  final bool dark;
  final Color labelColor;

  // Beat R tepesi şeritte 0,45. saniyede; pencere 1,2 sn.
  static const _window = 1.2;
  static const _r = 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final strip = Size(size.width, size.height - 54);
    EcgStripPainter(
      EcgSignal.sinus(45),
      seconds: _window,
      start: 0.3 - _r,
      dark: dark,
    ).paint(canvas, strip);

    final pxs = size.width / _window;
    double x(double t) => (_r + t) * pxs;
    final mid = strip.height * 0.6;
    final mm = pxs / 25;

    void label(String text, double t, double y, {bool bold = true}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: labelColor,
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x(t) - tp.width / 2, y - tp.height / 2));
    }

    // Dalga harfleri.
    label('P', -0.12, mid - 3 * mm);
    label('Q', -0.035, mid + 3 * mm);
    label('R', 0, mid - 11.5 * mm);
    label('S', 0.035, mid + 4.5 * mm);
    label('T', 0.30, mid - 5.5 * mm);
    label('ST', 0.14, mid - 2.2 * mm, bold: false);

    // Aralık parantezleri.
    final line = Paint()
      ..color = labelColor
      ..strokeWidth = 1.5;
    void bracket(double t0, double t1, double y, String text) {
      canvas.drawLine(Offset(x(t0), y), Offset(x(t1), y), line);
      canvas.drawLine(Offset(x(t0), y - 4), Offset(x(t0), y + 4), line);
      canvas.drawLine(Offset(x(t1), y - 4), Offset(x(t1), y + 4), line);
      label(text, (t0 + t1) / 2, y + 11, bold: false);
    }

    final base = strip.height + 8;
    bracket(-0.20, -0.045, base, 'PR');
    bracket(-0.035, 0.05, base, 'QRS');
    bracket(-0.04, 0.40, base + 26, 'QT');
  }

  @override
  bool shouldRepaint(_NormalComplexPainter old) =>
      old.dark != dark || old.labelColor != labelColor;
}

class _ReadingTab extends StatefulWidget {
  const _ReadingTab();

  @override
  State<_ReadingTab> createState() => _ReadingTabState();
}

enum _RateMethod {
  big('Büyük kare', 'R–R arası büyük kare sayısı', 300),
  small('Küçük kare', 'R–R arası küçük kare sayısı', 1500),
  six('6 saniye', '6 saniyedeki QRS sayısı', 10);

  const _RateMethod(this.label, this.hint, this.factor);

  final String label;
  final String hint;
  final int factor;

  int? rate(double n) {
    if (n <= 0) return null;
    return (this == six ? n * factor : factor / n).round();
  }
}

class _ReadingTabState extends State<_ReadingTab> {
  _RateMethod _method = _RateMethod.big;
  final _count = TextEditingController();

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = double.tryParse(_count.text.replaceAll(',', '.'));
    final rate = n == null ? null : _method.rate(n);

    Widget step(int i, String title, String body) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 13, child: Text('$i')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text('Normal kompleks', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 230,
            child: CustomPaint(
              size: Size.infinite,
              painter: _NormalComplexPainter(
                dark: theme.brightness == Brightness.dark,
                labelColor: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kâğıt: 1 küçük kare = 0,04 sn · 1 büyük kare = 0,2 sn · '
          '5 büyük kare = 1 sn · 10 küçük kare yükseklik = 1 mV',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: theme.dividerColor),
          columnWidths: const {0: IntrinsicColumnWidth()},
          children: [
            for (final (k, v) in const [
              ('PR', '0,12–0,20 sn (3–5 küçük kare)'),
              ('QRS', '< 0,12 sn (3 küçük kareden az)'),
              ('QTc', 'Erkek < 0,45 sn, kadın < 0,47 sn'),
              ('Hız', '60–100 /dk'),
            ])
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      k,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.all(6), child: Text(v)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Adım adım okuma', style: theme.textTheme.titleMedium),
        step(
          1,
          'Hasta nasıl?',
          'Bilinç, solunum, nabız. Nabız yoksa EKG okumayı bırak, KPR başlat. '
              'Hasta iyiyse ama ekran kötüyse önce kablo, ped ve artefaktı '
              '(titreme, hareket) kontrol et.',
        ),
        step(
          2,
          'Hız kaç?',
          '300 ÷ R–R arasındaki büyük kare sayısı. Düzensiz ritimde 6 '
              'saniyedeki QRS sayısı × 10. Normal 60–100.',
        ),
        step(
          3,
          'Düzenli mi?',
          'R–R aralıkları eşit mi? Bir kâğıda iki R tepesini işaretleyip '
              'şerit boyunca kaydır. Tamamen düzensiz + P yok → AF.',
        ),
        step(
          4,
          'P dalgası var mı?',
          'Her QRS\'in önünde bir P, her P\'den sonra bir QRS var mı? '
              'Testere dişi → flutter; titrek çizgi → AF; P\'ler QRS\'ten '
              'bağımsız → tam blok.',
        ),
        step(
          5,
          'PR aralığı',
          'Normal 0,12–0,20 sn (3–5 küçük kare). Uzun ve sabit → 1. derece '
              'blok; giderek uzayıp atım düşüyor → Mobitz I; sabit ama ani '
              'atım düşüyor → Mobitz II.',
        ),
        step(
          6,
          'QRS dar mı geniş mi?',
          'Dar < 0,12 sn (3 küçük kare). Geniş ve hızlı → aksi '
              'kanıtlanana kadar VT kabul et.',
        ),
        step(
          7,
          'ST segmenti ve T dalgası',
          'ST taban çizgisinden yüksekse (elevasyon) veya düşükse '
              '(depresyon) 12 derivasyonlu EKG çek ve hekime göster.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hız hesaplayıcı', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<_RateMethod>(
                  segments: [
                    for (final m in _RateMethod.values)
                      ButtonSegment(value: m, label: Text(m.label)),
                  ],
                  selected: {_method},
                  onSelectionChanged: (v) => setState(() => _method = v.first),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _count,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _method.hint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (rate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Kalp hızı ≈ $rate /dk'
                      '${rate < 60
                          ? ' (bradikardi)'
                          : rate > 100
                          ? ' (taşikardi)'
                          : ''}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hızlı başvuru: büyük kare → hız',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        const Text('1 → 300 · 2 → 150 · 3 → 100 · 4 → 75 · 5 → 60 · 6 → 50'),
        const SizedBox(height: 16),
        const SourcesCard(status: ReviewStatus.draft, sources: ecgSources),
      ],
    );
  }
}

class _ResusTab extends StatelessWidget {
  const _ResusTab();

  @override
  Widget build(BuildContext context) {
    void push(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () => push(const CprScreen()),
          icon: const Icon(Icons.timer),
          label: const Text('CPR Zamanlayıcıyı aç'),
        ),
        const SizedBox(height: 8),
        for (final (title, file, icon) in resusPages)
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(ContentScreen(asset: '$_res$file', title: title)),
          ),
        ListTile(
          leading: const Icon(Icons.calculate),
          title: const Text('İnfüzyon hesaplayıcı'),
          subtitle: const Text('Amiodaron, dopamin, adrenalin, noradrenalin'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => push(const InfusionScreen()),
        ),
      ],
    );
  }
}
