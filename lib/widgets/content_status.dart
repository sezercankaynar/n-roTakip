import 'package:flutter/material.dart';

/// İçeriğin kontrol durumu (bkz. ROADMAP.md, "Çok önemli bir güvenlik kuralı").
enum ReviewStatus {
  draft('Taslak: kontrol bekliyor', Color(0xFFF9A825), Icons.edit_note),
  nurseApproved('Hemşire onaylı', Color(0xFF2E7D32), Icons.verified),
  physicianApproved('Hekim onaylı', Color(0xFF1565C0), Icons.verified_user);

  const ReviewStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

/// Bir içeriğin kaynakları, kontrol durumu ve son kontrol tarihini gösteren kart.
class SourcesCard extends StatelessWidget {
  const SourcesCard({
    super.key,
    required this.status,
    required this.sources,
    this.lastReviewed,
  });

  final ReviewStatus status;
  final List<String> sources;
  final String? lastReviewed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(status: status),
            if (lastReviewed != null) ...[
              const SizedBox(height: 4),
              Text(
                'Son kontrol: $lastReviewed',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text('Kaynaklar', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final s in sources)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $s', style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(color: status.color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
