import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Schedules and cancels the daily reminder notifications for habits.
///
/// Each habit gets one notification per active weekday, repeating weekly at
/// the habit's reminder time (`habit.id.hashCode` combined with the weekday
/// keeps the notification ids stable and unique across habits).
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit reminders';
  static const _channelDescription = 'Daily nudges to complete your habits';
  static const _enabledPrefKey = 'habitforge_notifications_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledPrefKey) ?? true;
  }

  /// Persists the master toggle and immediately schedules or cancels every
  /// habit's reminders to match.
  static Future<void> setEnabled(bool enabled, List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledPrefKey, enabled);
    if (enabled) {
      await resyncAll(habits);
    } else {
      await cancelAll();
    }
  }

  /// Re-schedules reminders for every habit, honoring the master toggle.
  static Future<void> resyncAll(List<Habit> habits) async {
    final enabled = await isEnabled();
    for (final habit in habits) {
      await syncForHabit(habit, enabled: enabled);
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Fall back to UTC if the device timezone name isn't in the database —
      // schedules still fire at the right wall-clock time via TZDateTime.from.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.defaultImportance,
        ));

    _initialized = true;
  }

  /// Requests the runtime notification permission (Android 13+ / iOS).
  /// Returns `true` if granted (or not required on this platform).
  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return granted ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? true;
    }
    return true;
  }

  /// Cancels any existing reminders for [habit] and, if it has one configured
  /// and reminders are [enabled], schedules a fresh weekly-repeating set.
  static Future<void> syncForHabit(Habit habit, {required bool enabled}) async {
    await cancelForHabit(habit);
    if (!enabled || !habit.hasReminder || habit.isArchived) return;

    final body = "Time for ${habit.emoji} ${habit.name} — keep your streak alive!";
    for (final weekday in habit.activeDays) {
      await _plugin.zonedSchedule(
        _notificationId(habit.id, weekday),
        'HabitForge reminder',
        body,
        _nextInstanceOfWeekdayTime(weekday, habit.reminderHour!, habit.reminderMinute!),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> cancelForHabit(Habit habit) async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_notificationId(habit.id, weekday));
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static int _notificationId(String habitId, int weekday) =>
      (habitId.hashCode & 0x7FFFFFF) * 10 + weekday;

  static tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
