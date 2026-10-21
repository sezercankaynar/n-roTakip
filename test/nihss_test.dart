import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/nihss/nihss_items.dart';

void main() {
  test('15 madde ve maksimum 42 puan', () {
    expect(nihssItems.length, 15);
    expect(nihssItems.map((i) => i.code).toSet().length, 15);
    final max = nihssItems.fold<int>(0, (s, i) => s + i.maxScore);
    expect(max, 42);
  });

  test('UN toplama 0 olarak katılır', () {
    final answers = {for (final i in nihssItems) i.code: i.options.first};
    expect(nihssTotal(answers), 0);
    answers['5a'] = nihssItems
        .firstWhere((i) => i.code == '5a')
        .options
        .firstWhere((o) => o.isUntestable);
    answers['4'] = nihssItems.firstWhere((i) => i.code == '4').options[2];
    expect(nihssTotal(answers), 2);
  });

  test('şiddet sınıflaması sınırları', () {
    expect(nihssSeverity(0), 'İnme bulgusu yok');
    expect(nihssSeverity(4), 'Hafif inme');
    expect(nihssSeverity(5), 'Orta şiddette inme');
    expect(nihssSeverity(15), 'Orta şiddette inme');
    expect(nihssSeverity(16), 'Orta-ağır inme');
    expect(nihssSeverity(21), 'Ağır inme');
    expect(nihssSeverity(42), 'Ağır inme');
  });
}
