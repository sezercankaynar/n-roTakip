import 'package:flutter/material.dart';

import '../widgets/content_status.dart';
import 'content_page.dart';
import 'markdown_view.dart';

/// Bir içerik dosyasını başlık, kontrol durumu, metin ve kaynaklarla gösterir.
class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key, required this.asset, required this.title});

  final String asset;

  /// Dosya yüklenene kadar uygulama çubuğunda görünen başlık.
  final String title;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContentPage>(
      future: ContentPage.load(asset),
      builder: (context, snap) {
        final page = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(page?.title ?? title)),
          body: switch (snap) {
            AsyncSnapshot(hasError: true) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('İçerik yüklenemedi: ${snap.error}'),
              ),
            ),
            _ when page == null => const Center(
              child: CircularProgressIndicator(),
            ),
            _ => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(status: page.status),
                ),
                MarkdownView(page.body),
                const SizedBox(height: 16),
                SourcesCard(
                  status: page.status,
                  sources: page.sources,
                  lastReviewed: page.lastReviewed,
                ),
              ],
            ),
          },
        );
      },
    );
  }
}
