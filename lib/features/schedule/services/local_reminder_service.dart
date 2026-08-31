import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

abstract interface class ReminderScheduler {
  Future<bool> requestPermission();
  Future<void> sync(ReminderSetting reminder);
  Future<void> cancel(String reminderId);
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (_) => LocalReminderService(FlutterLocalNotificationsPlugin()),
);

class LocalReminderService implements ReminderScheduler {
  LocalReminderService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(zone.identifier));
    } catch (_) {
      timezone.setLocalLocation(timezone.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
    }
    return true;
  }

  @override
  Future<void> sync(ReminderSetting reminder) async {
    await _initialize();
    await cancel(reminder.id);
    if (!reminder.enabled) return;
    for (final day in reminder.repeatDays) {
      await _plugin.zonedSchedule(
        id: _notificationId(reminder.id, day),
        title: reminder.type.label,
        body: _bodyFor(reminder.type),
        scheduledDate: _nextOccurrence(day, reminder.time),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'caloris_habits',
            'Pengingat kebiasaan',
            channelDescription: 'Pengingat makanan, air, dan aktivitas Caloris',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder:${reminder.id}',
      );
    }
  }

  @override
  Future<void> cancel(String reminderId) async {
    await _initialize();
    for (var day = 1; day <= 7; day++) {
      await _plugin.cancel(id: _notificationId(reminderId, day));
    }
  }

  timezone.TZDateTime _nextOccurrence(int day, LocalTime time) {
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (scheduled.weekday != day || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _notificationId(String id, int day) {
    final compact = id.replaceAll('-', '');
    final prefix = compact.length >= 6
        ? int.tryParse(compact.substring(0, 6), radix: 16)
        : null;
    return ((prefix ?? id.hashCode).abs() % 10000000) * 10 + day;
  }

  String _bodyFor(ReminderType type) => switch (type) {
    ReminderType.water => 'Luangkan waktu sejenak untuk minum air.',
    ReminderType.walk || ReminderType.activity =>
      'Aktivitas ringan bisa menjadi pilihan jika kondisi memungkinkan.',
    ReminderType.weighIn => 'Catat berat secara konsisten, tanpa menghakimi.',
    ReminderType.sleep => 'Saatnya bersiap beristirahat.',
    ReminderType.foodLog =>
      'Catat makanan agar ringkasan harian tetap lengkap.',
    _ => 'Pengingat ${type.label.toLowerCase()} dari Caloris.',
  };
}
