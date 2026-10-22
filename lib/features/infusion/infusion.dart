/// İnfüzyon hesapları: doz birimleri, hazır ilaç bilgileri ve formüller.
library;

/// Torbadaki ilaç miktarının birimi.
enum AmountUnit {
  mg('mg', 1000),
  mcg('µg', 1),
  unit('ünite', 1),
  mEq('mEq', 1);

  const AmountUnit(this.label, this._mcgFactor);

  final String label;

  /// mg ↔ µg dönüşümü için (diğer birimler kendi içinde).
  final double _mcgFactor;

  bool get isMass => this == mg || this == mcg;

  /// [value] miktarını [to] birimine çevirir. Kütle dışı birimler
  /// yalnızca kendisine çevrilebilir.
  double convert(double value, AmountUnit to) {
    if (this == to) return value;
    if (isMass && to.isMass) return value * _mcgFactor / to._mcgFactor;
    throw ArgumentError('$label → ${to.label} çevrilemez');
  }
}

/// Sürekli infüzyon doz birimi (ör. µg/kg/dk).
enum DoseUnit {
  mcgKgMin('µg/kg/dk', AmountUnit.mcg, perKg: true, perMinute: true),
  mcgKgH('µg/kg/sa', AmountUnit.mcg, perKg: true, perMinute: false),
  mgKgH('mg/kg/sa', AmountUnit.mg, perKg: true, perMinute: false),
  mcgMin('µg/dk', AmountUnit.mcg, perKg: false, perMinute: true),
  mgMin('mg/dk', AmountUnit.mg, perKg: false, perMinute: true),
  mgH('mg/sa', AmountUnit.mg, perKg: false, perMinute: false),
  unitKgH('ünite/kg/sa', AmountUnit.unit, perKg: true, perMinute: false),
  unitH('ünite/sa', AmountUnit.unit, perKg: false, perMinute: false),
  mEqH('mEq/sa', AmountUnit.mEq, perKg: false, perMinute: false);

  const DoseUnit(
    this.label,
    this.amount, {
    required this.perKg,
    required this.perMinute,
  });

  final String label;
  final AmountUnit amount;
  final bool perKg;
  final bool perMinute;

  /// Bu birim, [bag] birimindeki bir torbayla hesaplanabilir mi.
  bool compatibleWith(AmountUnit bag) =>
      bag == amount || (bag.isMass && amount.isMass);
}

/// Sürekli infüzyon hesabı.
class Infusion {
  const Infusion({
    required this.amount,
    required this.amountUnit,
    required this.volumeMl,
    required this.unit,
    this.weightKg,
  });

  /// Torbadaki/enjektördeki toplam ilaç.
  final double amount;
  final AmountUnit amountUnit;
  final double volumeMl;
  final DoseUnit unit;
  final double? weightKg;

  bool get needsWeight => unit.perKg;

  bool get isValid =>
      amount > 0 &&
      volumeMl > 0 &&
      unit.compatibleWith(amountUnit) &&
      (!needsWeight || (weightKg ?? 0) > 0);

  /// Doz biriminin miktar cinsinden konsantrasyon (ör. µg/mL).
  double get concentration =>
      amountUnit.convert(amount, unit.amount) / volumeMl;

  double get _perHourFactor =>
      (unit.perKg ? weightKg! : 1) * (unit.perMinute ? 60 : 1);

  /// Verilen dozun pompa hızı (mL/sa).
  double rateFor(double dose) => dose * _perHourFactor / concentration;

  /// Verilen pompa hızının dozu.
  double doseFor(double rateMlH) => rateMlH * concentration / _perHourFactor;
}

/// İnfüzyonla verilen ilacın hazır bilgisi. Hazırlık bir örnektir;
/// kurumun standart konsantrasyonu girilmelidir.
class InfusionDrug {
  const InfusionDrug({
    required this.name,
    required this.unit,
    required this.prepAmount,
    required this.prepUnit,
    required this.prepVolume,
    this.asset,
    this.low,
    this.high,
    this.max,
    this.rangeNote = '',
    this.prepNote = '',
    this.warning = '',
  });

  final String name;

  /// İlaç rehberindeki sayfa (assets/content/ilac/ içinde).
  final String? asset;
  final DoseUnit unit;

  /// Olağan doz aralığı (doz biriminde).
  final double? low;
  final double? high;

  /// Bunun üstü kırmızı uyarı.
  final double? max;
  final String rangeNote;
  final double prepAmount;
  final AmountUnit prepUnit;
  final double prepVolume;
  final String prepNote;
  final String warning;

  String get rangeText {
    if (low == null && high == null) return rangeNote;
    final r = low == null
        ? 'en fazla ${formatNumber(high!)}'
        : '${formatNumber(low!)}–${formatNumber(high!)}';
    return '$r ${unit.label}${rangeNote.isEmpty ? '' : ' · $rangeNote'}';
  }

  String get prepText =>
      '${formatNumber(prepAmount)} ${prepUnit.label} / '
      '${formatNumber(prepVolume)} mL'
      '${prepNote.isEmpty ? '' : ' · $prepNote'}';
}

/// Sayıyı Türkçe ondalık virgülle, gereksiz sıfırsız yazar.
String formatNumber(double v, {int maxDecimals = 2}) {
  var s = v.toStringAsFixed(maxDecimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

/// Virgül veya noktalı sayıyı okur.
double? parseNumber(String s) =>
    double.tryParse(s.trim().replaceAll(' ', '').replaceAll(',', '.'));

const _ilac = 'assets/content/ilac/';

/// Sürekli infüzyon ilaçları. Aralıklar ilgili ilaç sayfasındaki
/// kaynaklarla uyumludur; hepsi taslaktır.
const infusionDrugs = <InfusionDrug>[
  InfusionDrug(
    name: 'Noradrenalin',
    asset: '${_ilac}noradrenalin.md',
    unit: DoseUnit.mcgKgMin,
    low: 0.05,
    high: 0.5,
    rangeNote: 'OAB hedefine göre titre',
    prepAmount: 4,
    prepUnit: AmountUnit.mg,
    prepVolume: 250,
    prepNote: '%5 dekstroz',
    warning: 'Yüksek riskli ilaç; santral hat tercih edilir, iki kişi kontrol.',
  ),
  InfusionDrug(
    name: 'Adrenalin (infüzyon)',
    asset: '${_ilac}adrenalin.md',
    unit: DoseUnit.mcgKgMin,
    low: 0.01,
    high: 0.5,
    prepAmount: 4,
    prepUnit: AmountUnit.mg,
    prepVolume: 250,
    warning: 'Arrest dozuyla (1 mg bolus) karıştırmayın.',
  ),
  InfusionDrug(
    name: 'Adrenalin (bradikardi)',
    asset: '${_ilac}adrenalin.md',
    unit: DoseUnit.mcgMin,
    low: 2,
    high: 10,
    rangeNote: 'yanıta göre titre',
    prepAmount: 1,
    prepUnit: AmountUnit.mg,
    prepVolume: 250,
  ),
  InfusionDrug(
    name: 'Dopamin',
    asset: '${_ilac}dopamin.md',
    unit: DoseUnit.mcgKgMin,
    low: 2,
    high: 20,
    rangeNote: 'bradikardide 5–20',
    prepAmount: 400,
    prepUnit: AmountUnit.mg,
    prepVolume: 250,
    warning: 'Damar dışına kaçarsa doku nekrozu; hattı sık kontrol edin.',
  ),
  InfusionDrug(
    name: 'Dobutamin',
    asset: '${_ilac}dobutamin.md',
    unit: DoseUnit.mcgKgMin,
    low: 2,
    high: 20,
    prepAmount: 250,
    prepUnit: AmountUnit.mg,
    prepVolume: 250,
  ),
  InfusionDrug(
    name: 'Nikardipin',
    asset: '${_ilac}nikardipin.md',
    unit: DoseUnit.mgH,
    low: 5,
    high: 15,
    max: 15,
    rangeNote: '5–15 dk\'da bir 2,5 mg/sa artır',
    prepAmount: 25,
    prepUnit: AmountUnit.mg,
    prepVolume: 250,
  ),
  InfusionDrug(
    name: 'Labetalol',
    asset: '${_ilac}labetalol.md',
    unit: DoseUnit.mgMin,
    low: 2,
    high: 8,
    prepAmount: 200,
    prepUnit: AmountUnit.mg,
    prepVolume: 200,
    warning: 'Bradikardi ve kalp bloğunda dikkat; nabız izlenir.',
  ),
  InfusionDrug(
    name: 'Amiodaron (idame)',
    asset: '${_ilac}amiodaron.md',
    unit: DoseUnit.mgMin,
    low: 0.5,
    high: 1,
    rangeNote: 'ilk 6 sa 1 mg/dk, sonraki 18 sa 0,5 mg/dk',
    prepAmount: 900,
    prepUnit: AmountUnit.mg,
    prepVolume: 500,
    prepNote: 'yalnızca %5 dekstroz',
  ),
  InfusionDrug(
    name: 'Nimodipin (IV)',
    asset: '${_ilac}nimodipin.md',
    unit: DoseUnit.mgH,
    low: 1,
    high: 2,
    rangeNote: '1 mg/sa başla, tolere edilirse 2 mg/sa',
    prepAmount: 10,
    prepUnit: AmountUnit.mg,
    prepVolume: 50,
    prepNote: 'hazır flakon, seyreltilmez, ışıktan korunur',
    warning: 'Hipotansiyonda hekime bildirin.',
  ),
  InfusionDrug(
    name: 'Midazolam (sedasyon)',
    asset: '${_ilac}midazolam.md',
    unit: DoseUnit.mgKgH,
    low: 0.02,
    high: 0.1,
    prepAmount: 50,
    prepUnit: AmountUnit.mg,
    prepVolume: 50,
  ),
  InfusionDrug(
    name: 'Midazolam (dirençli status)',
    asset: '${_ilac}midazolam.md',
    unit: DoseUnit.mgKgH,
    low: 0.05,
    high: 2,
    rangeNote: 'yükleme 0,2 mg/kg; EEG ile titre',
    prepAmount: 50,
    prepUnit: AmountUnit.mg,
    prepVolume: 50,
    warning: 'Yoğun bakımda, hava yolu güvencesiyle.',
  ),
  InfusionDrug(
    name: 'Propofol',
    asset: '${_ilac}propofol.md',
    unit: DoseUnit.mgKgH,
    low: 0.3,
    high: 3,
    max: 4,
    rangeNote: '5–50 µg/kg/dk',
    prepAmount: 500,
    prepUnit: AmountUnit.mg,
    prepVolume: 50,
    prepNote: '%1, seyreltilmez',
    warning: '4 mg/kg/sa üstü ve uzun süre: propofol infüzyon sendromu riski.',
  ),
  InfusionDrug(
    name: 'Deksmedetomidin',
    asset: '${_ilac}deksmedetomidin.md',
    unit: DoseUnit.mcgKgH,
    low: 0.2,
    high: 0.7,
    max: 1.4,
    prepAmount: 200,
    prepUnit: AmountUnit.mcg,
    prepVolume: 50,
    warning: 'Bradikardi ve hipotansiyon izlenir.',
  ),
  InfusionDrug(
    name: 'Fentanil',
    asset: '${_ilac}fentanil.md',
    unit: DoseUnit.mcgKgH,
    low: 0.7,
    high: 10,
    rangeNote: 'ağrı skoruna göre en düşük etkili doz',
    prepAmount: 500,
    prepUnit: AmountUnit.mcg,
    prepVolume: 50,
    warning: 'Solunum depresyonu; sedasyon ve solunum izlenir.',
  ),
  InfusionDrug(
    name: 'Morfin',
    asset: '${_ilac}morfin.md',
    unit: DoseUnit.mgH,
    low: 2,
    high: 30,
    rangeNote: 'ağrı skoruna göre en düşük etkili doz',
    prepAmount: 50,
    prepUnit: AmountUnit.mg,
    prepVolume: 50,
    warning: 'Solunum depresyonu; böbrek yetmezliğinde birikir.',
  ),
  InfusionDrug(
    name: 'Ketamin (analjezi)',
    asset: '${_ilac}ketamin.md',
    unit: DoseUnit.mgKgH,
    low: 0.1,
    high: 0.5,
    max: 1,
    prepAmount: 500,
    prepUnit: AmountUnit.mg,
    prepVolume: 50,
    warning: 'Ampul konsantrasyonları farklıdır (10 veya 50 mg/mL).',
  ),
  InfusionDrug(
    name: 'Heparin',
    asset: '${_ilac}heparin.md',
    unit: DoseUnit.unitKgH,
    low: 12,
    high: 18,
    rangeNote: 'aPTT/anti-Xa nomogramına göre',
    prepAmount: 25000,
    prepUnit: AmountUnit.unit,
    prepVolume: 500,
    warning: 'Yüksek riskli ilaç; kurum nomogramı ve iki kişi kontrolü.',
  ),
  InfusionDrug(
    name: 'İnsülin (regüler)',
    asset: '${_ilac}insulin.md',
    unit: DoseUnit.unitKgH,
    low: 0.05,
    high: 0.1,
    rangeNote: 'kan şekeri protokolüne göre',
    prepAmount: 50,
    prepUnit: AmountUnit.unit,
    prepVolume: 50,
    warning: '"ünite" tam yazılır; saatlik kan şekeri ve potasyum izlenir.',
  ),
  InfusionDrug(
    name: 'Furosemid',
    asset: '${_ilac}furosemid.md',
    unit: DoseUnit.mgH,
    low: 10,
    high: 40,
    rangeNote: 'dakikada 4 mg\'ı geçmeyin',
    prepAmount: 100,
    prepUnit: AmountUnit.mg,
    prepVolume: 100,
  ),
  InfusionDrug(
    name: 'Potasyum klorür',
    asset: '${_ilac}potasyum-klorur.md',
    unit: DoseUnit.mEqH,
    high: 10,
    max: 10,
    rangeNote: 'periferik yolda',
    prepAmount: 40,
    prepUnit: AmountUnit.mEq,
    prepVolume: 1000,
    warning:
        'Asla puşe yapılmaz; 10 mEq/sa üstü yalnızca santral hat + monitör.',
  ),
];

/// Kiloya göre yükleme dozu (status epileptikus ilaçları gibi).
class LoadingDrug {
  const LoadingDrug({
    required this.name,
    required this.mgPerKg,
    required this.defaultMinutes,
    required this.defaultVolume,
    this.asset,
    this.maxMg,
    this.maxMgPerMin,
    this.note = '',
  });

  final String name;
  final String? asset;
  final double mgPerKg;
  final double? maxMg;

  /// En yüksek veriliş hızı (ör. fenitoin 50 mg/dk).
  final double? maxMgPerMin;
  final int defaultMinutes;
  final double defaultVolume;
  final String note;

  double totalMg(double kg) {
    final t = mgPerKg * kg;
    return maxMg != null && t > maxMg! ? maxMg! : t;
  }

  /// Hız sınırına göre en kısa süre (dakika).
  double? minMinutes(double kg) =>
      maxMgPerMin == null ? null : totalMg(kg) / maxMgPerMin!;
}

const loadingDrugs = <LoadingDrug>[
  LoadingDrug(
    name: 'Levetirasetam',
    asset: '${_ilac}levetirasetam.md',
    mgPerKg: 60,
    maxMg: 4500,
    defaultMinutes: 15,
    defaultVolume: 100,
    note: '10–15 dakikada',
  ),
  LoadingDrug(
    name: 'Valproat',
    asset: '${_ilac}valproat.md',
    mgPerKg: 40,
    maxMg: 3000,
    defaultMinutes: 10,
    defaultVolume: 100,
    note: 'yaklaşık 10 dakikada',
  ),
  LoadingDrug(
    name: 'Fenitoin',
    asset: '${_ilac}fenitoin.md',
    mgPerKg: 20,
    maxMgPerMin: 50,
    defaultMinutes: 30,
    defaultVolume: 250,
    note: 'yalnızca serum fizyolojik, filtreli set; yaşlıda 25 mg/dk',
  ),
];

/// mL/sa hızını damla/dakikaya çevirir.
double dropsPerMinute(double mlPerHour, int dropFactor) =>
    mlPerHour * dropFactor / 60;

/// Belli hacmi belli sürede vermek için mL/sa.
double mlPerHour(double volumeMl, double minutes) => volumeMl * 60 / minutes;

List<InfusionDrug> infusionDrugsFor(String asset) => [
  for (final d in infusionDrugs)
    if (d.asset == asset) d,
];

LoadingDrug? loadingDrugFor(String asset) {
  for (final d in loadingDrugs) {
    if (d.asset == asset) return d;
  }
  return null;
}
