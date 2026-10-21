import 'package:flutter/services.dart';

import '../widgets/content_status.dart';

/// `assets/content/` altındaki bir içerik dosyası.
///
/// Dosya biçimi: en üstte `---` satırları arasında bilgi bloğu, ardından
/// sade Markdown metni.
///
/// ```
/// ---
/// title: İskemik İnme
/// status: draft            # draft | nurse | physician
/// last_reviewed: 2026-10-21  # isteğe bağlı
/// sources:
///   - Kaynak 1
///   - Kaynak 2
/// ---
/// ## Tanım
/// ...
/// ```
class ContentPage {
  const ContentPage({
    required this.title,
    required this.status,
    required this.sources,
    required this.body,
    this.lastReviewed,
  });

  final String title;
  final ReviewStatus status;
  final List<String> sources;
  final String? lastReviewed;
  final String body;

  static Future<ContentPage> load(String asset, {AssetBundle? bundle}) async {
    final text = await (bundle ?? rootBundle).loadString(asset);
    return parse(text, source: asset);
  }

  static ContentPage parse(String text, {String source = 'içerik'}) {
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      throw FormatException('$source: bilgi bloğu (---) ile başlamalı');
    }
    final end = lines.indexWhere((l) => l.trim() == '---', 1);
    if (end < 0) throw FormatException('$source: bilgi bloğu kapanmamış');

    final meta = <String, String>{};
    final sources = <String>[];
    String? listKey;
    for (final raw in lines.sublist(1, end)) {
      if (raw.trim().isEmpty || raw.trimLeft().startsWith('#')) continue;
      final item = RegExp(r'^\s+-\s+(.*)$').firstMatch(raw);
      if (item != null && listKey == 'sources') {
        sources.add(item.group(1)!.trim());
        continue;
      }
      final kv = RegExp(r'^([a-z_]+):\s*(.*)$').firstMatch(raw);
      if (kv == null) {
        throw FormatException('$source: anlaşılamayan satır: $raw');
      }
      listKey = kv.group(1);
      meta[listKey!] = kv.group(2)!.trim();
    }

    final title = meta['title'];
    if (title == null || title.isEmpty) {
      throw FormatException('$source: title eksik');
    }
    if (sources.isEmpty) {
      throw FormatException('$source: en az bir kaynak gerekli');
    }
    final status = switch (meta['status']) {
      'draft' => ReviewStatus.draft,
      'nurse' => ReviewStatus.nurseApproved,
      'physician' => ReviewStatus.physicianApproved,
      final s => throw FormatException('$source: geçersiz status: $s'),
    };
    final reviewed = meta['last_reviewed'];
    return ContentPage(
      title: title,
      status: status,
      sources: sources,
      lastReviewed: reviewed == null || reviewed.isEmpty ? null : reviewed,
      body: lines.sublist(end + 1).join('\n').trim(),
    );
  }
}
