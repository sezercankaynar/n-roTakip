import 'package:flutter/material.dart';

/// Android'de 1 mantıksal birim (dp) = 1/160 inç; 1 mm ≈ 6,3 dp.
const dpPerMm = 160 / 25.4;

/// Pupil boyutunu karşılaştırmak için mm ölçekli daireler.
class PupilGaugeScreen extends StatelessWidget {
  const PupilGaugeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pupil Cetveli')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Telefonu hastanın gözünün yanına tutup pupili en yakın daireyle '
              'karşılaştırın. Boyutlar telefon ekranına göre yaklaşıktır '
              '(±1 mm); kesin ölçüm için pupillometre kullanılır.',
              style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 18,
            children: [
              for (var mm = 1; mm <= 9; mm++)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 9 * dpPerMm + 4,
                      height: 9 * dpPerMm + 4,
                      child: Center(
                        child: Container(
                          width: mm * dpPerMm,
                          height: mm * dpPerMm,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$mm mm', style: theme.textTheme.titleMedium),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Normal pupil genellikle 2–5 mm, eşit ve ışığa canlı yanıtlıdır. '
            'Yeni gelişen 1 mm\'den büyük fark veya ışığa yanıtsız geniş '
            'pupil hemen hekime bildirilir.',
          ),
        ],
      ),
    );
  }
}
