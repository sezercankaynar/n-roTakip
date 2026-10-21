/// NIH İnme Ölçeği (NIHSS) maddeleri.
///
/// Ölçek NINDS tarafından kamu kullanımına açıktır. Metinler resmi
/// talimatların Türkçe özetidir; kontrol durumu: taslak.
library;

class NihssOption {
  const NihssOption(this.score, this.label);

  /// Puan; `null` ise "UN" (değerlendirilemez: amputasyon, eklem füzyonu,
  /// entübasyon vb.). UN toplam puana 0 olarak katılır.
  final int? score;
  final String label;

  bool get isUntestable => score == null;
}

class NihssItem {
  const NihssItem({
    required this.code,
    required this.title,
    required this.instructions,
    required this.options,
    this.tip,
  });

  final String code;
  final String title;
  final String instructions;
  final List<NihssOption> options;
  final String? tip;

  int get maxScore =>
      options.map((o) => o.score ?? 0).reduce((a, b) => a > b ? a : b);
}

const nihssSources = [
  'National Institute of Neurological Disorders and Stroke (NINDS). '
      'NIH Stroke Scale.',
  'Brott T, Adams HP Jr, Olinger CP, et al. Measurements of acute cerebral '
      'infarction: a clinical examination scale. Stroke. 1989;20(7):864-870.',
  'Lyden P. Using the National Institutes of Health Stroke Scale: '
      'a cautionary tale. Stroke. 2017;48(2):513-519.',
];

const _armOptions = [
  NihssOption(
    0,
    'Düşme yok: kol 10 saniye boyunca 90° (veya 45°) '
    'pozisyonda kalıyor',
  ),
  NihssOption(
    1,
    'Düşme var: kol 10 saniye dolmadan aşağı iniyor ama yatağa '
    'veya bir desteğe değmiyor',
  ),
  NihssOption(
    2,
    'Yerçekimine karşı biraz çaba var: kol 90° (veya 45°) '
    'pozisyona gelemiyor ya da koruyamıyor, yatağa düşüyor',
  ),
  NihssOption(3, 'Yerçekimine karşı çaba yok: kol düşüyor'),
  NihssOption(4, 'Hiç hareket yok'),
  NihssOption(null, 'UN: Amputasyon veya eklem füzyonu'),
];

const _legOptions = [
  NihssOption(0, 'Düşme yok: bacak 5 saniye boyunca 30° pozisyonda kalıyor'),
  NihssOption(
    1,
    'Düşme var: bacak 5 saniye dolmadan aşağı iniyor ama yatağa '
    'değmiyor',
  ),
  NihssOption(
    2,
    'Yerçekimine karşı biraz çaba var: bacak 5 saniye içinde '
    'yatağa düşüyor',
  ),
  NihssOption(3, 'Yerçekimine karşı çaba yok: bacak hemen yatağa düşüyor'),
  NihssOption(4, 'Hiç hareket yok'),
  NihssOption(null, 'UN: Amputasyon veya eklem füzyonu'),
];

const _armInstructions =
    'Kol avuç içi aşağı bakacak şekilde uzatılır: '
    'oturuyorsa 90°, sırtüstü yatıyorsa 45°. 10 saniye tutması istenir. '
    'Her kol ayrı değerlendirilir; paretik olmayan koldan başlanır.';

const _legInstructions =
    'Hasta sırtüstü yatarken bacak 30° kaldırılır ve '
    '5 saniye tutması istenir. Her bacak ayrı değerlendirilir; paretik '
    'olmayan bacaktan başlanır.';

const nihssItems = <NihssItem>[
  NihssItem(
    code: '1a',
    title: 'Bilinç düzeyi',
    instructions:
        'Hastanın uyanıklığı değerlendirilir. Entübasyon, dil '
        'engeli veya orotrakeal travma gibi engeller olsa bile bir seçim '
        'yapılmalıdır.',
    options: [
      NihssOption(0, 'Uyanık, canlı yanıt veriyor'),
      NihssOption(
        1,
        'Uyanık değil; hafif uyaranla uyanıyor, emirlere uyuyor '
        'veya yanıt veriyor',
      ),
      NihssOption(
        2,
        'Uyanık değil; dikkatini sağlamak için tekrarlayan uyaran, '
        'hareket için güçlü veya ağrılı uyaran gerekiyor',
      ),
      NihssOption(
        3,
        'Yalnızca refleks motor veya otonom yanıt var ya da '
        'tamamen yanıtsız, flask ve arefleksik',
      ),
    ],
    tip:
        '1a = 3 puan alan (koma) hastada diğer maddeler resmi talimatlara '
        'göre puanlanır; çoğunda en yüksek puan verilir.',
  ),
  NihssItem(
    code: '1b',
    title: 'Bilinç düzeyi: sorular',
    instructions:
        'Hastaya içinde bulunulan ay ve yaşı sorulur. Yanıt tam '
        'doğru olmalıdır; yaklaşık yanıt doğru sayılmaz. İpucu verilmez, '
        'yalnızca ilk yanıt puanlanır.',
    options: [
      NihssOption(0, 'İki soruyu da doğru yanıtlıyor'),
      NihssOption(1, 'Bir soruyu doğru yanıtlıyor'),
      NihssOption(2, 'İki soruyu da yanlış yanıtlıyor'),
    ],
    tip:
        'Afazik veya stuporöz hasta: 2 puan. Entübasyon, ağır dizartri, '
        'dil engeli gibi afazi dışı nedenlerle konuşamayan hasta: 1 puan.',
  ),
  NihssItem(
    code: '1c',
    title: 'Bilinç düzeyi: emirler',
    instructions:
        'Hastadan gözlerini açıp kapatması, ardından paretik '
        'olmayan elini sıkıp bırakması istenir. Anlamazsa hareket gösterilerek '
        'taklit ettirilebilir. Yalnızca ilk deneme puanlanır.',
    options: [
      NihssOption(0, 'İki emri de doğru yapıyor'),
      NihssOption(1, 'Bir emri doğru yapıyor'),
      NihssOption(2, 'Hiçbir emri yapamıyor'),
    ],
  ),
  NihssItem(
    code: '2',
    title: 'En iyi bakış',
    instructions:
        'Yalnızca yatay göz hareketleri değerlendirilir. İstemli '
        'veya refleks (okülosefalik) hareketler puanlanır; kalorik test '
        'yapılmaz.',
    options: [
      NihssOption(0, 'Normal'),
      NihssOption(
        1,
        'Kısmi bakış felci: bir veya iki gözde bakış anormal, '
        'ancak zorlu deviasyon veya tam bakış parezisi yok',
      ),
      NihssOption(
        2,
        'Zorlu deviasyon veya okülosefalik manevrayla '
        'yenilemeyen tam bakış parezisi',
      ),
    ],
  ),
  NihssItem(
    code: '3',
    title: 'Görme alanı',
    instructions:
        'Görme alanları (üst ve alt kadranlar) karşılıklı '
        'oturarak, parmak sayma veya görsel tehdit ile test edilir.',
    options: [
      NihssOption(0, 'Görme kaybı yok'),
      NihssOption(1, 'Kısmi hemianopi'),
      NihssOption(2, 'Tam hemianopi'),
      NihssOption(3, 'Bilateral hemianopi (kortikal körlük dahil körlük)'),
    ],
  ),
  NihssItem(
    code: '4',
    title: 'Fasiyal parezi',
    instructions:
        'Hastadan dişlerini göstermesi, kaşlarını kaldırması ve '
        'gözlerini sıkıca kapatması istenir. Yanıt vermeyen hastada ağrılı '
        'uyarana yüz buruşturma simetrisine bakılır.',
    options: [
      NihssOption(0, 'Normal, simetrik hareket'),
      NihssOption(
        1,
        'Hafif paralizi: nazolabial olukta silinme, gülümsemede '
        'asimetri',
      ),
      NihssOption(2, 'Kısmi paralizi: alt yüzde tam veya tama yakın paralizi'),
      NihssOption(
        3,
        'Tam paralizi: bir veya iki tarafta üst ve alt yüzde '
        'hareket yok',
      ),
    ],
  ),
  NihssItem(
    code: '5a',
    title: 'Motor: sol kol',
    instructions: _armInstructions,
    options: _armOptions,
  ),
  NihssItem(
    code: '5b',
    title: 'Motor: sağ kol',
    instructions: _armInstructions,
    options: _armOptions,
  ),
  NihssItem(
    code: '6a',
    title: 'Motor: sol bacak',
    instructions: _legInstructions,
    options: _legOptions,
  ),
  NihssItem(
    code: '6b',
    title: 'Motor: sağ bacak',
    instructions: _legInstructions,
    options: _legOptions,
  ),
  NihssItem(
    code: '7',
    title: 'Ekstremite ataksisi',
    instructions:
        'Parmak-burun-parmak ve topuk-diz testleri iki tarafta '
        'gözler açıkken yapılır. Ataksi yalnızca güçsüzlükle açıklanamayacak '
        'kadar belirginse puanlanır.',
    options: [
      NihssOption(0, 'Ataksi yok'),
      NihssOption(1, 'Bir ekstremitede ataksi var'),
      NihssOption(2, 'İki ekstremitede ataksi var'),
      NihssOption(null, 'UN: Amputasyon veya eklem füzyonu'),
    ],
    tip:
        'Talimatı anlamayan veya paralizisi olan hastada ataksi 0 puan '
        'olarak kaydedilir.',
  ),
  NihssItem(
    code: '8',
    title: 'Duyu',
    instructions:
        'İğne ile ağrı duyusu veya ağrılı uyarana yüz buruşturma '
        've çekme yanıtı değerlendirilir. Yüz, kol (el değil), bacak ve gövde '
        'karşılaştırılır.',
    options: [
      NihssOption(0, 'Normal, duyu kaybı yok'),
      NihssOption(
        1,
        'Hafif-orta duyu kaybı: iğneyi daha az keskin hissediyor '
        'veya yalnızca dokunulduğunu fark ediyor',
      ),
      NihssOption(
        2,
        'Ağır veya tam duyu kaybı: yüz, kol ve bacakta dokunuşu '
        'hissetmiyor',
      ),
    ],
    tip:
        'Koma hastasında (1a = 3) ve iki taraflı duyu kaybında 2 puan '
        'verilir.',
  ),
  NihssItem(
    code: '9',
    title: 'En iyi dil',
    instructions:
        'Hastadan standart resmi tanımlaması, nesneleri '
        'adlandırması ve cümleleri okuması istenir. Önceki maddeler sırasında '
        'konuşma da değerlendirmeye katılır.',
    options: [
      NihssOption(0, 'Afazi yok, normal'),
      NihssOption(
        1,
        'Hafif-orta afazi: akıcılık veya anlamada belirgin kayıp '
        'var ama iletişim kurulabiliyor',
      ),
      NihssOption(
        2,
        'Ağır afazi: iletişim parçalı, dinleyici büyük ölçüde '
        'tahmin etmek zorunda',
      ),
      NihssOption(3, 'Sessiz, global afazi: konuşma veya işitsel anlama yok'),
    ],
    tip: 'Koma hastasında (1a = 3) 3 puan verilir.',
  ),
  NihssItem(
    code: '10',
    title: 'Dizartri',
    instructions:
        'Hastaya standart kelime listesi okutulur veya '
        'tekrarlatılır; konuşmanın anlaşılırlığı değerlendirilir.',
    options: [
      NihssOption(0, 'Normal'),
      NihssOption(
        1,
        'Hafif-orta dizartri: bazı kelimeleri peltek söylüyor, '
        'zorlukla da olsa anlaşılıyor',
      ),
      NihssOption(2, 'Ağır dizartri: anlaşılmıyor ya da konuşamıyor (anartri)'),
      NihssOption(null, 'UN: Entübasyon veya başka bir fiziksel engel'),
    ],
  ),
  NihssItem(
    code: '11',
    title: 'Sönme ve dikkatsizlik (ihmal)',
    instructions:
        'Önceki maddeler sırasında ihmal bulgularına dikkat edilir. '
        'İki taraflı eş zamanlı görsel ve dokunsal uyaranla sönme test edilir.',
    options: [
      NihssOption(0, 'Anormallik yok'),
      NihssOption(
        1,
        'Tek bir duyu modalitesinde (görsel, dokunsal, işitsel, '
        'uzaysal veya kişisel) dikkatsizlik ya da sönme',
      ),
      NihssOption(
        2,
        'Belirgin hemi-dikkatsizlik veya birden fazla modalitede '
        'sönme: kendi elini tanımıyor ya da uzayın yalnızca bir yanına '
        'yöneliyor',
      ),
    ],
  ),
];

/// Toplam puan. Seçilmemiş maddeler ve UN 0 sayılır.
int nihssTotal(Map<String, NihssOption> answers) =>
    answers.values.fold(0, (sum, o) => sum + (o.score ?? 0));

/// Sık kullanılan şiddet sınıflaması.
String nihssSeverity(int total) {
  if (total == 0) return 'İnme bulgusu yok';
  if (total <= 4) return 'Hafif inme';
  if (total <= 15) return 'Orta şiddette inme';
  if (total <= 20) return 'Orta-ağır inme';
  return 'Ağır inme';
}
