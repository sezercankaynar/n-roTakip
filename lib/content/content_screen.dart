import 'package:flutter/material.dart';

import '../features/search/favorites.dart';
import '../widgets/content_status.dart';
import 'content_page.dart';
import 'markdown_view.dart';

/// Bir içerik dosyasını başlık, kontrol durumu, metin ve kaynaklarla gösterir.
class ContentScreen extends StatefulWidget {
  const ContentScreen({
    super.key,
    required this.asset,
    required this.title,
    this.header,
    this.actions = const [],
  });

  final String asset;

  /// Metnin üstünde gösterilecek ek bölüm (ör. infüzyon hesabı kartı).
  final Widget? header;
  final List<Widget> actions;

  /// Dosya yüklenene kadar uygulama çubuğunda görünen başlık.
  final String title;

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late final Future<ContentPage> _page = ContentPage.load(widget.asset);

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final header = widget.header;
    return FutureBuilder<ContentPage>(
      future: _page,
      builder: (context, snap) {
        final page = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(page?.title ?? title),
            actions: [...widget.actions, FavoriteButton(widget.asset)],
          ),
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
                ?header,
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
