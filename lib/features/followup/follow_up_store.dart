import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'follow_up.dart';

/// İzlemleri cihazda saklar (yalnızca bu telefonda; internete gönderilmez).
class FollowUpStore {
  static const _key = 'followups_v1';

  Future<List<FollowUp>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          FollowUp.fromJson((j as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      // Bozuk kayıt uygulamayı kilitlemesin.
      return [];
    }
  }

  Future<void> save(List<FollowUp> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final f in items) f.toJson()]),
    );
  }

  /// Kullanılmamış en küçük kimlik (bildirim numaraları bundan türetilir).
  static int nextId(List<FollowUp> items) {
    final used = {for (final f in items) f.id};
    var id = 1;
    while (used.contains(id)) {
      id++;
    }
    return id;
  }
}
