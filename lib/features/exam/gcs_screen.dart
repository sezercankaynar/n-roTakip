import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/content_status.dart';
import 'gcs.dart';

const _gcsSources = [
  'Teasdale G, Jennett B. Assessment of coma and impaired consciousness. '
      'Lancet. 1974;2(7872):81-84.',
  'Teasdale G, Maas A, Lecky F, et al. The Glasgow Coma Scale at 40 years: '
      'standing the test of time. Lancet Neurol. 2014;13(8):844-854.',
];

class GcsScreen extends StatefulWidget {
  const GcsScreen({super.key});

  @override
  State<GcsScreen> createState() => _GcsScreenState();
}

class _GcsScreenState extends State<GcsScreen> {
  final _answers = <String, GcsOption>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = GcsResult(_answers);
    final total = result.total;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glasgow Koma Skalası'),
        actions: [
          IconButton(
            tooltip: 'Temizle',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(_answers.clear),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    total == null ? '–' : '$total',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(result.summary(), style: theme.textTheme.titleMedium),
                  if (result.severity != null) Text(result.severity!),
                  if (result.complete && total == null)
                    const Text(
                      'Değerlendirilemeyen bileşen olduğu için toplam puan '
                      'verilmez; bileşenler ayrı yazılır.',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: result.complete
                        ? () {
                            Clipboard.setData(
                              ClipboardData(text: result.summary()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kopyalandı')),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.copy),
                    label: const Text('Sonucu kopyala'),
                  ),
                ],
              ),
            ),
          ),
          for (final c in gcsComponents) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Text(
                '${c.title} (${c.code})',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            for (final o in c.options)
              Card(
                color: identical(_answers[c.code], o)
                    ? theme.colorScheme.secondaryContainer
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(o.score?.toString() ?? (c.ntCode ?? 'NT')),
                  ),
                  title: Text(o.label),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _answers[c.code] = o);
                  },
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Motor yanıtta en iyi yanıt puanlanır; iki taraf arasındaki fark '
            'ayrıca kayda yazılır. Sternuma sert ovma yerine trapez sıkıştırma '
            'veya supraorbital bası önerilir.',
          ),
          const SizedBox(height: 12),
          const SourcesCard(status: ReviewStatus.draft, sources: _gcsSources),
        ],
      ),
    );
  }
}
