import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e, st) {
      logger.e(
        'Failed to initialize NotificationService',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleTaskReminder(
    int taskId,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        taskId,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Reminders for your tasks',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      logger.i('Scheduled notification for task $taskId at $scheduledDate');
    } catch (e, st) {
      logger.e('Failed to schedule notification', error: e, stackTrace: st);
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await _flutterLocalNotificationsPlugin.cancel(taskId);
    logger.i('Cancelled notification for task $taskId');
  }
}
