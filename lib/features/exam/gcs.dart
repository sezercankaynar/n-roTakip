/// Glasgow Koma Skalası (Teasdale ve ark., 2014 güncel terimleri).
library;

class GcsOption {
  const GcsOption(this.score, this.label);

  /// `null`: değerlendirilemez (NT); ör. entübe hastada sözel yanıt.
  final int? score;
  final String label;
}

class GcsComponent {
  const GcsComponent(this.code, this.title, this.options, {this.ntCode});

  /// E, V veya M.
  final String code;
  final String title;
  final List<GcsOption> options;

  /// Değerlendirilemediğinde yazılan kısaltma (ör. sözel için "T").
  final String? ntCode;
}

const gcsComponents = [
  GcsComponent('E', 'Göz açma', [
    GcsOption(4, 'Kendiliğinden'),
    GcsOption(3, 'Sesle'),
    GcsOption(2, 'Basıyla (ağrılı uyaranla)'),
    GcsOption(1, 'Yok'),
    GcsOption(null, 'Değerlendirilemiyor (ör. göz kapağı ödemi)'),
  ], ntCode: 'NT'),
  GcsComponent('V', 'Sözel yanıt', [
    GcsOption(5, 'Yönelimi tam (isim, yer, zaman)'),
    GcsOption(4, 'Konfüze'),
    GcsOption(3, 'Uygunsuz kelimeler'),
    GcsOption(2, 'Anlamsız sesler'),
    GcsOption(1, 'Yok'),
    GcsOption(null, 'Değerlendirilemiyor (entübe / trakeostomi)'),
  ], ntCode: 'T'),
  GcsComponent('M', 'Motor yanıt', [
    GcsOption(6, 'Emirlere uyuyor'),
    GcsOption(5, 'Ağrıyı lokalize ediyor'),
    GcsOption(4, 'Normal fleksiyon (çekme)'),
    GcsOption(3, 'Anormal fleksiyon (dekortike)'),
    GcsOption(2, 'Ekstansiyon (deserebre)'),
    GcsOption(1, 'Yok'),
  ]),
];

class GcsResult {
  const GcsResult(this.answers);

  /// Bileşen koduna göre seçilen seçenek.
  final Map<String, GcsOption> answers;

  bool get complete => answers.length == gcsComponents.length;

  /// Değerlendirilemeyen bileşen varsa veya eksikse toplam verilmez.
  int? get total {
    if (!complete) return null;
    var sum = 0;
    for (final o in answers.values) {
      if (o.score == null) return null;
      sum += o.score!;
    }
    return sum;
  }

  /// "GKS 10 (E3 V3 M4)" veya "GKS: E3 VT M5".
  String summary() {
    final parts = [
      for (final c in gcsComponents)
        if (answers[c.code] case final o?)
          '${c.code}${o.score ?? c.ntCode}'
        else
          '${c.code}?',
    ].join(' ');
    final t = total;
    return t == null ? 'GKS: $parts' : 'GKS $t ($parts)';
  }

  String? get severity {
    final t = total;
    if (t == null) return null;
    if (t >= 13) return 'Hafif (13–15)';
    if (t >= 9) return 'Orta (9–12)';
    return 'Ağır (3–8): havayolu koruması değerlendirilir';
  }
}
