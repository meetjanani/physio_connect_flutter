import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local appointment reminders (T−24h and T−1h) on-device.
///
/// Requires AndroidManifest receivers + POST_NOTIFICATIONS / exact-alarm
/// permissions (see android/app/src/main/AndroidManifest.xml).
class AppointmentReminderService {
  AppointmentReminderService._();
  static final AppointmentReminderService instance =
      AppointmentReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'session_reminders';
  static const _channelName = 'Session reminders';

  Future<void> ensureInitialized() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    await _configureLocalTimeZone();

    // Drawable/mipmap name without extension. Prefer launcher icon.
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create channel early (Android 8+).
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Upcoming physiotherapy session alerts',
        importance: Importance.high,
      ),
    );

    await requestPermissions();
    _ready = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
      if (kDebugMode) {
        print('[Reminder] Local timezone = $name');
      }
    } catch (e) {
      // Fallback so scheduling still works if timezone name lookup fails.
      tz.setLocalLocation(tz.UTC);
      if (kDebugMode) {
        print('[Reminder] Timezone fallback to UTC: $e');
      }
    }
  }

  /// Ask for notification + exact-alarm permissions (Android 13 / 14+).
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notifOk =
        await android?.requestNotificationsPermission() ?? false;
    // Opens system screen for exact alarms when needed (Android 12+ / 14).
    await android?.requestExactAlarmsPermission();
    if (kDebugMode) {
      print('[Reminder] notificationsGranted=$notifOk');
    }
    return notifOk;
  }

  /// Schedule reminders for a session at T−24h, T−1h, and a few test offsets.
  /*await AppointmentReminderService.instance.scheduleSessionReminders(
  bookingId: 99999,
  sessionStart: DateTime.now().add(const Duration(minutes: 1)),
  sessionLabel: 'Manual reminder test',
  );*/
  Future<void> scheduleSessionReminders({
    required int bookingId,
    required DateTime sessionStart,
    required String sessionLabel,
    bool includeJoinSoon = false,
  }) async {
    await ensureInitialized();

    final reminders = <Duration, String>{
      const Duration(hours: 24): 'Tomorrow: $sessionLabel',
      const Duration(hours: 12): 'Reminder of Upcoming Appointment: $sessionLabel',
      const Duration(hours: 2): 'Today: $sessionLabel',
      const Duration(hours: 1): 'Starting soon: $sessionLabel',
      const Duration(minutes: 30): 'Starting soon: $sessionLabel',
      // const Duration(seconds: 20): 'Starting soon 20: $sessionLabel',
    };

    for (final entry in reminders.entries) {
      final whenLocal = sessionStart.subtract(entry.key);
      if (whenLocal.isBefore(DateTime.now())) {
        if (kDebugMode) {
          print(
            '[Reminder] Skip past alarm booking=$bookingId '
            'offset=${entry.key} when=$whenLocal',
          );
        }
        continue;
      }

      final scheduled = tz.TZDateTime.from(whenLocal, tz.local);
      final id = _notificationId(bookingId, entry.key.inHours);

      await _plugin.zonedSchedule(
        id,
        'PhysioConnect reminder',
        entry.value,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Upcoming physiotherapy session alerts',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      if (kDebugMode) {
        print(
          '[Reminder] Scheduled id=$id at $scheduled '
          '(local now=${tz.TZDateTime.now(tz.local)})',
        );
      }
    }

    if (includeJoinSoon) {
      final whenLocal = sessionStart.subtract(const Duration(minutes: 15));
      if (!whenLocal.isBefore(DateTime.now())) {
        await _plugin.zonedSchedule(
          bookingId * 10 + 9,
          'Join your online session',
          'Your PhysioConnect Google Meet starts in 15 minutes. Open the app to Join.',
          tz.TZDateTime.from(whenLocal, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: 'Upcoming physiotherapy session alerts',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  int _notificationId(int bookingId, int hoursOffset) =>
      bookingId * 10 + hoursOffset;
}
