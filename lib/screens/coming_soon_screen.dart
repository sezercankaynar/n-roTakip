import 'package:flutter/material.dart';

/// Henüz yapılmamış bölümler için yer tutucu ekran.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.version,
  });

  final String title;
  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Hazırlanıyor', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Bu bölüm Sürüm $version ile gelecek.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
