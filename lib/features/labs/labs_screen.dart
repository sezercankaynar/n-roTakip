import 'package:flutter/material.dart';

import '../../widgets/content_status.dart';
import '../drugs/drug_guide_screen.dart' show normalizeForSearch;
import '../infusion/infusion.dart' show formatNumber, parseNumber;
import 'labs.dart';

const labSources = [
  'Kratz A, Ferraro M, Sluss PM, Lewandrowski KB. Laboratory reference '
      'values. N Engl J Med. 2004;351(15):1548-1563.',
  'Dighe AS, Rao A, Coakley AB, Lewandrowski KB. Analysis of laboratory '
      'critical value reporting at a large academic medical center. Am J '
      'Clin Pathol. 2006;125(5):758-764.',
  'Powers WJ, Rabinstein AA, Ackerson T, et al. Guidelines for the Early '
      'Management of Patients With Acute Ischemic Stroke: 2019 Update. '
      'Stroke. 2019;50(12):e344-e418.',
  'Spasovski G, Vanholder R, Allolio B, et al. Clinical practice guideline '
      'on diagnosis and treatment of hyponatraemia. Eur J Endocrinol. '
      '2014;170(3):G1-G47.',
  'Hoh BL, Ko NU, Amin-Hanjani S, et al. 2023 Guideline for the Management '
      'of Patients With Aneurysmal Subarachnoid Hemorrhage. Stroke. '
      '2023;54(7):e314-e370.',
];

(String, Color) levelLabel(LabLevel l) => switch (l) {
  LabLevel.criticalLow => ('KRİTİK DÜŞÜK', const Color(0xFFC62828)),
  LabLevel.criticalHigh => ('KRİTİK YÜKSEK', const Color(0xFFC62828)),
  LabLevel.low => ('Düşük', const Color(0xFFB26A00)),
  LabLevel.high => ('Yüksek', const Color(0xFFB26A00)),
  LabLevel.normal => ('Normal', const Color(0xFF2E7D32)),
};

/// Laboratuvar referans aralıkları, kritik değerler ve değer yorumlama.
class LabsScreen extends StatefulWidget {
  const LabsScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  late final _search = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(LabTest t, String q) =>
      q.isEmpty ||
      [
        t.name,
        ...t.aliases,
        t.group.label,
      ].any((s) => normalizeForSearch(s).contains(q));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = normalizeForSearch(_search.text);
    final shown = [
      for (final t in labTests)
        if (_matches(t, q)) t,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratuvar Değerleri')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Tetkik ara (ör. sodyum, INR, BOS)',
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            'Değeri yorumlamak için tetkike dokunun. Kurumunuzun laboratuvar '
            'referansı ve kritik değer listesi esastır.',
            style: theme.textTheme.bodySmall,
          ),
          for (final g in LabGroup.values)
            if (shown.any((t) => t.group == g)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                child: Text(
                  g.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, t)
                        in shown.where((t) => t.group == g).indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _LabRow(test: t),
                    ],
                  ],
                ),
              ),
            ],
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Eşleşen tetkik yok')),
            ),
          if (q.isEmpty) ...[
            const SizedBox(height: 20),
            const _NeuroLimitsCard(),
            const SizedBox(height: 12),
            const _CriticalReportCard(),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Text(
                'Hesaplar',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const _SodiumRateCard(),
            const SizedBox(height: 12),
            const _CalciumCard(),
          ],
          const SizedBox(height: 16),
          const SourcesCard(status: ReviewStatus.draft, sources: labSources),
        ],
      ),
    );
  }
}

class _LabRow extends StatelessWidget {
  const _LabRow({required this.test});

  final LabTest test;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = test;
    final crit = t.criticalText;
    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => LabValueSheet(test: t),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.normalText} ${t.unit}'.trim(),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (crit != null)
                    Text(
                      'Kritik: $crit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.edit_note_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Değer girilince düzeyi ve yapılacakları gösterir.
class LabValueSheet extends StatefulWidget {
  const LabValueSheet({super.key, required this.test});

  final LabTest test;

  @override
  State<LabValueSheet> createState() => _LabValueSheetState();
}

class _LabValueSheetState extends State<LabValueSheet> {
  final _value = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.test;
    final v = parseNumber(_value.text);
    final level = v == null ? null : t.classify(v);
    final critical =
        level == LabLevel.criticalLow || level == LabLevel.criticalHigh;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Normal: ${t.normalText} ${t.unit}'.trim()),
            if (t.criticalText != null)
              Text(
                'Kritik: ${t.criticalText}',
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _value,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Hastanın değeri',
                suffixText: t.unit,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (level != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: levelLabel(level).$2.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: levelLabel(level).$2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelLabel(level).$1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: levelLabel(level).$2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (critical)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Hekime hemen bildirin; sözlü bildirimde geri '
                          'okuyun ve saatiyle kaydedin.',
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (t.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(t.note, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _NeuroLimitsCard extends StatelessWidget {
  const _NeuroLimitsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nörolojide önemli sınırlar',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            for (final (title, text) in neuroLimits)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    children: [
                      TextSpan(
                        text: '$title: ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: text),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CriticalReportCard extends StatelessWidget {
  const _CriticalReportCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kritik değer gelince',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '1. Hastayı değerlendir (bilinç, yaşam bulguları)\n'
              '2. Hekime kurumun belirlediği sürede bildir\n'
              '3. Sözlü bildirimde değeri geri oku, onay al\n'
              '4. Saat, kime bildirildiği ve yapılanı kaydet',
            ),
          ],
        ),
      ),
    );
  }
}

class _SodiumRateCard extends StatefulWidget {
  const _SodiumRateCard();

  @override
  State<_SodiumRateCard> createState() => _SodiumRateCardState();
}

class _SodiumRateCardState extends State<_SodiumRateCard> {
  final _prev = TextEditingController();
  final _now = TextEditingController();
  final _hours = TextEditingController();

  @override
  void dispose() {
    for (final c in [_prev, _now, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = parseNumber(_prev.text);
    final b = parseNumber(_now.text);
    final h = parseNumber(_hours.text);
    String? result;
    Color? color;
    if (a != null && b != null && h != null && h > 0) {
      final change = sodiumChange(a, b);
      final per24 = change * 24 / h;
      final tooFast = per24.abs() > 10;
      result =
          '${change >= 0 ? '+' : ''}${formatNumber(change)} mmol/L '
          '${formatNumber(h)} saatte · 24 saate oranla '
          '${per24 >= 0 ? '+' : ''}${formatNumber(per24)} mmol/L'
          '${tooFast ? '\nÇok hızlı değişim! Hekime hemen bildirin.' : ''}';
      color = tooFast ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    }
    InputDecoration dec(String label, [String? suffix]) =>
        InputDecoration(labelText: label, suffixText: suffix, isDense: true);
    const kb = TextInputType.numberWithOptions(decimal: true);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sodyum değişim hızı',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prev,
                    keyboardType: kb,
                    decoration: dec('Önceki Na'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _now,
                    keyboardType: kb,
                    decoration: dec('Şimdiki Na'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hours,
                    keyboardType: kb,
                    decoration: dec('Arada', 'sa'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (result != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  result,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Kronik hiponatremide ilk 24 saatte en fazla 10 mmol/L artış.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CalciumCard extends StatefulWidget {
  const _CalciumCard();

  @override
  State<_CalciumCard> createState() => _CalciumCardState();
}

class _CalciumCardState extends State<_CalciumCard> {
  final _ca = TextEditingController();
  final _alb = TextEditingController();

  @override
  void dispose() {
    _ca.dispose();
    _alb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = parseNumber(_ca.text);
    final alb = parseNumber(_alb.text);
    const kb = TextInputType.numberWithOptions(decimal: true);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Albümine göre düzeltilmiş kalsiyum',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ca,
                    keyboardType: kb,
                    decoration: const InputDecoration(
                      labelText: 'Kalsiyum',
                      suffixText: 'mg/dL',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _alb,
                    keyboardType: kb,
                    decoration: const InputDecoration(
                      labelText: 'Albümin',
                      suffixText: 'g/dL',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (ca != null && alb != null && alb > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Düzeltilmiş kalsiyum ≈ '
                  '${formatNumber(correctedCalcium(ca, alb))} mg/dL',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Formül: Ca + 0,8 × (4 − albümin). Kesin değer için iyonize '
              'kalsiyum istenir.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
