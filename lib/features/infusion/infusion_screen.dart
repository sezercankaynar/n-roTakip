import 'package:flutter/material.dart';

import '../../content/content_screen.dart';
import 'infusion.dart';

/// İnfüzyon hesaplayıcı: sürekli infüzyon, yükleme dozu, mL/sa–damla.
class InfusionScreen extends StatelessWidget {
  const InfusionScreen({
    super.key,
    this.drug,
    this.loading,
    this.initialTab = 0,
  });

  final InfusionDrug? drug;
  final LoadingDrug? loading;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İnfüzyon Hesaplayıcı'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sürekli'),
              Tab(text: 'Yükleme'),
              Tab(text: 'mL/sa · damla'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ContinuousTab(initial: drug),
            LoadingTab(initial: loading),
            const DripTab(),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    onChanged: onChanged,
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.value,
    required this.unit,
    this.lines = const [],
    this.level = _Level.ok,
  });

  final String value;
  final String unit;
  final List<String> lines;
  final _Level level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (level) {
      _Level.ok => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Level.caution => (const Color(0xFFFFF3CD), const Color(0xFF664D03)),
      _Level.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Card(
      color: bg,
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(color: fg, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '  $unit',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l, style: TextStyle(color: fg)),
              ),
          ],
        ),
      ),
    );
  }
}

enum _Level { ok, caution, danger }

const _doubleCheck =
    'Sonucu hekim istemi ve pompa ayarıyla iki kişi kontrol edin. Hazırlık '
    'örnektir; kurumunuzun konsantrasyonunu girin.';

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.fact_check,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _doubleCheck,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

void _openPage(BuildContext context, String asset, String title) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContentScreen(asset: asset, title: title),
      ),
    );

/// Sürekli infüzyon: dozdan pompa hızına veya hızdan doza.
class ContinuousTab extends StatefulWidget {
  const ContinuousTab({super.key, this.initial});

  final InfusionDrug? initial;

  @override
  State<ContinuousTab> createState() => _ContinuousTabState();
}

class _ContinuousTabState extends State<ContinuousTab>
    with AutomaticKeepAliveClientMixin {
  InfusionDrug? _drug;
  final _amount = TextEditingController();
  final _volume = TextEditingController();
  final _weight = TextEditingController();
  final _input = TextEditingController();
  AmountUnit _amountUnit = AmountUnit.mg;
  DoseUnit _unit = DoseUnit.mcgKgMin;
  bool _fromDose = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _select(widget.initial);
  }

  @override
  void dispose() {
    for (final c in [_amount, _volume, _weight, _input]) {
      c.dispose();
    }
    super.dispose();
  }

  void _select(InfusionDrug? d) {
    _drug = d;
    if (d != null) {
      _amount.text = formatNumber(d.prepAmount);
      _amountUnit = d.prepUnit;
      _volume.text = formatNumber(d.prepVolume);
      _unit = d.unit;
      _input.text = d.low == null ? '' : formatNumber(d.low!);
    }
  }

  Infusion? get _infusion {
    final inf = Infusion(
      amount: parseNumber(_amount.text) ?? 0,
      amountUnit: _amountUnit,
      volumeMl: parseNumber(_volume.text) ?? 0,
      unit: _unit,
      weightKg: parseNumber(_weight.text),
    );
    return inf.isValid ? inf : null;
  }

  _Level _levelFor(double dose) {
    final d = _drug;
    if (d == null) return _Level.ok;
    if (d.max != null && dose > d.max! + 1e-9) return _Level.danger;
    if ((d.high != null && dose > d.high! + 1e-9) ||
        (d.low != null && dose < d.low! - 1e-9)) {
      return _Level.caution;
    }
    return _Level.ok;
  }

  String? _levelText(_Level l) => switch (l) {
    _Level.ok => null,
    _Level.caution => 'Olağan aralığın dışında; istemi doğrulayın.',
    _Level.danger => 'Önerilen en yüksek dozun üstünde!',
  };

  List<double> _steps(InfusionDrug d) {
    final lo = d.low ?? 0;
    final hi = d.high!;
    if (hi <= lo) return [hi];
    return [for (var i = 0; i <= 5; i++) lo + (hi - lo) * i / 5];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final d = _drug;
    final inf = _infusion;
    final value = parseNumber(_input.text);

    Widget? result;
    if (inf != null && value != null && value >= 0) {
      final conc =
          'Konsantrasyon: ${formatNumber(inf.concentration, maxDecimals: 3)} '
          '${_unit.amount.label}/mL';
      if (_fromDose) {
        final level = _levelFor(value);
        result = _ResultCard(
          value: formatNumber(inf.rateFor(value), maxDecimals: 1),
          unit: 'mL/sa',
          level: level,
          lines: [
            '${formatNumber(value, maxDecimals: 3)} ${_unit.label} için',
            conc,
            ?_levelText(level),
          ],
        );
      } else {
        final dose = inf.doseFor(value);
        final level = _levelFor(dose);
        result = _ResultCard(
          value: formatNumber(dose, maxDecimals: 3),
          unit: _unit.label,
          level: level,
          lines: [
            '${formatNumber(value, maxDecimals: 1)} mL/sa hızında',
            conc,
            ?_levelText(level),
          ],
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        DropdownButtonFormField<InfusionDrug?>(
          initialValue: d,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'İlaç',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('İlaç seçmeden (elle)'),
            ),
            for (final x in infusionDrugs)
              DropdownMenuItem(
                value: x,
                child: Text(
                  '${x.name} · ${x.unit.label}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (x) => setState(() => _select(x)),
        ),
        if (d != null)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doz birimi: ${d.unit.label}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text('Olağan aralık: ${d.rangeText}'),
                  Text('Örnek hazırlık: ${d.prepText}'),
                  if (d.warning.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '⚠ ${d.warning}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  if (d.asset != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openPage(context, d.asset!, d.name),
                        icon: const Icon(Icons.menu_book, size: 18),
                        label: const Text('İlaç sayfası'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Torbadaki / enjektördeki ilaç',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _NumberField(
                controller: _amount,
                label: 'Miktar',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<AmountUnit>(
                initialValue: _amountUnit,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final u in AmountUnit.values)
                    if (u == _unit.amount || (u.isMass && _unit.amount.isMass))
                      DropdownMenuItem(value: u, child: Text(u.label)),
                ],
                onChanged: (u) => setState(() => _amountUnit = u!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _NumberField(
                controller: _volume,
                label: 'Hacim',
                suffix: 'mL',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (d == null) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<DoseUnit>(
            initialValue: _unit,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Doz birimi',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final u in DoseUnit.values)
                DropdownMenuItem(value: u, child: Text(u.label)),
            ],
            onChanged: (u) => setState(() {
              _unit = u!;
              if (!_unit.compatibleWith(_amountUnit)) {
                _amountUnit = _unit.amount;
              }
            }),
          ),
        ],
        if (_unit.perKg) ...[
          const SizedBox(height: 12),
          _NumberField(
            controller: _weight,
            label: 'Hasta kilosu',
            suffix: 'kg',
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Dozdan hıza')),
            ButtonSegment(value: false, label: Text('Hızdan doza')),
          ],
          selected: {_fromDose},
          onSelectionChanged: (v) => setState(() {
            _fromDose = v.first;
            _input.clear();
          }),
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _input,
          label: _fromDose ? 'İstenen doz' : 'Pompa hızı',
          suffix: _fromDose ? _unit.label : 'mL/sa',
          onChanged: (_) => setState(() {}),
        ),
        ?result,
        if (result == null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _unit.perKg && parseNumber(_weight.text) == null
                  ? 'Sonuç için hasta kilosunu girin.'
                  : 'Sonuç için bütün alanları doldurun.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (d != null && d.high != null && inf != null) ...[
          const SizedBox(height: 16),
          Text(
            'Doz tablosu (bu hazırlıkla)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: theme.dividerColor),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                children: [
                  _cell(d.unit.label, bold: true),
                  _cell('mL/sa', bold: true),
                ],
              ),
              for (final s in _steps(d))
                TableRow(
                  children: [
                    _cell(formatNumber(s, maxDecimals: 3)),
                    _cell(formatNumber(inf.rateFor(s), maxDecimals: 1)),
                  ],
                ),
            ],
          ),
        ],
        const _Footer(),
      ],
    );
  }

  Widget _cell(String t, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Text(
      t,
      style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
    ),
  );
}

/// Kiloya göre yükleme dozu ve veriliş hızı.
class LoadingTab extends StatefulWidget {
  const LoadingTab({super.key, this.initial});

  final LoadingDrug? initial;

  @override
  State<LoadingTab> createState() => _LoadingTabState();
}

class _LoadingTabState extends State<LoadingTab>
    with AutomaticKeepAliveClientMixin {
  late LoadingDrug _drug = widget.initial ?? loadingDrugs.first;
  final _weight = TextEditingController();
  late final _volume = TextEditingController(
    text: formatNumber(_drug.defaultVolume),
  );
  late final _minutes = TextEditingController(text: '${_drug.defaultMinutes}');

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_weight, _volume, _minutes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final d = _drug;
    final kg = parseNumber(_weight.text);
    final vol = parseNumber(_volume.text);
    final min = parseNumber(_minutes.text);

    Widget? result;
    if (kg != null &&
        kg > 0 &&
        vol != null &&
        vol > 0 &&
        min != null &&
        min > 0) {
      final total = d.totalMg(kg);
      final capped = d.maxMg != null && d.mgPerKg * kg > d.maxMg!;
      final mgPerMin = total / min;
      final minMin = d.minMinutes(kg);
      final tooFast = minMin != null && min + 1e-9 < minMin;
      result = _ResultCard(
        value: formatNumber(mlPerHour(vol, min), maxDecimals: 1),
        unit: 'mL/sa',
        level: tooFast ? _Level.danger : _Level.ok,
        lines: [
          'Toplam doz: ${formatNumber(total, maxDecimals: 0)} mg'
              '${capped ? ' (en fazla ${formatNumber(d.maxMg!)} mg ile sınırlandı)' : ''}',
          '${formatNumber(vol)} mL içinde, ${formatNumber(min)} dakikada',
          'Veriliş hızı: ${formatNumber(mgPerMin, maxDecimals: 1)} mg/dk',
          'Konsantrasyon: ${formatNumber(total / vol, maxDecimals: 1)} mg/mL',
          if (tooFast)
            'Çok hızlı! En az ${formatNumber(minMin.ceilToDouble())} dakikada '
                'verilmeli (en fazla ${formatNumber(d.maxMgPerMin!)} mg/dk).',
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        DropdownButtonFormField<LoadingDrug>(
          initialValue: d,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'İlaç',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final x in loadingDrugs)
              DropdownMenuItem(value: x, child: Text(x.name)),
          ],
          onChanged: (x) => setState(() {
            _drug = x!;
            _volume.text = formatNumber(x.defaultVolume);
            _minutes.text = '${x.defaultMinutes}';
          }),
        ),
        Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatNumber(d.mgPerKg)} mg/kg'
                  '${d.maxMg == null ? '' : ', en fazla ${formatNumber(d.maxMg!)} mg'}'
                  '${d.maxMgPerMin == null ? '' : ', en fazla ${formatNumber(d.maxMgPerMin!)} mg/dk'}',
                  style: theme.textTheme.titleSmall,
                ),
                if (d.note.isNotEmpty) Text(d.note),
                if (d.asset != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openPage(context, d.asset!, d.name),
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('İlaç sayfası'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _weight,
          label: 'Hasta kilosu',
          suffix: 'kg',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: _volume,
                label: 'Seyreltme hacmi',
                suffix: 'mL',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberField(
                controller: _minutes,
                label: 'Süre',
                suffix: 'dk',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        ?result,
        const _Footer(),
      ],
    );
  }
}

/// Hacim ve süreden mL/sa; mL/sa'dan damla/dakika.
class DripTab extends StatefulWidget {
  const DripTab({super.key});

  @override
  State<DripTab> createState() => _DripTabState();
}

class _DripTabState extends State<DripTab> with AutomaticKeepAliveClientMixin {
  final _volume = TextEditingController();
  final _hours = TextEditingController();
  final _mins = TextEditingController();
  final _rate = TextEditingController();

  static const _sets = [
    (20, 'Standart set (20 damla/mL)'),
    (60, 'Mikro set (60 damla/mL)'),
    (15, 'Kan seti (15 damla/mL)'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_volume, _hours, _mins, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final vol = parseNumber(_volume.text);
    final total =
        (parseNumber(_hours.text) ?? 0) * 60 + (parseNumber(_mins.text) ?? 0);
    final fromVolume = vol != null && vol > 0 && total > 0
        ? mlPerHour(vol, total)
        : null;
    final rate = fromVolume ?? parseNumber(_rate.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('Hacim ve süreden', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _NumberField(
          controller: _volume,
          label: 'Verilecek hacim',
          suffix: 'mL',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: _hours,
                label: 'Süre',
                suffix: 'saat',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberField(
                controller: _mins,
                label: 've',
                suffix: 'dakika',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('veya pompa hızını yazın', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _NumberField(
          controller: _rate,
          label: 'Hız',
          suffix: 'mL/sa',
          onChanged: (_) => setState(() {}),
        ),
        if (rate != null && rate > 0) ...[
          _ResultCard(
            value: formatNumber(rate, maxDecimals: 1),
            unit: 'mL/sa',
            lines: [
              if (fromVolume != null)
                '${formatNumber(vol!)} mL, ${formatNumber(total)} dakikada',
            ],
          ),
          const SizedBox(height: 8),
          for (final (factor, label) in _sets)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.water_drop),
              title: Text(label),
              trailing: Text(
                '${formatNumber(dropsPerMinute(rate, factor), maxDecimals: 0)} damla/dk',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          'Setin damla sayısı ambalajında yazar; farklıysa hesap değişir. '
          'Yüksek riskli ilaçlar için damla sayarak değil, pompa ile verin.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
