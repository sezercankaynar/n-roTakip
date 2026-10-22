import 'package:flutter/material.dart';

import '../../content/content_screen.dart';
import '../infusion/infusion.dart';
import '../infusion/infusion_screen.dart';

/// İlaç sayfası; infüzyonla verilen ilaçlarda doz birimi ve hesaplayıcı
/// kartı da gösterilir.
Widget drugPage(String asset, String title) {
  final infusions = infusionDrugsFor(asset);
  final loading = loadingDrugFor(asset);
  return ContentScreen(
    asset: asset,
    title: title,
    header: infusions.isEmpty && loading == null
        ? null
        : InfusionInfoCard(infusions: infusions, loading: loading),
  );
}

class InfusionInfoCard extends StatelessWidget {
  const InfusionInfoCard({super.key, required this.infusions, this.loading});

  final List<InfusionDrug> infusions;
  final LoadingDrug? loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void open(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    final l = loading;
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate),
                const SizedBox(width: 8),
                Text('İnfüzyon', style: theme.textTheme.titleMedium),
              ],
            ),
            for (final d in infusions) ...[
              const SizedBox(height: 8),
              Text(d.name, style: theme.textTheme.titleSmall),
              Text('Doz birimi: ${d.unit.label}'),
              Text('Olağan aralık: ${d.rangeText}'),
              Text('Örnek hazırlık: ${d.prepText}'),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => open(InfusionScreen(drug: d)),
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('Hızı hesapla'),
                ),
              ),
            ],
            if (l != null) ...[
              const SizedBox(height: 8),
              Text('Yükleme dozu', style: theme.textTheme.titleSmall),
              Text(
                '${formatNumber(l.mgPerKg)} mg/kg'
                '${l.maxMg == null ? '' : ', en fazla ${formatNumber(l.maxMg!)} mg'}'
                '${l.maxMgPerMin == null ? '' : ', en fazla ${formatNumber(l.maxMgPerMin!)} mg/dk'}'
                ' · ${l.note}',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      open(InfusionScreen(loading: l, initialTab: 1)),
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('Yükleme hızını hesapla'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
