import 'package:flutter/material.dart';

import '../../widgets/content_status.dart';

const mrsLevels = [
  (0, 'Hiç belirti yok'),
  (
    1,
    'Belirtilere rağmen anlamlı engellilik yok: olağan görev ve '
        'etkinliklerin tümünü yapabiliyor',
  ),
  (
    2,
    'Hafif engellilik: önceki etkinliklerin hepsini yapamıyor ama kendi '
        'işlerini yardımsız görebiliyor',
  ),
  (
    3,
    'Orta engellilik: biraz yardıma gereksinim duyuyor ama yardımsız '
        'yürüyebiliyor',
  ),
  (
    4,
    'Orta-ağır engellilik: yardımsız yürüyemiyor ve bedensel '
        'gereksinimlerini yardımsız karşılayamıyor',
  ),
  (
    5,
    'Ağır engellilik: yatağa bağımlı, idrar-gaita kaçırma, sürekli bakım '
        've dikkat gerektiriyor',
  ),
  (6, 'Ölüm'),
];

/// Modifiye Rankin Ölçeği: inme sonrası bağımsızlık düzeyi.
class MrsScreen extends StatefulWidget {
  const MrsScreen({super.key});

  @override
  State<MrsScreen> createState() => _MrsScreenState();
}

class _MrsScreenState extends State<MrsScreen> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Modifiye Rankin Ölçeği')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'İnme öncesi (trombolitik/trombektomi kararında) ve taburculuk/'
            'kontrollerde işlevsel durumu tanımlar. Hasta ve yakınından '
            'günlük yaşamı sorularak belirlenir.',
          ),
          const SizedBox(height: 8),
          for (final (score, text) in mrsLevels)
            Card(
              color: _selected == score
                  ? theme.colorScheme.secondaryContainer
                  : null,
              child: ListTile(
                leading: CircleAvatar(child: Text('$score')),
                title: Text(text),
                onTap: () => setState(() => _selected = score),
              ),
            ),
          if (_selected != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'mRS $_selected',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          const SizedBox(height: 12),
          const SourcesCard(
            status: ReviewStatus.draft,
            sources: [
              'van Swieten JC, Koudstaal PJ, Visser MC, Schouten HJ, van Gijn '
                  'J. Interobserver agreement for the assessment of handicap '
                  'in stroke patients. Stroke. 1988;19(5):604-607.',
              'Banks JL, Marotta CA. Outcomes validity and reliability of the '
                  'modified Rankin scale. Stroke. 2007;38(3):1091-1096.',
            ],
          ),
        ],
      ),
    );
  }
}
