import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/content_status.dart';
import 'nihss_items.dart';

/// NIHSS hesaplayıcı: her madde ayrı sayfada, sonunda özet.
class NihssScreen extends StatefulWidget {
  const NihssScreen({super.key});

  @override
  State<NihssScreen> createState() => _NihssScreenState();
}

class _NihssScreenState extends State<NihssScreen> {
  final _answers = <String, NihssOption>{};
  final _pages = PageController();
  int _page = 0;

  // Son sayfa sonuç sayfasıdır.
  int get _pageCount => nihssItems.length + 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _select(NihssItem item, NihssOption option) {
    HapticFeedback.selectionClick();
    setState(() => _answers[item.code] = option);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _page < _pageCount - 1) _goTo(_page + 1);
    });
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni değerlendirme'),
        content: const Text('Tüm seçimler silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(_answers.clear);
      _goTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = nihssTotal(_answers);
    return Scaffold(
      appBar: AppBar(
        title: const Text('NIHSS'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(label: Text('Toplam: $total')),
            ),
          ),
          IconButton(
            tooltip: 'Yeni değerlendirme',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _answers.length / nihssItems.length,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final item in nihssItems)
                    _ItemPage(
                      item: item,
                      selected: _answers[item.code],
                      onSelect: (o) => _select(item, o),
                    ),
                  _ResultPage(answers: _answers, onEdit: (i) => _goTo(i)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Geri'),
                  ),
                  Expanded(
                    child: Text(
                      _page < nihssItems.length
                          ? '${_page + 1} / ${nihssItems.length}'
                          : 'Sonuç',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _page < _pageCount - 1
                        ? () => _goTo(_page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('İleri'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPage extends StatelessWidget {
  const _ItemPage({
    required this.item,
    required this.selected,
    required this.onSelect,
  });

  final NihssItem item;
  final NihssOption? selected;
  final ValueChanged<NihssOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${item.code}. ${item.title}',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(item.instructions),
        if (item.tip != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.tip!,
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final o in item.options)
          Card(
            color: identical(o, selected)
                ? theme.colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: identical(o, selected)
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: identical(o, selected)
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                child: Text(o.score?.toString() ?? 'UN'),
              ),
              title: Text(o.label),
              onTap: () => onSelect(o),
            ),
          ),
      ],
    );
  }
}

class _ResultPage extends StatelessWidget {
  const _ResultPage({required this.answers, required this.onEdit});

  final Map<String, NihssOption> answers;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = nihssTotal(answers);
    final missing = nihssItems.length - answers.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('NIHSS toplam', style: theme.textTheme.titleMedium),
                Text(
                  '$total',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(nihssSeverity(total), style: theme.textTheme.titleLarge),
                if (missing > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$missing madde henüz değerlendirilmedi',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < nihssItems.length; i++)
          ListTile(
            dense: true,
            title: Text('${nihssItems[i].code}. ${nihssItems[i].title}'),
            trailing: Text(switch (answers[nihssItems[i].code]) {
              null => '—',
              final o => o.score?.toString() ?? 'UN',
            }, style: theme.textTheme.titleMedium),
            onTap: () => onEdit(i),
          ),
        const SizedBox(height: 8),
        Text(
          'Şiddet sınıflaması: 0 bulgu yok · 1–4 hafif · 5–15 orta · '
          '16–20 orta-ağır · 21–42 ağır. UN olarak işaretlenen maddeler '
          'toplama 0 olarak katılır. Puan tek başına tedavi kararı için '
          'kullanılmaz.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        const SourcesCard(status: ReviewStatus.draft, sources: nihssSources),
      ],
    );
  }
}
