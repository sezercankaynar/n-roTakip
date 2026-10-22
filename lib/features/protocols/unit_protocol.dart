import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Protokol türü (listede süzme ve simge için).
enum ProtocolKind {
  flow('Akış şeması'),
  drugPrep('İlaç hazırlama'),
  regimen('Tedavi şeması'),
  checklist('Kontrol listesi'),
  note('Not');

  const ProtocolKind(this.label);

  final String label;

  static ProtocolKind byName(String? name) => ProtocolKind.values.firstWhere(
    (k) => k.name == name,
    orElse: () => ProtocolKind.note,
  );
}

/// Kullanıcının kendi ünitesi için yazdığı protokol veya not.
///
/// Metin, içerik sayfalarıyla aynı sade biçimi destekler (## başlık,
/// - madde, 1. numaralı adım, > uyarı kutusu, **kalın**, | tablo |).
class UnitProtocol {
  const UnitProtocol({
    required this.id,
    required this.title,
    required this.kind,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final ProtocolKind kind;
  final String body;
  final DateTime updatedAt;

  UnitProtocol copyWith({
    String? title,
    ProtocolKind? kind,
    String? body,
    DateTime? updatedAt,
  }) => UnitProtocol(
    id: id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'body': body,
    'updated': updatedAt.toIso8601String(),
  };

  factory UnitProtocol.fromJson(Map<String, Object?> j) => UnitProtocol(
    id: j['id']! as String,
    title: j['title']! as String,
    kind: ProtocolKind.byName(j['kind'] as String?),
    body: (j['body'] as String?) ?? '',
    updatedAt:
        DateTime.tryParse((j['updated'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Mesajla paylaşılacak düz metin. [parseShared] ile geri okunabilir.
  String toShareText() =>
      '$shareHeader\n'
      'Başlık: $title\n'
      'Tür: ${kind.label}\n'
      '---\n'
      '$body';

  static const shareHeader = '📝 NöroCep ünite protokolü';

  /// Paylaşılmış metni (veya düz bir notu) protokole çevirir.
  ///
  /// NöroCep biçimi tanınmazsa ilk satır başlık, kalanı metin olur.
  static UnitProtocol parseShared(String text, {required String id}) {
    final lines = text.replaceAll('\r\n', '\n').trim().split('\n');
    var title = '';
    var kind = ProtocolKind.note;
    var start = 0;
    final sep = lines.indexWhere((l) => l.trim() == '---');
    if (lines.isNotEmpty && lines.first.contains('NöroCep') && sep > 0) {
      for (final l in lines.sublist(1, sep)) {
        final m = RegExp(r'^(Başlık|Tür):\s*(.*)$').firstMatch(l.trim());
        if (m == null) continue;
        if (m.group(1) == 'Başlık') {
          title = m.group(2)!.trim();
        } else {
          final label = m.group(2)!.trim();
          kind = ProtocolKind.values.firstWhere(
            (k) => k.label == label,
            orElse: () => ProtocolKind.note,
          );
        }
      }
      start = sep + 1;
    } else if (lines.isNotEmpty) {
      title = lines.first.replaceFirst(RegExp(r'^#+\s*'), '').trim();
      start = 1;
    }
    return UnitProtocol(
      id: id,
      title: title.isEmpty ? 'İçe aktarılan protokol' : title,
      kind: kind,
      body: lines.sublist(start.clamp(0, lines.length)).join('\n').trim(),
      updatedAt: DateTime.now(),
    );
  }
}

/// Metinde kişisel veri olabilecek kalıpları bulur (uyarı içindir; kesin
/// değildir). Dönen liste kullanıcıya gösterilecek açıklamalardır.
List<String> personalDataWarnings(String text) {
  final found = <String>[];
  if (RegExp(r'(?<!\d)[1-9]\d{10}(?!\d)').hasMatch(text)) {
    found.add('11 haneli sayı (T.C. kimlik numarası olabilir)');
  }
  if (RegExp(r'(?<!\d)0?5\d{2}[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}(?!\d)')
      .hasMatch(text)) {
    found.add('cep telefonu numarası');
  }
  if (RegExp(
    r'\b(hasta adı|hastanın adı|protokol no|dosya no|TC|T\.C\.)\s*[:=]',
    caseSensitive: false,
  ).hasMatch(text)) {
    found.add('hasta kimlik alanı');
  }
  return found;
}

/// Protokolleri yalnızca bu telefonda saklar.
class UnitProtocolStore {
  static const _key = 'unit_protocols_v1';

  Future<List<UnitProtocol>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          UnitProtocol.fromJson((j as Map).cast<String, Object?>()),
      ];
    } on Object {
      return [];
    }
  }

  Future<void> save(List<UnitProtocol> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final p in items) p.toJson()]),
    );
  }
}

/// Yeni protokol için hazır iskeletler. İçerik ünitenin kendi talimatıyla
/// doldurulur; burada tıbbi bilgi değil yalnızca başlıklar vardır.
const protocolTemplates = <(String, ProtocolKind, String)>[
  ('Boş sayfa', ProtocolKind.note, ''),
  (
    'Akış şeması',
    ProtocolKind.flow,
    '> Ünitemizin onaylı talimatına göre doldurulmuştur.\n'
        '\n'
        '## Ne zaman başlatılır\n'
        '- \n'
        '\n'
        '## Adımlar\n'
        '1. 0. dakika: \n'
        '2. 5. dakika: \n'
        '3. 10. dakika: \n'
        '\n'
        '## Kime haber verilir\n'
        '- Nöbetçi hekim (dahili: )\n'
        '\n'
        '## Kayıt\n'
        '- ',
  ),
  (
    'İlaç hazırlama',
    ProtocolKind.drugPrep,
    '> Eczanemizin ve ünitemizin talimatına göre.\n'
        '\n'
        '## Ürün\n'
        '- Ticari ad / form: \n'
        '\n'
        '## Hazırlama\n'
        '1. Sulandırma: \n'
        '2. Seyreltme: \n'
        '3. Son konsantrasyon: \n'
        '\n'
        '## Uygulama\n'
        '- Yol ve hız: \n'
        '- Set / ışıktan koruma: \n'
        '\n'
        '## İzlem\n'
        '- \n'
        '\n'
        '## Saklama\n'
        '- Hazırlandıktan sonra dayanma süresi: ',
  ),
  (
    'Tedavi şeması',
    ProtocolKind.regimen,
    '> Hekim istemi olmadan uygulanmaz.\n'
        '\n'
        '## Endikasyon\n'
        '- \n'
        '\n'
        '## Şema\n'
        '| Gün / saat | İlaç | Doz | Not |\n'
        '|---|---|---|---|\n'
        '|  |  |  |  |\n'
        '\n'
        '## İzlem\n'
        '- ',
  ),
  (
    'Kontrol listesi',
    ProtocolKind.checklist,
    '## Hazırlık\n'
        '- [ ] \n'
        '- [ ] \n'
        '\n'
        '## Uygulama\n'
        '- [ ] \n'
        '\n'
        '## Sonrası\n'
        '- [ ] ',
  ),
];
