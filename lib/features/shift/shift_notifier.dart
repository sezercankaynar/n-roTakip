import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../followup/follow_up_notifier.dart';
import 'shift.dart';

/// Vardiya işleri için zamanlanmış bildirimler.
abstract class ShiftNotifier {
  /// Bildirim izni ister; tam zamanlı alarm izni yoksa `false` döner.
  Future<bool> ensurePermissions();

  Future<void> schedule(ShiftTask t);

  Future<void> cancel(ShiftTask t);
}

/// İzlem bildirimleriyle çakışmasın diye vardiya işleri 1.000.000'dan
/// başlar; her iş iki numara kullanır (asıl zaman ve 10 dk önce).
int shiftNotificationId(ShiftTask t, {bool early = false}) =>
    1000000 + t.id * 2 + (early ? 1 : 0);

const earlyReminder = Duration(minutes: 10);

class LocalShiftNotifier implements ShiftNotifier {
  LocalShiftNotifier._();

  static final instance = LocalShiftNotifier._();

  // Eklenti tekildir; izlem bildirimleriyle aynı nesne kullanılır.
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'shift_tasks',
      'Vardiya işleri',
      channelDescription: 'Vardiya boyunca ilaç ve iş hatırlatmaları',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
  );

  Future<void> _init() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  Future<bool> _exact() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.canScheduleExactNotifications() ??
      false;

  @override
  Future<bool> ensurePermissions() =>
      LocalFollowUpNotifier.instance.ensurePermissions();

  @override
  Future<void> schedule(ShiftTask t) async {
    try {
      await _init();
      await cancel(t);
      if (t.isDone) return;
      final mode = await _exact()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      final now = DateTime.now();
      final where = t.bed.isEmpty ? '' : '${t.bedLabel} · ';
      final note = t.note.isEmpty ? '' : '\n${t.note}';
      if (t.at.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: shiftNotificationId(t),
          title: '${t.important ? '⚠ ' : ''}$where${t.title}',
          body: 'Saat ${hhmm(t.at)} · ${t.kind.label}$note',
          scheduledDate: tz.TZDateTime.from(t.at, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: mode,
        );
      }
      final early = t.at.subtract(earlyReminder);
      if (t.important && early.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: shiftNotificationId(t, early: true),
          title: '10 dk sonra: $where${t.title}',
          body: 'Saat ${hhmm(t.at)} · önemli iş, hazırlığa başlayın$note',
          scheduledDate: tz.TZDateTime.from(early, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: mode,
        );
      }
    } catch (e) {
      debugPrint('Vardiya bildirimi kurulamadı: $e');
    }
  }

  @override
  Future<void> cancel(ShiftTask t) async {
    try {
      await _init();
      await _plugin.cancel(id: shiftNotificationId(t));
      await _plugin.cancel(id: shiftNotificationId(t, early: true));
    } catch (e) {
      debugPrint('Vardiya bildirimi iptal edilemedi: $e');
    }
  }
}
