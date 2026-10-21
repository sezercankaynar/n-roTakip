import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/content/content_page.dart';
import 'package:norocep/content/content_screen.dart';
import 'package:norocep/content/markdown_view.dart';
import 'package:norocep/widgets/content_status.dart';

void main() {
  final files = Directory('assets/content')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  test('içerik dosyaları bulunur', () {
    expect(files.length, greaterThanOrEqualTo(8));
  });

  for (final f in files) {
    test('${f.path}: başlık, durum ve kaynak içerir', () {
      final page = ContentPage.parse(f.readAsStringSync(), source: f.path);
      expect(page.title, isNotEmpty);
      expect(page.sources, isNotEmpty);
      expect(page.body, isNotEmpty);
      // Her tablo satırı başlıkla aynı sayıda hücre içermeli.
      for (final b in parseBlocks(page.body).whereType<MdTable>()) {
        for (final row in b.rows) {
          expect(row.length, b.rows.first.length, reason: row.join(' | '));
        }
      }
    });
  }

  test('bilgi bloğu ayrıştırılır', () {
    final page = ContentPage.parse('''---
title: Deneme
status: nurse
last_reviewed: 2026-10-21
sources:
  - Kaynak A
  - Kaynak B
---
## Başlık
Metin''');
    expect(page.title, 'Deneme');
    expect(page.status, ReviewStatus.nurseApproved);
    expect(page.lastReviewed, '2026-10-21');
    expect(page.sources, ['Kaynak A', 'Kaynak B']);
    expect(page.body, '## Başlık\nMetin');
  });

  test('kaynaksız içerik reddedilir', () {
    expect(
      () => ContentPage.parse('---\ntitle: X\nstatus: draft\n---\nmetin'),
      throwsFormatException,
    );
  });

  test('markdown blokları', () {
    final blocks = parseBlocks('''## Başlık
Birinci satır
ikinci satır

- madde
  - alt madde
1. bir
> uyarı
| a | b |
|---|---|
| 1 | 2 |''');
    expect(blocks.map((b) => b.runtimeType.toString()), [
      'MdHeading',
      'MdParagraph',
      'MdListItem',
      'MdListItem',
      'MdListItem',
      'MdNote',
      'MdTable',
    ]);
    expect((blocks[1] as MdParagraph).text, 'Birinci satır ikinci satır');
    expect((blocks[3] as MdListItem).level, 1);
    expect((blocks[4] as MdListItem).marker, '1.');
    expect((blocks[6] as MdTable).rows, [
      ['a', 'b'],
      ['1', '2'],
    ]);
  });

  testWidgets('içerik ekranı taşmadan çizilir', (tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    for (final f in files) {
      final asset = f.path.replaceAll('\\', '/');
      await tester.pumpWidget(
        MaterialApp(
          home: ContentScreen(asset: asset, title: 'x'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: asset);
      expect(find.byType(StatusChip), findsOneWidget, reason: asset);
    }
  });
}
