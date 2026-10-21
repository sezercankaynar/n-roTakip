/// Beyin damar haritasındaki damar ve bölgelerin bilgileri.
///
/// Belirti metinlerinde şu yer tutucular, dokunulan tarafa göre doldurulur:
/// - `{karşı}`: lezyonun karşı tarafı ("sağ", "sol" veya "karşı")
/// - `{aynı}`: lezyonla aynı taraf ("sol", "sağ" veya "aynı")
/// - `{aynıya}`: lezyon tarafına doğru ("sola", "sağa" veya "lezyon tarafına")
library;

enum Side {
  /// Hastanın sağı.
  right('Sağ'),

  /// Hastanın solu.
  left('Sol');

  const Side(this.label);

  final String label;
}

class VesselInfo {
  const VesselInfo({
    required this.abbr,
    required this.name,
    required this.supplies,
    required this.symptoms,
    this.leftSymptoms = const [],
    this.rightSymptoms = const [],
    this.notes = const [],
    this.midline = false,
  });

  /// Kısa ad (ör. "MCA").
  final String abbr;
  final String name;
  final String supplies;

  /// Her iki tarafta da görülen belirtiler (yer tutuculu).
  final List<String> symptoms;

  /// Yalnızca sol taraf (çoğu kişide dominant yarıküre) tutulumunda.
  final List<String> leftSymptoms;

  /// Yalnızca sağ taraf (çoğu kişide dominant olmayan yarıküre) tutulumunda.
  final List<String> rightSymptoms;

  /// Tedavi ve bakım açısından önemli notlar.
  final List<String> notes;

  /// Orta hatta tek damar (ör. baziler arter); taraf yoktur.
  final bool midline;

  String title(Side? side) =>
      midline || side == null ? '$abbr · $name' : '${side.label} $abbr · $name';

  /// Taraf yer tutucuları doldurulmuş belirtiler.
  List<String> resolvedSymptoms(Side? side) => [
    for (final s in symptoms) resolveSide(s, side),
  ];
}

String resolveSide(String text, Side? side) {
  final (karsi, ayni, ayniya) = switch (side) {
    Side.left => ('sağ', 'sol', 'sola'),
    Side.right => ('sol', 'sağ', 'sağa'),
    null => ('karşı', 'aynı', 'lezyon tarafına'),
  };
  final out = text
      .replaceAll('{karşı}', karsi)
      .replaceAll('{aynıya}', ayniya)
      .replaceAll('{aynı}', ayni);
  return out.isEmpty ? out : out[0].toUpperCase() + out.substring(1);
}

const vascularSources = [
  'Tatu L, Moulin T, Bogousslavsky J, Duvernoy H. Arterial territories of '
      'the human brain: cerebral hemispheres. Neurology. 1998;50(6):1699-1708.',
  'Tatu L, Moulin T, Bogousslavsky J, Duvernoy H. Arterial territories of '
      'human brain: brainstem and cerebellum. Neurology. 1996;47(5):1125-1135.',
  'Caplan LR. Caplan\'s Stroke: A Clinical Approach. 5th ed. Cambridge '
      'University Press; 2016.',
  'Kim JS. Pure lateral medullary infarction: clinical-radiological '
      'correlation of 130 acute, consecutive patients. Brain. '
      '2003;126(8):1864-1872.',
  'Powers WJ, Rabinstein AA, Ackerson T, et al. Guidelines for the Early '
      'Management of Patients With Acute Ischemic Stroke: 2019 Update. '
      'Stroke. 2019;50(12):e344-e418.',
];

const dominanceNote =
    'Sağ elini kullananların büyük çoğunluğunda (ve sol elini kullananların '
    'çoğunda) dil merkezi sol yarıküredir. Bu yüzden afazi genellikle sol, '
    'ihmal genellikle sağ yarıküre lezyonlarında görülür.';

/// Kesit görünümündeki bölgeler ve Willis poligonundaki damarlar.
enum Vessel {
  aca(
    VesselInfo(
      abbr: 'ACA',
      name: 'Anterior serebral arter',
      supplies:
          'Frontal ve parietal lobun iç (medial) yüzü, bacağın motor ve '
          'duyu alanı, korpus kallozumun ön kısmı.',
      symptoms: [
        '{karşı} bacakta belirgin güçsüzlük ve duyu kaybı (bacak koldan daha çok '
            'etkilenir, yüz genellikle korunur)',
        'İdrar kaçırma',
        'İsteksizlik, tepkisizlik (abuli), kişilik değişikliği',
        'Kavrama refleksi',
      ],
      leftSymptoms: [
        'Konuşmayı başlatmada güçlük, az konuşma (transkortikal motor afazi)',
      ],
      rightSymptoms: ['Dikkat ve davranış bozuklukları daha belirgin olabilir'],
    ),
  ),
  mca(
    VesselInfo(
      abbr: 'MCA',
      name: 'Orta serebral arter',
      supplies:
          'Frontal, parietal ve temporal lobun dış (lateral) yüzü: yüz ve '
          'kolun motor-duyu alanları, dil ve görme yolları. İnmelerin en sık '
          'görüldüğü alan.',
      symptoms: [
        '{karşı} yüz ve kolda belirgin güçsüzlük ve duyu kaybı (yüz ve kol '
            'bacaktan daha çok etkilenir)',
        '{karşı} tarafta görme alanı kaybı (homonim hemianopi)',
        'Gözlerde {aynıya} bakış deviasyonu (hasta lezyon tarafına bakar)',
        'Dizartri',
      ],
      leftSymptoms: [
        'Afazi: konuşamama, anlamama veya ikisi birden (global afazi)',
        'Okuma, yazma ve hesap yapma bozukluğu',
      ],
      rightSymptoms: [
        'Sol tarafı ihmal etme (hemi-ihmal): sol taraftaki kişi ve eşyaları '
            'fark etmeme',
        'Hastalığını kabul etmeme (anozognozi)',
        'Giyinme ve çizim güçlüğü (apraksi)',
      ],
      notes: [
        'MCA ana gövdesinin (M1) tıkanıklığı mekanik trombektominin en sık '
            'yapıldığı durumdur.',
        'Geniş MCA infarktında 2.–5. günlerde ciddi beyin ödemi gelişebilir: '
            'bilinçte azalma ve pupil değişikliği hemen bildirilmelidir.',
      ],
    ),
  ),
  pca(
    VesselInfo(
      abbr: 'PCA',
      name: 'Posterior serebral arter',
      supplies:
          'Oksipital lob (görme merkezi), temporal lobun alt-iç yüzü '
          '(bellek), talamus (derin dallarıyla).',
      symptoms: [
        '{karşı} tarafta görme alanı kaybı (homonim hemianopi); merkezi görme '
            'korunabilir',
        'Gördüğünü tanıyamama (görsel agnozi)',
        'Bellek bozukluğu (temporal lob tutulumunda)',
      ],
      leftSymptoms: [
        'Yazabildiği halde okuyamama (agrafisiz aleksi)',
        'Renkleri adlandıramama',
      ],
      rightSymptoms: ['Yüzleri tanıyamama, yön bulma güçlüğü'],
      notes: [
        'İki taraflı PCA tıkanıklığı kortikal körlüğe yol açar; hasta kör '
            'olduğunu fark etmeyebilir (Anton sendromu).',
      ],
    ),
  ),
  lenticulostriate(
    VesselInfo(
      abbr: 'Derin dallar',
      name: 'Lentikülostriat arterler (MCA dalları)',
      supplies:
          'Bazal ganglionlar ve iç kapsül (internal kapsül): motor '
          'yolların sıkıca geçtiği küçük ama kritik alan.',
      symptoms: [
        'Saf motor inme: {karşı} yüz, kol ve bacakta yaklaşık eşit güçsüzlük, '
            'duyu kaybı yok',
        'Dizartri ve elde beceriksizlik',
        'Afazi, ihmal ve görme alanı kaybı genellikle olmaz',
      ],
      notes: [
        'Küçük damar (laküner) inmelerin tipik yeridir; hipertansiyon ve '
            'diyabetle ilişkilidir.',
        'Hipertansif beyin kanamasının da en sık yeri burasıdır (putamen).',
      ],
    ),
  ),
  thalamus(
    VesselInfo(
      abbr: 'Talamus',
      name: 'Talamoperforan arterler (PCA dalları)',
      supplies:
          'Talamus: duyuların beyne aktarıldığı istasyon; bilinç ve '
          'bellekte de rol alır.',
      symptoms: [
        'Saf duyu inmesi: {karşı} yüz, kol ve bacakta uyuşma, his kaybı',
        'Haftalar sonra {karşı} tarafta yanıcı ağrı gelişebilir (talamik ağrı '
            'sendromu)',
        'Bilinç bulanıklığı, uyku hali, bellek sorunları',
      ],
      notes: [
        'İki taraflı paramedian talamus infarktı (Percheron arteri) ani '
            'bilinç bozukluğu ve göz hareket kısıtlılığıyla başlar; kolayca '
            'atlanabilir.',
      ],
    ),
  ),
  ica(
    VesselInfo(
      abbr: 'ICA',
      name: 'İnternal karotis arter',
      supplies:
          'Beynin ön dolaşımının ana kaynağı: ACA ve MCA\'yı verir; '
          'oftalmik arterle gözü besler.',
      symptoms: [
        'MCA ve ACA belirtileri birlikte: {karşı} tarafta yüz, kol ve bacakta '
            'güçsüzlük, görme alanı kaybı, bakış deviasyonu',
        '{aynı} gözde geçici veya kalıcı görme kaybı (amarozis fugaks)',
        'Diseksiyonda: boyun veya yüz ağrısı, {aynı} tarafta göz kapağı düşüklüğü '
            've küçük pupil (Horner sendromu)',
      ],
      leftSymptoms: ['Afazi'],
      rightSymptoms: ['Sol hemi-ihmal'],
      notes: [
        'İntrakraniyal ICA tıkanıklığı mekanik trombektomi için güçlü '
            'öneri alan durumlardandır.',
        'Karotis darlığı TİA ve inmenin önemli bir nedenidir.',
      ],
    ),
  ),
  m1(
    VesselInfo(
      abbr: 'M1',
      name: 'MCA ana gövdesi',
      supplies:
          'MCA\'nın tüm alanı ve derin dallar (bazal ganglion, iç kapsül).',
      symptoms: [
        'Tüm MCA belirtileri ağır biçimde: {karşı} yüz, kol (ve sıklıkla bacakta) '
            'güçsüzlük, duyu kaybı, görme alanı kaybı',
        'Gözlerde {aynıya} bakış deviasyonu',
      ],
      leftSymptoms: ['Global afazi'],
      rightSymptoms: ['Sol hemi-ihmal, anozognozi'],
      notes: [
        'Mekanik trombektomi için güçlü öneri: uygun hastada 6 saat, seçilmiş '
            'hastada 24 saate kadar.',
        'Ağır MCA belirtileri (NIHSS genellikle yüksek) büyük damar '
            'tıkanıklığını düşündürür.',
      ],
    ),
  ),
  m2(
    VesselInfo(
      abbr: 'M2',
      name: 'MCA üst ve alt dalları',
      supplies:
          'Üst dal: frontal lob ve motor alanlar. Alt dal: temporal ve '
          'parietal lob.',
      symptoms: [
        'Üst dal: {karşı} yüz ve kolda güçsüzlük',
        'Alt dal: {karşı} tarafta görme alanı kaybı, güçsüzlük daha hafif',
      ],
      leftSymptoms: [
        'Üst dal: konuşma akıcılığının bozulması, anladığı halde '
            'konuşamama (Broca afazisi)',
        'Alt dal: akıcı ama anlamsız konuşma, söyleneni anlamama (Wernicke '
            'afazisi)',
      ],
      rightSymptoms: ['Alt dal: sol hemi-ihmal, yön bulma güçlüğü'],
      notes: ['Seçilmiş M2 tıkanıklıklarında trombektomi değerlendirilebilir.'],
    ),
  ),
  a1a2(
    VesselInfo(
      abbr: 'ACA (A1/A2)',
      name: 'Anterior serebral arter segmentleri',
      supplies:
          'A1: ICA\'dan ön iletişim arterine kadar. A2: ön iletişim '
          'arterinden sonra, frontal lobun iç yüzüne.',
      symptoms: [
        '{karşı} bacakta belirgin güçsüzlük ve duyu kaybı',
        'İdrar kaçırma, isteksizlik, davranış değişikliği',
      ],
      notes: [
        'Ön iletişim arteri sayesinde tek taraflı A1 tıkanıklığı belirti '
            'vermeyebilir.',
      ],
    ),
  ),
  acomm(
    VesselInfo(
      abbr: 'AComm',
      name: 'Ön iletişim arteri',
      supplies:
          'İki ACA\'yı birbirine bağlar; bir taraf tıkanırsa diğer '
          'taraftan kan akımı sağlar.',
      symptoms: [
        'Tıkanıklığı genellikle belirti vermez',
        'Anevrizması patlarsa: ani, çok şiddetli baş ağrısı, ense sertliği, '
            'bilinç bozukluğu (subaraknoid kanama)',
      ],
      notes: [
        'Beyin anevrizmalarının en sık görüldüğü yerlerden biridir.',
        'Rüptür sonrası bellek ve davranış bozuklukları görülebilir.',
      ],
      midline: true,
    ),
  ),
  pcomm(
    VesselInfo(
      abbr: 'PComm',
      name: 'Arka iletişim arteri',
      supplies:
          'ICA ile PCA\'yı birbirine bağlar (ön ve arka dolaşım arasında '
          'köprü).',
      symptoms: [
        'Anevrizması 3. kraniyal sinire basabilir: {aynı} gözde pupil '
            'genişlemesi, göz kapağı düşüklüğü, gözün dışa-aşağı kayması',
        'Patlarsa subaraknoid kanama belirtileri',
      ],
      notes: [
        'Ani başlayan, ağrılı ve pupili tutan 3. sinir felci acil bir '
            'durumdur; hemen hekime bildirilir.',
      ],
    ),
  ),
  p1p2(
    VesselInfo(
      abbr: 'PCA (P1/P2)',
      name: 'Posterior serebral arter segmentleri',
      supplies:
          'P1: baziler arterden arka iletişim arterine kadar; orta beyin '
          've talamusa dallar verir. P2: oksipital ve temporal loba.',
      symptoms: [
        '{karşı} tarafta görme alanı kaybı',
        'P1 tutulumunda ek olarak: {karşı} tarafta duyu kaybı, göz hareket '
            'bozuklukları, bilinç bulanıklığı',
      ],
    ),
  ),
  basilar(
    VesselInfo(
      abbr: 'Baziler',
      name: 'Baziler arter',
      supplies:
          'Beyin sapı (pons, orta beyin), beyincik ve PCA\'lar aracılığıyla '
          'oksipital loblar ve talamus.',
      symptoms: [
        'Bilinç bozukluğu, koma',
        'Dört ekstremitede güçsüzlük (tetraparezi)',
        'Çift görme, göz hareketlerinde kısıtlılık, pupil anormallikleri',
        'Dizartri, yutma güçlüğü',
        'Baş dönmesi, bulantı-kusma, denge kaybı',
        'Kilitli kalma sendromu: bilinç açık, ancak yalnızca göz hareketleriyle '
            'iletişim kurabilir',
      ],
      notes: [
        'Belirtiler dalgalanabilir ve aniden ağırlaşabilir; ölüm oranı '
            'yüksektir.',
        'Seçilmiş hastalarda mekanik trombektomi yarar sağlar.',
        'Yutma güçlüğü sık görülür: yutma taraması yapılmadan ağızdan hiçbir '
            'şey verilmez.',
      ],
      midline: true,
    ),
  ),
  vertebral(
    VesselInfo(
      abbr: 'Vertebral',
      name: 'Vertebral arter',
      supplies:
          'Omurilik üst kısmı, medulla, beyinciğin alt kısmı (PICA ile); '
          'iki vertebral arter birleşerek baziler arteri oluşturur.',
      symptoms: [
        'PICA belirtileri (lateral medüller sendrom) görülebilir',
        'Diseksiyonda: ense ve başın arkasında ağrı, ardından beyin sapı veya '
            'beyincik belirtileri',
      ],
      notes: [
        'Boyun manipülasyonu veya travma sonrası diseksiyon genç inmelerin '
            'önemli bir nedenidir.',
      ],
    ),
  ),
  pica(
    VesselInfo(
      abbr: 'PICA',
      name: 'Arka alt serebellar arter',
      supplies: 'Medullanın dış kısmı ve beyinciğin alt kısmı.',
      symptoms: [
        'Lateral medüller (Wallenberg) sendrom:',
        '{aynı} yüzde, {karşı} gövde ve ekstremitelerde ağrı-ısı duyusu kaybı',
        '{aynı} tarafta göz kapağı düşüklüğü ve küçük pupil (Horner sendromu)',
        '{aynı} tarafta ataksi (koordinasyon bozukluğu)',
        'Yutma güçlüğü, ses kısıklığı, hıçkırık',
        'Baş dönmesi, bulantı-kusma, nistagmus',
        'Belirgin güçsüzlük genellikle olmaz',
      ],
      notes: [
        'Yutma güçlüğü ve aspirasyon riski yüksektir.',
        'Geniş serebellar infarktta ödem, beyin sapı basısı ve hidrosefali '
            'gelişebilir: bilinçte azalma acil bir durumdur.',
        'NIHSS bu hastalarda düşük çıkabilir; düşük puan hafif inme anlamına '
            'gelmez.',
      ],
    ),
  ),
  aica(
    VesselInfo(
      abbr: 'AICA',
      name: 'Ön alt serebellar arter',
      supplies: 'Pons alt-dış kısmı, beyinciğin ön-alt kısmı, iç kulak.',
      symptoms: [
        '{aynı} kulakta ani işitme kaybı, kulak çınlaması',
        '{aynı} tarafta yüz felci',
        '{aynı} tarafta ataksi',
        'Baş dönmesi, bulantı-kusma',
      ],
    ),
  ),
  sca(
    VesselInfo(
      abbr: 'SCA',
      name: 'Üst serebellar arter',
      supplies: 'Beyinciğin üst kısmı ve orta beynin bir bölümü.',
      symptoms: [
        '{aynı} tarafta kol ve bacakta koordinasyon bozukluğu (ataksi)',
        'Dizartri',
        'Baş dönmesi, bulantı, yürüme güçlüğü',
      ],
    ),
  );

  const Vessel(this.info);

  final VesselInfo info;
}
