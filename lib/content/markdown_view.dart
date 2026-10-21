import 'package:flutter/material.dart';

/// İçerik dosyaları için küçük bir Markdown görüntüleyici.
///
/// Desteklenenler: `#`/`##`/`###` başlık, paragraf, `-` madde (iki boşluk
/// girintiyle alt madde), `1.` numaralı madde, `> ` uyarı kutusu,
/// `| a | b |` tablo ve satır içinde `**kalın**`.
class MarkdownView extends StatelessWidget {
  const MarkdownView(this.markdown, {super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in parseBlocks(markdown)) _buildBlock(context, b),
      ],
    );
  }

  Widget _buildBlock(BuildContext context, MdBlock b) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    switch (b) {
      case MdHeading(:final level, :final text):
        final style = switch (level) {
          1 => theme.textTheme.headlineSmall,
          2 => theme.textTheme.titleLarge,
          _ => theme.textTheme.titleMedium,
        };
        return Padding(
          padding: EdgeInsets.only(top: level <= 2 ? 20 : 14, bottom: 6),
          child: Text.rich(
            _inline(text, style?.copyWith(color: theme.colorScheme.primary)),
          ),
        );
      case MdParagraph(text: final t):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text.rich(_inline(t, text.bodyLarge)),
        );
      case MdListItem(:final level, :final marker, text: final t):
        return Padding(
          padding: EdgeInsets.only(left: 4.0 + level * 18, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: marker.length > 1 ? 26 : 16,
                child: Text(marker, style: text.bodyLarge),
              ),
              Expanded(child: Text.rich(_inline(t, text.bodyLarge))),
            ],
          ),
        );
      case MdNote(text: final t):
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text.rich(
            _inline(
              t,
              text.bodyLarge?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        );
      case MdTable(:final rows):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: theme.dividerColor),
              children: [
                for (var r = 0; r < rows.length; r++)
                  TableRow(
                    decoration: r == 0
                        ? BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                          )
                        : null,
                    children: [
                      for (final cell in rows[r])
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text.rich(
                              _inline(
                                cell,
                                r == 0
                                    ? text.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      )
                                    : text.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
    }
  }

  static TextSpan _inline(String s, TextStyle? style) {
    final spans = <TextSpan>[];
    final parts = s.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      );
    }
    return TextSpan(style: style, children: spans);
  }
}

sealed class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  const MdHeading(this.level, this.text);
  final int level;
  final String text;
}

class MdParagraph extends MdBlock {
  const MdParagraph(this.text);
  final String text;
}

class MdListItem extends MdBlock {
  const MdListItem(this.level, this.marker, this.text);
  final int level;
  final String marker;
  final String text;
}

class MdNote extends MdBlock {
  const MdNote(this.text);
  final String text;
}

class MdTable extends MdBlock {
  const MdTable(this.rows);
  final List<List<String>> rows;
}

List<MdBlock> parseBlocks(String markdown) {
  final blocks = <MdBlock>[];
  final para = <String>[];
  final note = <String>[];
  final table = <List<String>>[];

  void flush() {
    if (para.isNotEmpty) blocks.add(MdParagraph(para.join(' ')));
    if (note.isNotEmpty) blocks.add(MdNote(note.join(' ')));
    if (table.isNotEmpty) blocks.add(MdTable([...table]));
    para.clear();
    note.clear();
    table.clear();
  }

  final heading = RegExp(r'^(#{1,3})\s+(.*)$');
  final bullet = RegExp(r'^( *)[-*]\s+(.*)$');
  final numbered = RegExp(r'^( *)(\d+)\.\s+(.*)$');
  final tableSep = RegExp(r'^\|?\s*:?-{3,}');

  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flush();
      continue;
    }
    final t = line.trimLeft();
    if (t.startsWith('|')) {
      if (para.isNotEmpty || note.isNotEmpty) flush();
      if (tableSep.hasMatch(t)) continue;
      var cells = t.split('|').map((c) => c.trim()).toList();
      if (cells.isNotEmpty && cells.first.isEmpty) cells = cells.sublist(1);
      if (cells.isNotEmpty && cells.last.isEmpty) {
        cells = cells.sublist(0, cells.length - 1);
      }
      table.add(cells);
      continue;
    }
    if (t.startsWith('>')) {
      if (para.isNotEmpty || table.isNotEmpty) flush();
      note.add(t.substring(1).trim());
      continue;
    }
    final h = heading.firstMatch(line);
    if (h != null) {
      flush();
      blocks.add(MdHeading(h.group(1)!.length, h.group(2)!.trim()));
      continue;
    }
    final b = bullet.firstMatch(line);
    if (b != null) {
      flush();
      blocks.add(MdListItem(b.group(1)!.length ~/ 2, '•', b.group(2)!));
      continue;
    }
    final n = numbered.firstMatch(line);
    if (n != null) {
      flush();
      blocks.add(
        MdListItem(n.group(1)!.length ~/ 2, '${n.group(2)}.', n.group(3)!),
      );
      continue;
    }
    if (note.isNotEmpty || table.isNotEmpty) flush();
    para.add(t);
  }
  flush();
  return blocks;
}
