import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../main.dart';

/// İlk açılışta gösterilen, sağlık profesyoneli onayı istenen ekran.
class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.health_and_safety,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              appName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            Text(
              'Nöroloji klinik cep rehberi',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            const _Point(
              icon: Icons.medical_services,
              text:
                  'Bu uygulama sağlık profesyonelleri (hemşire ve hekim) '
                  'için hazırlanmıştır.',
            ),
            const _Point(
              icon: Icons.gavel,
              text:
                  'Klinik kararın yerine geçmez. Kurumunuzun protokolleri '
                  've hekim istemi her zaman önceliklidir.',
            ),
            const _Point(
              icon: Icons.menu_book,
              text:
                  'İçerikler kılavuz ve makalelere dayanır; her bölümde '
                  'kaynak ve kontrol durumu gösterilir.',
            ),
            const _Point(
              icon: Icons.lock,
              text:
                  'Hasta adı veya kimlik bilgisi girmeyin. Uygulama '
                  'kişisel veri toplamaz, internete veri göndermez.',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Sağlık profesyoneliyim, yukarıdakileri okudum ve kabul '
                'ediyorum.',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _confirmed
                  ? () => AppSettingsScope.of(context).acceptDisclaimer()
                  : null,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Devam et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
