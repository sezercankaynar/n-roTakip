import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/content_status.dart';
import 'scale.dart';

/// Her maddeden bir seçeneğin seçildiği genel ölçek hesaplayıcı.
class ScaleScreen extends StatefulWidget {
  const ScaleScreen({super.key, required this.scale});

  final ScaleDefinition scale;

  @override
  State<ScaleScreen> createState() => _ScaleScreenState();
}

class _ScaleScreenState extends State<ScaleScreen> {
  final _selected = <int, int>{}; // madde → seçenek sırası

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.scale;
    final complete = _selected.length == s.items.length;
    final total = _selected.entries.fold(
      0,
      (sum, e) => sum + s.items[e.key].options[e.value].$1,
    );
    final band = complete ? s.interpret(total) : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.title),
        actions: [
          IconButton(
            tooltip: 'Temizle',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(_selected.clear),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          Card(
            color: band?.color ?? theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    complete ? '$total' : '–',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: band == null ? null : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    band?.label ??
                        '${_selected.length}/${s.items.length} madde '
                            '(puan aralığı ${s.minTotal}–${s.maxTotal})',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: band == null ? null : Colors.white,
                    ),
                  ),
                  if (band?.advice != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      band!.advice!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (s.intro != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(s.intro!),
            ),
          for (var i = 0; i < s.items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Text(
                '${i + 1}. ${s.items[i].title}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (s.items[i].help != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(s.items[i].help!, style: theme.textTheme.bodySmall),
              ),
            for (var j = 0; j < s.items[i].options.length; j++)
              Card(
                color: _selected[i] == j
                    ? theme.colorScheme.secondaryContainer
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${s.items[i].options[j].$1}'),
                  ),
                  title: Text(s.items[i].options[j].$2),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected[i] = j);
                  },
                ),
              ),
          ],
          if (s.footnote != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
              child: Text(s.footnote!, style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 12),
          SourcesCard(status: ReviewStatus.draft, sources: s.sources),
        ],
      ),
    );
  }
}
