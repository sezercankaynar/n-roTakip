/// Trombolitik doz hesapları (inme dozları). Arayüzden bağımsız, test edilir.
///
/// Alteplaz: 0,9 mg/kg (en fazla 90 mg); %10 bolus 1 dakikada, kalan 60
/// dakikada. Sulandırılmış konsantrasyon 1 mg/mL.
/// Tenekteplaz: 0,25 mg/kg (en fazla 25 mg); tek bolus. Sulandırılmış
/// konsantrasyon 5 mg/mL.
library;

const minWeightKg = 30.0;
const maxWeightKg = 250.0;

// Küçük kayan nokta hatalarında (18,249999...) yukarı yuvarlansın.
double _round1(double v) => ((v * 10) + 1e-9).roundToDouble() / 10;

/// Virgül veya noktalı ondalık kiloyu okur; geçersizse `null`.
double? parseWeight(String text) {
  final v = double.tryParse(text.trim().replaceAll(',', '.'));
  if (v == null || v < minWeightKg || v > maxWeightKg) return null;
  return v;
}

/// 64.8 → "64,8"; 90.0 → "90".
String formatNumber(double v) {
  final r = _round1(v);
  final s = r == r.roundToDouble()
      ? r.toStringAsFixed(0)
      : r.toStringAsFixed(1);
  return s.replaceAll('.', ',');
}

class AlteplaseDose {
  const AlteplaseDose({
    required this.weightKg,
    required this.totalMg,
    required this.bolusMg,
    required this.infusionMg,
    required this.capped,
    required this.vialMg,
    required this.vials,
  });

  static const mgPerKg = 0.9;
  static const maxMg = 90.0;

  final double weightKg;
  final double totalMg;
  final double bolusMg;
  final double infusionMg;

  /// En yüksek doz (90 mg) sınırına takıldı mı.
  final bool capped;
  final int vialMg;
  final int vials;

  /// 1 mg/mL olduğundan mL değerleri mg ile aynıdır.
  double get preparedMg => (vialMg * vials).toDouble();
  double get discardMg => _round1(preparedMg - totalMg);

  /// İnfüzyon 60 dakikada verildiği için pompa hızı (mL/saat).
  double get infusionRateMlPerHour => infusionMg;

  factory AlteplaseDose.forWeight(double kg, {int vialMg = 50}) {
    final raw = kg * mgPerKg;
    final capped = raw > maxMg;
    final total = _round1(capped ? maxMg : raw);
    final bolus = _round1(total * 0.1);
    return AlteplaseDose(
      weightKg: kg,
      totalMg: total,
      bolusMg: bolus,
      infusionMg: _round1(total - bolus),
      capped: capped,
      vialMg: vialMg,
      vials: (total / vialMg).ceil(),
    );
  }
}

class TenecteplaseDose {
  const TenecteplaseDose({
    required this.weightKg,
    required this.doseMg,
    required this.capped,
    required this.vialMg,
  });

  static const mgPerKg = 0.25;
  static const maxMg = 25.0;
  static const mgPerMl = 5.0;

  final double weightKg;
  final double doseMg;
  final bool capped;
  final int vialMg;

  double get doseMl => _round1(doseMg / mgPerMl);
  double get vialMl => vialMg / mgPerMl;
  double get discardMl => _round1(vialMl - doseMl);

  factory TenecteplaseDose.forWeight(double kg, {int vialMg = 25}) {
    final raw = kg * mgPerKg;
    final capped = raw > maxMg;
    return TenecteplaseDose(
      weightKg: kg,
      doseMg: _round1(capped ? maxMg : raw),
      capped: capped,
      vialMg: vialMg,
    );
  }
}
