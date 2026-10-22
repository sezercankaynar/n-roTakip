import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Kurumun acil durum kodu (kullanıcı düzenleyebilir).
class EmergencyCode {
  const EmergencyCode({
    required this.name,
    required this.colorValue,
    this.extension = '',
    this.description = '',
  });

  final String name;
  final int colorValue;

  /// Hastane içi dahili numara.
  final String extension;
  final String description;

  EmergencyCode copyWith({
    String? name,
    String? extension,
    String? description,
  }) => EmergencyCode(
    name: name ?? this.name,
    colorValue: colorValue,
    extension: extension ?? this.extension,
    description: description ?? this.description,
  );

  Map<String, Object> toJson() => {
    'name': name,
    'color': colorValue,
    'ext': extension,
    'desc': description,
  };

  factory EmergencyCode.fromJson(Map<String, Object?> j) => EmergencyCode(
    name: j['name']! as String,
    colorValue: j['color']! as int,
    extension: (j['ext'] as String?) ?? '',
    description: (j['desc'] as String?) ?? '',
  );
}

const defaultEmergencyCodes = [
  EmergencyCode(
    name: 'Mavi Kod',
    colorValue: 0xFF1565C0,
    description: 'Kardiyopulmoner arrest, acil tıbbi müdahale',
  ),
  EmergencyCode(
    name: 'Pembe Kod',
    colorValue: 0xFFD81B60,
    description: 'Bebek veya çocuk kaçırılması',
  ),
  EmergencyCode(
    name: 'Beyaz Kod',
    colorValue: 0xFF757575,
    description: 'Sağlık çalışanına yönelik şiddet',
  ),
  EmergencyCode(
    name: 'Kırmızı Kod',
    colorValue: 0xFFC62828,
    description: 'Kuruma göre (ör. yangın)',
  ),
];

/// Kodları cihazda saklar.
class EmergencyCodeStore {
  static const _key = 'emergency_codes_v1';

  Future<List<EmergencyCode>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [...defaultEmergencyCodes];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          EmergencyCode.fromJson((j as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      return [...defaultEmergencyCodes];
    }
  }

  Future<void> save(List<EmergencyCode> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final c in codes) c.toJson()]),
    );
  }
}
