import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_entry.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    await _setLocalTimezone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings: settings);

    await requestPermission();
  }

  static Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> scheduleForTask(
    TaskEntry entry, {
    Duration reminderBefore = Duration.zero,
  }) async {
    if (entry.dateTime == null || entry.dateTime!.isBefore(DateTime.now())) {
      await showNotification(title: "Task added", body: entry.title);
      return;
    }

    final reminderTime = entry.dateTime!.subtract(reminderBefore);
    final scheduledTime = reminderTime.isAfter(DateTime.now())
        ? reminderTime
        : entry.dateTime!;

    await _notificationsPlugin.zonedSchedule(
      id: entry.id,
      title: "Reminder",
      body: reminderBefore == Duration.zero
          ? entry.title
          : "${entry.title} starts ${_durationLabel(reminderBefore)} later",
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  static Future<void> cancelForTask(TaskEntry entry) async {
    await _notificationsPlugin.cancel(id: entry.id);
  }

  static NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'assistant_channel',
          'Assistant Notifications',
          channelDescription: 'Notifications for Buddy',
          importance: Importance.high,
          priority: Priority.high,
        );

    return const NotificationDetails(android: androidDetails);
  }

  static String _durationLabel(Duration duration) {
    if (duration.inDays >= 1 && duration.inHours % 24 == 0) {
      return "${duration.inDays} day${duration.inDays == 1 ? "" : "s"}";
    }
    if (duration.inHours >= 1 && duration.inMinutes % 60 == 0) {
      return "${duration.inHours} hour${duration.inHours == 1 ? "" : "s"}";
    }
    return "${duration.inMinutes} minute${duration.inMinutes == 1 ? "" : "s"}";
  }

  static Future<void> _setLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation("UTC"));
    }
  }
}
