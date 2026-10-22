/// Erişkin laboratuvar referans aralıkları ve kritik değerler.
///
/// Değerler yaygın kaynaklardaki erişkin aralıklarıdır; her laboratuvarın
/// kendi referansı ve kurumun kritik değer listesi esastır.
library;

enum LabGroup {
  chemistry('Biyokimya ve elektrolit'),
  blood('Hemogram'),
  coag('Koagülasyon'),
  gas('Arter kan gazı'),
  drugLevel('İlaç düzeyleri'),
  csf('Beyin omurilik sıvısı (BOS)');

  const LabGroup(this.label);

  final String label;
}

enum LabLevel { criticalLow, low, normal, high, criticalHigh }

class LabTest {
  const LabTest({
    required this.name,
    required this.group,
    required this.unit,
    required this.low,
    required this.high,
    this.critLow,
    this.critHigh,
    this.rangeText,
    this.aliases = const [],
    this.note = '',
    this.decimals = 1,
  });

  final String name;
  final LabGroup group;
  final String unit;
  final double low;
  final double high;
  final double? critLow;
  final double? critHigh;

  /// Aralık farklı yazılacaksa (ör. cinsiyete göre).
  final String? rangeText;
  final List<String> aliases;

  /// Hemşire için kısa not: neye dikkat, ne yapılır.
  final String note;
  final int decimals;

  LabLevel classify(double v) {
    if (critLow != null && v < critLow!) return LabLevel.criticalLow;
    if (critHigh != null && v > critHigh!) return LabLevel.criticalHigh;
    if (v < low) return LabLevel.low;
    if (v > high) return LabLevel.high;
    return LabLevel.normal;
  }

  String get normalText => rangeText ?? '${_f(low)}–${_f(high)}';

  String? get criticalText {
    final parts = [
      if (critLow != null) '< ${_f(critLow!)}',
      if (critHigh != null) '> ${_f(critHigh!)}',
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  String _f(double v) {
    var s = v.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s.replaceAll('.', ',');
  }
}

const labTests = <LabTest>[
  // Biyokimya ve elektrolit
  LabTest(
    name: 'Sodyum (Na)',
    group: LabGroup.chemistry,
    unit: 'mmol/L',
    low: 135,
    high: 145,
    critLow: 120,
    critHigh: 160,
    decimals: 0,
    note:
        'Bilinç değişikliği ve nöbet yapabilir. Düşük sodyum 24 saatte en '
        'fazla 8–10 mmol/L yükseltilir (osmotik demiyelinizasyon riski). '
        'SAK\'ta hiponatremi sıktır; sıvı kısıtlaması yapılmaz, hekime '
        'bildirilir.',
  ),
  LabTest(
    name: 'Potasyum (K)',
    group: LabGroup.chemistry,
    unit: 'mmol/L',
    low: 3.5,
    high: 5.0,
    critLow: 2.8,
    critHigh: 6.2,
    note:
        'Kritik düzeyde aritmi riski: monitör, EKG. Hemolizli örnek yalancı '
        'yüksek çıkabilir, tekrarlanır. KCl asla puşe yapılmaz.',
  ),
  LabTest(
    name: 'Glukoz',
    group: LabGroup.chemistry,
    unit: 'mg/dL',
    low: 70,
    high: 100,
    critLow: 50,
    critHigh: 400,
    decimals: 0,
    aliases: ['kan şekeri', 'şeker'],
    note:
        'Normal aralık açlık değeridir. İnme taklitçisi olabilir: < 50 ise '
        'trombolitik öncesi düzeltilir. Akut inmede hedef genellikle '
        '140–180 mg/dL.',
  ),
  LabTest(
    name: 'Kalsiyum (total)',
    group: LabGroup.chemistry,
    unit: 'mg/dL',
    low: 8.5,
    high: 10.5,
    critLow: 6.5,
    critHigh: 13,
    aliases: ['Ca'],
    note: 'Albümin düşükse total kalsiyum yanıltıcıdır; iyonize kalsiyum istenir.',
  ),
  LabTest(
    name: 'Magnezyum (Mg)',
    group: LabGroup.chemistry,
    unit: 'mg/dL',
    low: 1.7,
    high: 2.4,
    critLow: 1.0,
    critHigh: 4.9,
    note: 'Düşük magnezyum aritmi (torsades) ve nöbet riskini artırır.',
  ),
  LabTest(
    name: 'Fosfor',
    group: LabGroup.chemistry,
    unit: 'mg/dL',
    low: 2.5,
    high: 4.5,
    critLow: 1.0,
    note: 'Uzun açlık sonrası beslenme başlanınca düşebilir (refeeding).',
  ),
  LabTest(
    name: 'Kreatinin',
    group: LabGroup.chemistry,
    unit: 'mg/dL',
    low: 0.6,
    high: 1.2,
    rangeText: 'Kadın 0,5–1,1 · Erkek 0,7–1,3',
    note:
        'Kontrastlı tetkik, vankomisin, enoksaparin ve birçok ilaç dozu '
        'böbrek işlevine göre ayarlanır.',
  ),
  LabTest(
    name: 'Üre / BUN',
    group: LabGroup.chemistry,
    unit: 'mg/dL',
    low: 7,
    high: 20,
    decimals: 0,
    rangeText: 'BUN 7–20 (üre ≈ BUN × 2,14)',
    aliases: ['BUN', 'üre'],
  ),
  LabTest(
    name: 'Laktat',
    group: LabGroup.chemistry,
    unit: 'mmol/L',
    low: 0.5,
    high: 2.0,
    critHigh: 4.0,
    note: 'Yükselmesi doku perfüzyon bozukluğu, sepsis veya nöbet sonrası olabilir.',
  ),
  LabTest(
    name: 'Albümin',
    group: LabGroup.chemistry,
    unit: 'g/dL',
    low: 3.5,
    high: 5.0,
    note: 'Düşükse fenitoin ve kalsiyum düzeyleri yanıltıcı olabilir; bası yarası riski artar.',
  ),
  LabTest(
    name: 'CRP',
    group: LabGroup.chemistry,
    unit: 'mg/L',
    low: 0,
    high: 5,
    decimals: 0,
    rangeText: '< 5',
    note: 'Bazı laboratuvarlar mg/dL kullanır (< 0,5); birimi kontrol edin.',
  ),
  // Hemogram
  LabTest(
    name: 'Hemoglobin',
    group: LabGroup.blood,
    unit: 'g/dL',
    low: 12,
    high: 17.5,
    critLow: 7,
    critHigh: 20,
    rangeText: 'Kadın 12–16 · Erkek 13,5–17,5',
    aliases: ['Hb', 'Hgb'],
    note: 'Ani düşüş kanama düşündürür (antikoagülan, trombolitik sonrası).',
  ),
  LabTest(
    name: 'Lökosit (WBC)',
    group: LabGroup.blood,
    unit: '×10³/µL',
    low: 4,
    high: 10,
    critLow: 2,
    critHigh: 30,
    aliases: ['WBC', 'beyaz küre'],
  ),
  LabTest(
    name: 'Trombosit',
    group: LabGroup.blood,
    unit: '×10³/µL',
    low: 150,
    high: 400,
    critLow: 20,
    critHigh: 1000,
    decimals: 0,
    aliases: ['PLT'],
    note:
        '< 100 ×10³/µL trombolitik tedavi için kontrendikasyondur. Heparin '
        'alan hastada %50\'den fazla düşüş HIT düşündürür.',
  ),
  LabTest(
    name: 'Mutlak nötrofil (ANC)',
    group: LabGroup.blood,
    unit: '×10³/µL',
    low: 1.5,
    high: 7.5,
    critLow: 0.5,
    aliases: ['nötrofil', 'ANC'],
    note: '< 0,5 nötropeni: koruyucu önlemler, ateşte hemen bildir.',
  ),
  // Koagülasyon
  LabTest(
    name: 'INR',
    group: LabGroup.coag,
    unit: '',
    low: 0.8,
    high: 1.2,
    critHigh: 5,
    note:
        '> 1,7 trombolitik tedavi için kontrendikasyondur. Varfarinle hedef '
        'genellikle 2–3.',
  ),
  LabTest(
    name: 'aPTT',
    group: LabGroup.coag,
    unit: 'sn',
    low: 25,
    high: 35,
    critHigh: 100,
    decimals: 0,
    note: 'Heparin infüzyonunda kurum nomogramına göre izlenir.',
  ),
  LabTest(
    name: 'PT',
    group: LabGroup.coag,
    unit: 'sn',
    low: 11,
    high: 13.5,
    aliases: ['protrombin zamanı'],
  ),
  LabTest(
    name: 'Fibrinojen',
    group: LabGroup.coag,
    unit: 'mg/dL',
    low: 200,
    high: 400,
    critLow: 100,
    decimals: 0,
    note: 'Trombolitik sonrası kanamada istenir; düşükse kriyopresipitat gerekebilir.',
  ),
  // Kan gazı
  LabTest(
    name: 'pH',
    group: LabGroup.gas,
    unit: '',
    low: 7.35,
    high: 7.45,
    critLow: 7.2,
    critHigh: 7.6,
    decimals: 2,
  ),
  LabTest(
    name: 'PaCO₂',
    group: LabGroup.gas,
    unit: 'mmHg',
    low: 35,
    high: 45,
    critLow: 20,
    critHigh: 70,
    decimals: 0,
    aliases: ['pCO2', 'CO2'],
    note: 'Yüksek PaCO₂ kafa içi basıncını artırır; KİBAS hastasında önemli.',
  ),
  LabTest(
    name: 'PaO₂',
    group: LabGroup.gas,
    unit: 'mmHg',
    low: 80,
    high: 100,
    critLow: 40,
    decimals: 0,
    aliases: ['pO2', 'oksijen'],
  ),
  LabTest(
    name: 'HCO₃⁻',
    group: LabGroup.gas,
    unit: 'mmol/L',
    low: 22,
    high: 26,
    critLow: 10,
    critHigh: 40,
    decimals: 0,
    aliases: ['bikarbonat', 'HCO3'],
  ),
  // İlaç düzeyleri
  LabTest(
    name: 'Fenitoin (total)',
    group: LabGroup.drugLevel,
    unit: 'µg/mL',
    low: 10,
    high: 20,
    critHigh: 30,
    decimals: 0,
    note:
        'Albümin düşükse total düzey düşük görünür ama serbest düzey '
        'yüksek olabilir. Nistagmus, ataksi, uyku hali toksisite belirtisi.',
  ),
  LabTest(
    name: 'Valproat',
    group: LabGroup.drugLevel,
    unit: 'µg/mL',
    low: 50,
    high: 100,
    critHigh: 150,
    decimals: 0,
    note: 'Bilinç bulanıklığında amonyak da istenebilir.',
  ),
  LabTest(
    name: 'Karbamazepin',
    group: LabGroup.drugLevel,
    unit: 'µg/mL',
    low: 4,
    high: 12,
    critHigh: 15,
    decimals: 0,
  ),
  LabTest(
    name: 'Digoksin',
    group: LabGroup.drugLevel,
    unit: 'ng/mL',
    low: 0.5,
    high: 2.0,
    critHigh: 2.0,
    note:
        'Toksisitede bulantı, görme bozukluğu, bradikardi; potasyumu da bakın.',
  ),
  // BOS
  LabTest(
    name: 'BOS açılış basıncı',
    group: LabGroup.csf,
    unit: 'cmH₂O',
    low: 6,
    high: 20,
    critHigh: 25,
    decimals: 0,
    aliases: ['lomber ponksiyon', 'LP'],
    note: 'Yan yatarak, bacaklar gevşek ölçülür.',
  ),
  LabTest(
    name: 'BOS lökosit',
    group: LabGroup.csf,
    unit: '/µL',
    low: 0,
    high: 5,
    decimals: 0,
    rangeText: '0–5 (mononükleer)',
    note: 'Artış menenjit/ensefalit düşündürür; örnek hemen laboratuvara.',
  ),
  LabTest(
    name: 'BOS protein',
    group: LabGroup.csf,
    unit: 'mg/dL',
    low: 15,
    high: 45,
    decimals: 0,
    note: 'Guillain-Barré\'de hücre artışı olmadan protein yükselir.',
  ),
  LabTest(
    name: 'BOS glukoz',
    group: LabGroup.csf,
    unit: 'mg/dL',
    low: 40,
    high: 70,
    decimals: 0,
    rangeText: '40–70 (kan şekerinin yaklaşık %60\'ı)',
    note:
        'BOS/kan glukozu oranı < 0,4 bakteriyel menenjiti düşündürür; kan '
        'şekeri aynı anda alınır.',
  ),
];

/// Nöroloji hastasında akılda tutulacak sınırlar.
const neuroLimits = <(String, String)>[
  (
    'Trombolitik öncesi',
    'Glukoz < 50 mg/dL ise önce düzeltilir · Trombosit < 100.000/µL, '
        'INR > 1,7 veya aPTT uzunsa (heparin almışsa) kontrendikasyon',
  ),
  ('Akut inmede glukoz', 'Hedef 140–180 mg/dL; hipoglisemiden kaçınılır'),
  (
    'Sodyum düzeltme hızı',
    'Kronik hiponatremide ilk 24 saatte en fazla 10, sonraki her 24 saatte '
        'en fazla 8 mmol/L artış',
  ),
  (
    'Subaraknoid kanama',
    'Hiponatremi sıktır (tuz kaybı); sıvı kısıtlaması yapılmaz, sodyum '
        'günlük izlenir',
  ),
  (
    'Hipertonik salin (KİBAS)',
    'Sodyum kurum protokolündeki hedefte tutulur; > 160 mmol/L kritik',
  ),
];

/// Hesaplanmış küçük yardımcılar.
double correctedCalcium(double total, double albumin) =>
    total + 0.8 * (4 - albumin);

double sodiumChange(double previous, double current) => current - previous;
