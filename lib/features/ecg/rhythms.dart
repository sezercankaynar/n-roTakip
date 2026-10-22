import 'package:flutter/material.dart';

import 'ecg_wave.dart';

/// Ritmin aciliyeti (kart rengi ve etiketi).
enum RhythmUrgency {
  arrestShock('ARREST · ŞOK VER', Color(0xFFC62828)),
  shockIfPulseless('NABIZ YOKSA ŞOK', Color(0xFFC62828)),
  arrestNoShock('ARREST · ŞOK YOK', Color(0xFFC62828)),
  urgent('ACİL · hekime hemen', Color(0xFFE65100)),
  report('Bildir · izle', Color(0xFF1565C0)),
  normal('Normal', Color(0xFF2E7D32));

  const RhythmUrgency(this.label, this.color);

  final String label;
  final Color color;
}

const _res = 'assets/content/resusitasyon/';

class Rhythm {
  const Rhythm({
    required this.name,
    required this.urgency,
    required this.signal,
    required this.rate,
    required this.regular,
    required this.p,
    required this.qrs,
    required this.recognize,
    required this.actions,
    this.aliases = '',
    this.page,
  });

  final String name;
  final String aliases;
  final RhythmUrgency urgency;
  final EcgSignal Function() signal;
  final String rate;
  final String regular;
  final String p;
  final String qrs;

  /// Tanımanın en kısa ipucu.
  final String recognize;

  /// Hemşirenin yapacakları.
  final List<String> actions;

  /// İlgili algoritma sayfası.
  final String? page;
}

final rhythms = <Rhythm>[
  Rhythm(
    name: 'Ventriküler fibrilasyon (VF)',
    aliases: 'VF',
    urgency: RhythmUrgency.arrestShock,
    signal: EcgSignal.vf,
    rate: 'Ölçülemez',
    regular: 'Tamamen düzensiz, kaotik',
    p: 'Yok',
    qrs: 'Yok; değişken dalgalar',
    recognize: 'Tanınabilir hiçbir kompleks yok, titrek kaotik çizgi.',
    actions: [
      'Önce hastaya bak: elektrot/kablo kopması VF\'ye benzeyebilir',
      'Yanıt ve nabız yoksa: Mavi Kod, KPR başlat',
      'Defibrilatör gelir gelmez ŞOK, hemen 2 dk KPR',
      'Adrenalin ve amiodaron şok sayısına göre (algoritma)',
    ],
    page: '${_res}kardiyak-arrest.md',
  ),
  Rhythm(
    name: 'Ventriküler taşikardi (VT)',
    aliases: 'VT, monomorfik',
    urgency: RhythmUrgency.shockIfPulseless,
    signal: EcgSignal.vt,
    rate: '> 100, genellikle 150–250',
    regular: 'Düzenli',
    p: 'Görülmez (varsa QRS\'ten bağımsız)',
    qrs: 'Geniş (≥ 0,12 sn), birbirine benzer',
    recognize: 'Hızlı, düzenli, geniş ve tek tip QRS kompleksleri.',
    actions: [
      'HEMEN nabız kontrol et',
      'Nabız yok → VF gibi: şok + KPR',
      'Nabız var, stabil değil → senkronize kardiyoversiyon',
      'Nabız var, stabil → hekim, 12 derivasyonlu EKG, amiodaron hazırlığı',
    ],
    page: '${_res}tasikardi.md',
  ),
  Rhythm(
    name: 'Polimorfik VT / Torsades de Pointes',
    aliases: 'Torsades, TdP',
    urgency: RhythmUrgency.shockIfPulseless,
    signal: EcgSignal.torsades,
    rate: '200–250',
    regular: 'Düzensiz',
    p: 'Yok',
    qrs: 'Geniş; boyu büyüyüp küçülerek eksen etrafında döner',
    recognize: 'QRS\'ler taban çizgisi etrafında "kurdele gibi" bükülür.',
    actions: [
      'Nabız yoksa: defibrilasyon (senkronsuz) + KPR',
      'Magnezyum sülfat 2 g IV hazırla',
      'QT uzatan ilaçları (haloperidol, ondansetron vb.) hekime bildir',
      'Potasyum ve magnezyum düzeyi',
    ],
    page: '${_res}tasikardi.md',
  ),
  Rhythm(
    name: 'Asistoli',
    urgency: RhythmUrgency.arrestNoShock,
    signal: EcgSignal.asystole,
    rate: '0',
    regular: '—',
    p: 'Yok (bazen yalnız P dalgaları)',
    qrs: 'Yok',
    recognize: 'Düz çizgi.',
    actions: [
      'Kablo ve pedleri, kazancı (gain) ve derivasyonu kontrol et',
      'KPR + adrenalin 1 mg en kısa sürede, 3–5 dk\'da bir',
      'ŞOK VERİLMEZ, atropin önerilmez',
      '4H 4T nedenlerini ara',
    ],
    page: '${_res}kardiyak-arrest.md',
  ),
  Rhythm(
    name: 'Nabızsız elektriksel aktivite (NEA)',
    aliases: 'PEA',
    urgency: RhythmUrgency.arrestNoShock,
    signal: () => EcgSignal.sinus(70),
    rate: 'Herhangi',
    regular: 'Herhangi (çoğu zaman düzenli)',
    p: 'Olabilir',
    qrs: 'Dar veya geniş',
    recognize: 'Monitörde ritim var ama NABIZ YOK. Ekrana değil hastaya bak.',
    actions: [
      'KPR + adrenalin 1 mg en kısa sürede, 3–5 dk\'da bir',
      'ŞOK VERİLMEZ',
      'Nedeni bul: hipovolemi, hipoksi, tamponad, tansiyon pnömotoraks, '
          'pulmoner emboli, hiperkalemi',
    ],
    page: '${_res}kardiyak-arrest.md',
  ),
  Rhythm(
    name: 'Tam (3. derece) AV blok',
    aliases: 'tam blok, AV blok',
    urgency: RhythmUrgency.urgent,
    signal: EcgSignal.completeBlock,
    rate: 'Ventrikül genellikle 20–40',
    regular: 'P\'ler düzenli, QRS\'ler düzenli ama birbirinden bağımsız',
    p: 'Var; QRS ile ilişkisiz',
    qrs: 'Sıklıkla geniş',
    recognize:
        'P dalgaları kendi hızında yürür, QRS\'ler kendi hızında; '
        'PR her seferinde farklı.',
    actions: [
      'Hekime hemen bildir, defibrilatör/pace hazır',
      'Bilinç, kan basıncı; belirti varsa bradikardi algoritması',
      'Atropin çoğu zaman etkisiz → transkutan pace',
    ],
    page: '${_res}bradikardi.md',
  ),
  Rhythm(
    name: '2. derece AV blok – Mobitz II',
    aliases: 'Mobitz 2',
    urgency: RhythmUrgency.urgent,
    signal: EcgSignal.mobitz2,
    rate: 'Genellikle yavaş',
    regular: 'Düşen atımlar nedeniyle düzensiz',
    p: 'Var; bazılarının ardından QRS gelmez',
    qrs: 'Dar veya geniş',
    recognize: 'PR hep aynı, sonra bir P\'den sonra QRS aniden düşer.',
    actions: [
      'Hekime bildir; tam bloğa ilerleyebilir',
      'Pace hazırlığı; belirti varsa bradikardi algoritması',
    ],
    page: '${_res}bradikardi.md',
  ),
  Rhythm(
    name: 'Supraventriküler taşikardi (SVT)',
    aliases: 'SVT, AVNRT',
    urgency: RhythmUrgency.urgent,
    signal: EcgSignal.svt,
    rate: '150–250',
    regular: 'Çok düzenli',
    p: 'Genellikle görülmez',
    qrs: 'Dar (< 0,12 sn)',
    recognize: 'Hızlı, saat gibi düzenli, dar QRS; P seçilemiyor.',
    actions: [
      'Stabil mi? (KB, bilinç, göğüs ağrısı)',
      '12 derivasyonlu EKG, damar yolu, hekime bildir',
      'Stabilse: vagal manevra, adenozin 6 mg hızlı puşe + 20 mL SF',
      'Stabil değilse: senkronize kardiyoversiyon',
    ],
    page: '${_res}tasikardi.md',
  ),
  Rhythm(
    name: 'ST elevasyonu (STEMI şüphesi)',
    aliases: 'STEMI, MI, kalp krizi',
    urgency: RhythmUrgency.urgent,
    signal: () => EcgSignal.sinus(80, stemi: true),
    rate: 'Herhangi',
    regular: 'Genellikle düzenli',
    p: 'Var',
    qrs: 'Normal; ardından ST segmenti taban çizgisinin üstünde',
    recognize:
        'QRS bitimindeki ST, taban çizgisinden yüksek ("kubbe" gibi). '
        'Tek derivasyondan karar verilmez.',
    actions: [
      '12 derivasyonlu EKG, hekime HEMEN göster',
      'Göğüs ağrısı, terleme, bulantı sorgula; yaşam bulguları',
      'Trombolitik almış inme hastasında ve SAK\'ta EKG değişikliği '
          'olabilir; karar hekimindir',
    ],
  ),
  Rhythm(
    name: 'Atriyal fibrilasyon (AF)',
    aliases: 'AF, AFib',
    urgency: RhythmUrgency.report,
    signal: EcgSignal.atrialFib,
    rate: 'Değişken (hızlı ventrikül yanıtında > 100)',
    regular: 'Tamamen düzensiz',
    p: 'Yok; taban çizgisi titrek (f dalgaları)',
    qrs: 'Dar',
    recognize: 'R–R aralıkları hep farklı ve P dalgası yok.',
    actions: [
      'Yeni AF ise 12 derivasyonlu EKG ile hekime bildir (inme nedeni olabilir)',
      'Hız > 110–120 veya belirti varsa taşikardi algoritması',
      'Antikoagülan ilaç ve kanama riskini hekimle değerlendir',
    ],
    page: '${_res}tasikardi.md',
  ),
  Rhythm(
    name: 'Atriyal flutter',
    aliases: 'flutter',
    urgency: RhythmUrgency.report,
    signal: EcgSignal.flutter,
    rate: 'Atriyum ~300; ventrikül sıklıkla 150 (2:1) veya 75 (4:1)',
    regular: 'Genellikle düzenli',
    p: 'Testere dişi F dalgaları',
    qrs: 'Dar',
    recognize:
        'Taban çizgisi testere dişi gibi; 150/dk düzenli ritimde '
        'flutter akla gelmeli.',
    actions: [
      '12 derivasyonlu EKG, hekime bildir',
      'Hızlıysa ve belirti varsa taşikardi algoritması',
    ],
    page: '${_res}tasikardi.md',
  ),
  Rhythm(
    name: '2. derece AV blok – Mobitz I (Wenckebach)',
    aliases: 'Wenckebach, Mobitz 1',
    urgency: RhythmUrgency.report,
    signal: EcgSignal.wenckebach,
    rate: 'Normal veya yavaş',
    regular: 'Gruplar halinde düzensiz',
    p: 'Var',
    qrs: 'Dar',
    recognize:
        'PR her atımda biraz uzar, sonunda bir QRS düşer, döngü '
        'yeniden başlar.',
    actions: [
      'Genellikle iyi huyludur; hekime bildir',
      'İlaçları gözden geçir (beta bloker, digoksin, deksmedetomidin)',
      'Belirti varsa bradikardi algoritması',
    ],
    page: '${_res}bradikardi.md',
  ),
  Rhythm(
    name: '1. derece AV blok',
    urgency: RhythmUrgency.report,
    signal: () => EcgSignal.sinus(70, pr: 0.32),
    rate: 'Normal',
    regular: 'Düzenli',
    p: 'Var, her P\'yi QRS izler',
    qrs: 'Dar',
    recognize:
        'PR aralığı uzun (> 0,20 sn = 1 büyük kare), ama hiç atım '
        'düşmüyor.',
    actions: ['Kayda geçir, hekime bildir; tek başına tedavi gerektirmez'],
  ),
  Rhythm(
    name: 'Ventriküler erken atım (VES)',
    aliases: 'VES, PVC, ekstrasistol',
    urgency: RhythmUrgency.report,
    signal: EcgSignal.pvc,
    rate: 'Altta yatan ritme göre',
    regular: 'Erken gelen atımlar nedeniyle düzensiz',
    p: 'Erken atımda yok',
    qrs: 'Erken atım geniş ve farklı şekilli',
    recognize: 'Beklenenden erken gelen geniş bir QRS, ardından duraklama.',
    actions: [
      'Sıklaşıyor, art arda geliyor (kuplet, VT atakları) ise hekime bildir',
      'Potasyum ve magnezyum düzeyine bak',
    ],
  ),
  Rhythm(
    name: 'Sinüs bradikardisi',
    aliases: 'bradikardi',
    urgency: RhythmUrgency.report,
    signal: () => EcgSignal.sinus(45),
    rate: '< 60',
    regular: 'Düzenli',
    p: 'Normal, her QRS önünde',
    qrs: 'Dar',
    recognize: 'Normal görünen ama yavaş ritim.',
    actions: [
      'Belirti var mı? (hipotansiyon, bilinç değişikliği)',
      'Nöroloji hastasında KİBAS (Cushing) açısından kan basıncı ve '
          'pupilleri değerlendir',
      'Belirti varsa bradikardi algoritması',
    ],
    page: '${_res}bradikardi.md',
  ),
  Rhythm(
    name: 'Sinüs taşikardisi',
    aliases: 'taşikardi',
    urgency: RhythmUrgency.report,
    signal: () => EcgSignal.sinus(125),
    rate: '100–150 (genellikle)',
    regular: 'Düzenli',
    p: 'Normal, her QRS önünde',
    qrs: 'Dar',
    recognize: 'Normal görünen ama hızlı ritim; P dalgaları seçilebiliyor.',
    actions: [
      'Nedeni ara: ağrı, ateş, hipovolemi, kanama, hipoksi, anksiyete, '
          'pulmoner emboli',
      'Nedene yönelik tedavi; ritmin kendisi şokla düzeltilmez',
    ],
  ),
  Rhythm(
    name: 'Normal sinüs ritmi',
    aliases: 'NSR, sinüs',
    urgency: RhythmUrgency.normal,
    signal: () => EcgSignal.sinus(75),
    rate: '60–100',
    regular: 'Düzenli',
    p: 'Her QRS önünde bir P',
    qrs: 'Dar (< 0,12 sn)',
    recognize: 'Düzenli; P → QRS → T sırası her atımda aynı.',
    actions: ['Karşılaştırma için referans ritim'],
  ),
];
