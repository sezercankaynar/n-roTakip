import 'package:flutter/material.dart';

/// Puanlanan bir klinik ölçeğin tanımı (her maddeden bir seçenek seçilir).
class ScaleItem {
  const ScaleItem(this.title, this.options, {this.help});

  final String title;
  final List<(int, String)> options;
  final String? help;
}

class ScaleBand {
  const ScaleBand(this.label, this.color, {this.advice});

  final String label;
  final Color color;

  /// Bu risk düzeyinde önerilenler.
  final String? advice;
}

class ScaleDefinition {
  const ScaleDefinition({
    required this.title,
    required this.items,
    required this.interpret,
    required this.sources,
    this.intro,
    this.footnote,
  });

  final String title;
  final List<ScaleItem> items;
  final ScaleBand Function(int total) interpret;
  final List<String> sources;
  final String? intro;
  final String? footnote;

  int get minTotal => items.fold(
    0,
    (s, i) => s + i.options.map((o) => o.$1).reduce((a, b) => a < b ? a : b),
  );

  int get maxTotal => items.fold(
    0,
    (s, i) => s + i.options.map((o) => o.$1).reduce((a, b) => a > b ? a : b),
  );
}

/// Morse Düşme Ölçeği (Morse ve ark., 1989).
final morseFallScale = ScaleDefinition(
  title: 'Morse Düşme Ölçeği',
  intro:
      'Yatışta, durum değiştiğinde ve kurumun belirlediği aralıklarla '
      'değerlendirilir. Risk eşikleri kurumdan kuruma değişebilir.',
  items: const [
    ScaleItem('Düşme öyküsü (son 3 ay veya bu yatışta)', [
      (0, 'Hayır'),
      (25, 'Evet'),
    ]),
    ScaleItem('İkincil tanı (birden fazla tıbbi tanı)', [
      (0, 'Hayır'),
      (15, 'Evet'),
    ]),
    ScaleItem('Yürümeye yardımcı', [
      (0, 'Yok / yatak istirahati / hemşire yardımıyla'),
      (15, 'Koltuk değneği, baston veya yürüteç'),
      (30, 'Mobilyaya tutunarak yürüyor'),
    ]),
    ScaleItem('IV tedavi / damar yolu (heparin kilidi dahil)', [
      (0, 'Hayır'),
      (20, 'Evet'),
    ]),
    ScaleItem('Yürüyüş / transfer', [
      (0, 'Normal / yatak istirahati / hareketsiz'),
      (10, 'Zayıf (öne eğik, kısa adımlar, destekle dengede)'),
      (20, 'Bozuk (kalkmakta zorlanıyor, dengesiz, desteğe tutunuyor)'),
    ]),
    ScaleItem('Mental durum', [
      (0, 'Kendi yürüme kapasitesinin farkında'),
      (15, 'Kısıtlılığını unutuyor veya abartıyor'),
    ]),
  ],
  interpret: (t) {
    if (t >= 45) {
      return const ScaleBand(
        'Yüksek risk (≥ 45)',
        Color(0xFFC62828),
        advice:
            'Standart önlemlere ek olarak yüksek risk önlemleri: işaret, '
            'sık gözetim, kalkışta refakat, tuvalet programı, ilaçların '
            'gözden geçirilmesi.',
      );
    }
    if (t >= 25) {
      return const ScaleBand(
        'Orta risk (25–44)',
        Color(0xFFEF6C00),
        advice:
            'Standart düşme önlemleri ve bireysel risklere yönelik '
            'önlemler.',
      );
    }
    return const ScaleBand(
      'Düşük risk (0–24)',
      Color(0xFF2E7D32),
      advice: 'Standart düşme önlemleri.',
    );
  },
  footnote:
      'Türkiye\'de birçok hastanede İtaki Düşme Riski Ölçeği kullanılır; '
      'kurumunuzun resmi formunu esas alın.',
  sources: const [
    'Morse JM, Morse RM, Tylko SJ. Development of a scale to identify the '
        'fall-prone patient. Can J Aging. 1989;8(4):366-377.',
    'Morse JM. Preventing Patient Falls: Establishing a Fall Intervention '
        'Program. 2nd ed. Springer; 2009.',
  ],
);

/// Norton Bası Yarası Risk Ölçeği (Norton ve ark., 1962).
final nortonScale = ScaleDefinition(
  title: 'Norton Bası Yarası Ölçeği',
  intro:
      'Her alanda hastanın durumuna en uygun seçenek işaretlenir. Puan '
      'düştükçe bası yarası riski artar.',
  items: const [
    ScaleItem('Fiziksel durum', [
      (4, 'İyi'),
      (3, 'Orta'),
      (2, 'Kötü'),
      (1, 'Çok kötü'),
    ]),
    ScaleItem('Mental durum', [
      (4, 'Uyanık'),
      (3, 'Apatik'),
      (2, 'Konfüze'),
      (1, 'Stupor / koma'),
    ]),
    ScaleItem('Aktivite', [
      (4, 'Yürüyor'),
      (3, 'Yardımla yürüyor'),
      (2, 'Tekerlekli sandalyeye bağımlı'),
      (1, 'Yatağa bağımlı'),
    ]),
    ScaleItem('Hareket', [
      (4, 'Tam'),
      (3, 'Hafif kısıtlı'),
      (2, 'Çok kısıtlı'),
      (1, 'Hareketsiz'),
    ]),
    ScaleItem('İnkontinans', [
      (4, 'Yok'),
      (3, 'Ara sıra'),
      (2, 'Genellikle idrar'),
      (1, 'İdrar ve gaita'),
    ]),
  ],
  interpret: (t) {
    if (t <= 12) {
      return const ScaleBand(
        'Yüksek risk (≤ 12)',
        Color(0xFFC62828),
        advice:
            'Basınç dağıtan yüzey, sık pozisyon değişimi, topukların '
            'kaldırılması, günlük cilt değerlendirmesi, beslenme desteği.',
      );
    }
    if (t <= 14) {
      return const ScaleBand(
        'Risk var (13–14)',
        Color(0xFFEF6C00),
        advice:
            'Bası yarası önleme planı: pozisyon değişimi, cilt bakımı, '
            'nemden koruma.',
      );
    }
    return const ScaleBand('Düşük risk (15–20)', Color(0xFF2E7D32));
  },
  footnote: 'Kurumunuzda Braden Ölçeği kullanılıyorsa resmi formu esas alın.',
  sources: const [
    'Norton D, McLaren R, Exton-Smith AN. An Investigation of Geriatric '
        'Nursing Problems in Hospital. London: National Corporation for the '
        'Care of Old People; 1962.',
    'European Pressure Ulcer Advisory Panel, National Pressure Injury '
        'Advisory Panel and Pan Pacific Pressure Injury Alliance. Prevention '
        'and Treatment of Pressure Ulcers/Injuries: The International '
        'Guideline. 2019.',
  ],
);
