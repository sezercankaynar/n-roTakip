import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'follow_up.dart';

/// İzlem kontrolleri için zamanlanmış bildirimler.
abstract class FollowUpNotifier {
  /// Bildirim izni ister. Tam zamanlı alarm izni yoksa `false` döner
  /// (bildirimler birkaç dakika gecikebilir).
  Future<bool> ensurePermissions();

  /// Bu izlemin gelecekteki tüm kontrolleri için bildirim kurar.
  Future<void> schedule(FollowUp f);

  Future<void> cancel(FollowUp f);

  /// Tam zamanlı alarm izni var mı.
  Future<bool> canScheduleExact();
}

/// Her izlem en fazla 100 bildirim numarası kullanır: id*100 + kontrol sırası.
int notificationId(FollowUp f, int checkIndex) => f.id * 100 + checkIndex;

class LocalFollowUpNotifier implements FollowUpNotifier {
  LocalFollowUpNotifier._();

  static final instance = LocalFollowUpNotifier._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _exact = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'followup_checks',
      'İzlem kontrolleri',
      channelDescription:
          'Trombolitik/trombektomi sonrası nörolojik kontrol hatırlatmaları',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _init() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> ensurePermissions() async {
    try {
      await _init();
      await _android?.requestNotificationsPermission();
      _exact = await _android?.canScheduleExactNotifications() ?? false;
      if (!_exact) {
        await _android?.requestExactAlarmsPermission();
        _exact = await _android?.canScheduleExactNotifications() ?? false;
      }
      return _exact;
    } catch (e) {
      debugPrint('Bildirim izni alınamadı: $e');
      return false;
    }
  }

  @override
  Future<bool> canScheduleExact() async {
    try {
      await _init();
      _exact = await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      _exact = false;
    }
    return _exact;
  }

  @override
  Future<void> schedule(FollowUp f) async {
    try {
      await _init();
      final now = DateTime.now();
      for (var i = 0; i < f.total; i++) {
        final at = f.timeOf(i);
        if (!at.isAfter(now) || f.done[i] != null) continue;
        await _plugin.zonedSchedule(
          id: notificationId(f, i),
          title: 'Nörolojik kontrol zamanı · ${f.label}',
          body:
              '${i + 1}/${f.total}. kontrol · ${phaseOf(i).label}. '
              'Bilinç, pupiller, motor güç, kan basıncı.',
          // Mutlak an olarak UTC'de zamanlanır; saat dilimi gerekmez.
          scheduledDate: tz.TZDateTime.from(at, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: _exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Bildirim kurulamadı: $e');
    }
  }

  @override
  Future<void> cancel(FollowUp f) async {
    try {
      await _init();
      for (var i = 0; i < f.total; i++) {
        await _plugin.cancel(id: notificationId(f, i));
      }
    } catch (e) {
      debugPrint('Bildirim iptal edilemedi: $e');
    }
  }
}
