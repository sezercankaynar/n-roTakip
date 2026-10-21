import 'package:flutter/material.dart';

import '../../widgets/content_status.dart';
import 'thrombolytic_dose.dart';

enum _Drug { alteplase, tenecteplase }

const _doseSources = [
  'Powers WJ, Rabinstein AA, Ackerson T, et al. Guidelines for the Early '
      'Management of Patients With Acute Ischemic Stroke: 2019 Update. '
      'Stroke. 2019;50(12):e344-e418.',
  'Alamowitch S, Turc G, Palaiodimou L, et al. European Stroke Organisation '
      '(ESO) expedited recommendation on tenecteplase for acute ischaemic '
      'stroke. Eur Stroke J. 2023;8(1):8-54.',
  'Alteplaz (Actilyse) ve tenekteplaz (Metalyse) kısa ürün bilgileri.',
];

/// Kiloya göre alteplaz veya tenekteplaz dozu ve hazırlama miktarları.
class ThrombolyticDoseScreen extends StatefulWidget {
  const ThrombolyticDoseScreen({super.key});

  @override
  State<ThrombolyticDoseScreen> createState() => _ThrombolyticDoseScreenState();
}

class _ThrombolyticDoseScreenState extends State<ThrombolyticDoseScreen> {
  final _weight = TextEditingController();
  _Drug _drug = _Drug.alteplase;
  int _alteplaseVial = 50;
  int _tenecteplaseVial = 25;

  @override
  void initState() {
    super.initState();
    _weight.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kg = parseWeight(_weight.text);
    final typed = _weight.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('tPA Doz Hesaplayıcı')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Doz ve hazırlama iki sağlık çalışanı tarafından bağımsız olarak '
              'kontrol edilmelidir. Hekim istemi ve kurum protokolü esastır.',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_Drug>(
            segments: const [
              ButtonSegment(value: _Drug.alteplase, label: Text('Alteplaz')),
              ButtonSegment(
                value: _Drug.tenecteplase,
                label: Text('Tenekteplaz'),
              ),
            ],
            selected: {_drug},
            onSelectionChanged: (s) => setState(() => _drug = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              labelText: 'Hastanın kilosu (kg)',
              border: const OutlineInputBorder(),
              suffixText: 'kg',
              errorText: typed && kg == null
                  ? 'Geçerli bir kilo girin '
                        '(${formatNumber(minWeightKg)}–'
                        '${formatNumber(maxWeightKg)} kg)'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          _VialPicker(
            label: 'Flakon',
            options: _drug == _Drug.alteplase
                ? const [50, 20, 10]
                : const [25, 50],
            value: _drug == _Drug.alteplase
                ? _alteplaseVial
                : _tenecteplaseVial,
            onChanged: (v) => setState(() {
              if (_drug == _Drug.alteplase) {
                _alteplaseVial = v;
              } else {
                _tenecteplaseVial = v;
              }
            }),
          ),
          const SizedBox(height: 16),
          if (kg != null)
            _drug == _Drug.alteplase
                ? _AlteplaseResult(
                    AlteplaseDose.forWeight(kg, vialMg: _alteplaseVial),
                  )
                : _TenecteplaseResult(
                    TenecteplaseDose.forWeight(kg, vialMg: _tenecteplaseVial),
                  ),
          const SizedBox(height: 16),
          const SourcesCard(status: ReviewStatus.draft, sources: _doseSources),
        ],
      ),
    );
  }
}

class _VialPicker extends StatelessWidget {
  const _VialPicker({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<int> options;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$label:'),
        for (final o in options)
          ChoiceChip(
            label: Text('$o mg'),
            selected: o == value,
            onSelected: (_) => onChanged(o),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value, {this.big = false, this.detail});

  final String label;
  final String value;
  final String? detail;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleMedium),
                if (detail != null)
                  Text(detail!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style:
                (big
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.titleLarge)
                    ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _AlteplaseResult extends StatelessWidget {
  const _AlteplaseResult(this.d);

  final AlteplaseDose d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String mg(double v) => '${formatNumber(v)} mg';
    String ml(double v) => '${formatNumber(v)} mL';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '0,9 mg/kg × ${formatNumber(d.weightKg)} kg'
              '${d.capped ? ', en fazla 90 mg' : ''}',
              style: theme.textTheme.bodyMedium,
            ),
            if (d.capped)
              Text(
                'Hesaplanan doz 90 mg\'ı aştığı için en yüksek doz uygulandı.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            const Divider(),
            _ResultRow(
              'Toplam doz',
              mg(d.totalMg),
              big: true,
              detail: '1 mg/mL ile ${ml(d.totalMg)}',
            ),
            _ResultRow(
              'Bolus (%10)',
              ml(d.bolusMg),
              detail: '${mg(d.bolusMg)}, 1 dakikada IV',
            ),
            _ResultRow(
              'İnfüzyon (%90)',
              ml(d.infusionMg),
              detail: '${mg(d.infusionMg)}, 60 dakikada',
            ),
            _ResultRow(
              'Pompa hızı',
              '${formatNumber(d.infusionRateMlPerHour)} mL/saat',
              detail: '60 dakika boyunca',
            ),
            const Divider(),
            Text('Hazırlama', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '• ${d.vials} × ${d.vialMg} mg flakon = ${mg(d.preparedMg)} '
              '(${ml(d.preparedMg)}) hazırlanır.\n'
              '• Bolus ve infüzyondan önce fazla olan '
              '${ml(d.discardMg)} (${mg(d.discardMg)}) çekilip atılır.\n'
              '• Flakon çalkalanmaz, hafifçe çevrilerek karıştırılır.\n'
              '• İnfüzyon bitince hat, kurum protokolüne göre serum fizyolojik '
              'ile aynı hızda yıkanır.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TenecteplaseResult extends StatelessWidget {
  const _TenecteplaseResult(this.d);

  final TenecteplaseDose d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '0,25 mg/kg × ${formatNumber(d.weightKg)} kg'
              '${d.capped ? ', en fazla 25 mg' : ''}',
            ),
            if (d.capped)
              Text(
                'Hesaplanan doz 25 mg\'ı aştığı için en yüksek doz uygulandı.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            const Divider(),
            _ResultRow(
              'Doz (tek bolus)',
              '${formatNumber(d.doseMg)} mg',
              big: true,
              detail: '5–10 saniyede IV',
            ),
            _ResultRow(
              'Hacim',
              '${formatNumber(d.doseMl)} mL',
              detail: '5 mg/mL konsantrasyonda',
            ),
            const Divider(),
            Text('Hazırlama', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '• ${d.vialMg} mg flakon ${formatNumber(d.vialMl)} mL steril su ile '
              'sulandırılır (5 mg/mL). Çalkalanmaz.\n'
              '• ${formatNumber(d.doseMl)} mL çekilir; kalan '
              '${formatNumber(d.discardMl)} mL atılır.\n'
              '• Öncesinde ve sonrasında hat serum fizyolojik ile yıkanır; '
              'dekstrozlu sıvıyla aynı hattan verilmez.',
            ),
            const SizedBox(height: 8),
            Text(
              'Bu inme dozudur. Kalp krizinde kullanılan kiloya göre yüksek doz '
              'tablosu kullanılmaz.',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
