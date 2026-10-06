import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../model/bookings_model.dart';

/// Schedules local appointment reminders (T−24h and T−1h) on-device.
///
/// Exact-alarm / notification permission is requested only from in-app
/// opt-in UI — never at process start.
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

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

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
      tz.setLocalLocation(tz.UTC);
      if (kDebugMode) {
        print('[Reminder] Timezone fallback to UTC: $e');
      }
    }
  }

  /// True when notifications (and Android exact alarms) are already allowed.
  /// Never opens a system settings screen.
  Future<bool> hasPermissions() async {
    await ensureInitialized();
    if (!Platform.isAndroid) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      return options?.isEnabled == true ||
          options?.isProvisionalEnabled == true;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notifOk = await android?.areNotificationsEnabled() ?? true;
    final exactOk = await android?.canScheduleExactNotifications() ?? true;
    return notifOk && exactOk;
  }

  /// User-initiated prompt. Android 12+ may open Alarms & reminders settings.
  Future<bool> requestPermissions() async {
    await ensureInitialized();
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
    await android?.requestNotificationsPermission();
    final exactOk = await android?.canScheduleExactNotifications() ?? true;
    if (!exactOk) {
      await android?.requestExactAlarmsPermission();
    }
    return hasPermissions();
  }

  Future<void> scheduleRemindersForBookings(List<BookingsModel> bookings) async {
    if (!await hasPermissions()) {
      if (kDebugMode) {
        print('[Reminder] Skip scheduling — permission not granted');
      }
      return;
    }

    for (final booking in bookings) {
      try {
        final date = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
        var slotTime = '09:00';
        var sessionName = 'Physio session';
        try {
          slotTime = booking.aTimeslot().time;
          sessionName = booking.aSessionType().name;
        } catch (_) {}
        await scheduleSessionReminders(
          bookingId: booking.id,
          sessionStart: combineDateAndSlot(date, slotTime),
          sessionLabel: booking.isOnlineSession
              ? '$sessionName — join from the app'
              : sessionName,
          includeJoinSoon: booking.isOnlineSession,
        );
      } catch (e) {
        if (kDebugMode) {
          print('[Reminder] Failed booking=${booking.id}: $e');
        }
      }
    }
  }

  /// Schedule reminders for a session. No-ops when permission is missing.
  Future<void> scheduleSessionReminders({
    required int bookingId,
    required DateTime sessionStart,
    required String sessionLabel,
    bool includeJoinSoon = false,
  }) async {
    await ensureInitialized();
    if (!await hasPermissions()) {
      if (kDebugMode) {
        print('[Reminder] Skip alarms booking=$bookingId — no permission');
      }
      return;
    }

    final reminders = <Duration, String>{
      const Duration(hours: 24): 'Tomorrow: $sessionLabel',
      const Duration(hours: 12):
          'Reminder of Upcoming Appointment: $sessionLabel',
      const Duration(hours: 2): 'Today: $sessionLabel',
      const Duration(hours: 1): 'Starting soon: $sessionLabel',
      const Duration(minutes: 30): 'Starting soon: $sessionLabel',
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
      await _zonedSchedule(
        id: id,
        title: 'PhysioConnect reminder',
        body: entry.value,
        scheduled: scheduled,
      );
    }

    if (includeJoinSoon) {
      final whenLocal = sessionStart.subtract(const Duration(minutes: 15));
      if (!whenLocal.isBefore(DateTime.now())) {
        await _zonedSchedule(
          id: bookingId * 10 + 9,
          title: 'Join your online session',
          body:
              'Your PhysioConnect Google Meet starts in 15 minutes. Open the app to Join.',
          scheduled: tz.TZDateTime.from(whenLocal, tz.local),
        );
      }
    }
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduled,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
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
    } catch (e) {
      if (kDebugMode) {
        print('[Reminder] Could not schedule id=$id: $e');
      }
    }
  }

  static DateTime combineDateAndSlot(DateTime date, String slotTime) {
    final cleaned = slotTime.trim().toUpperCase();
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?').firstMatch(cleaned);
    var hour = 9;
    var minute = 0;
    if (match != null) {
      hour = int.tryParse(match.group(1) ?? '9') ?? 9;
      minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final ampm = match.group(3);
      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  int _notificationId(int bookingId, int hoursOffset) =>
      bookingId * 10 + hoursOffset;
}
