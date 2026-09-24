import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/habits/models/habit_item.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _hasPromptedPermission = false;
  bool get hasPromptedPermission => _hasPromptedPermission;

  /// Initialize local notification plugin and timezone database.
  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      debugPrint(
        '[NotificationService] Scheduled notifications are not supported on Flutter Web. '
        'Running in web preview mode.',
      );
      _isInitialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint(
            '[NotificationService] Notification tapped: ${response.payload}',
          );
        },
      );

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully.');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Explicitly requests notification permission from the user on first use.
  Future<bool> requestPermission(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scheduled alarms require the mobile (Android/iOS) or desktop app.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }

    _hasPromptedPermission = true;

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? granted =
            await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final bool? granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[NotificationService] Permission request error: $e');
    }

    return false;
  }

  /// Schedules a recurring daily local notification at (habit time - offset).
  Future<void> scheduleHabitReminder(HabitItem habit) async {
    if (kIsWeb) {
      debugPrint(
        '[NotificationService Web] Skipped native scheduling for: ${habit.title}',
      );
      return;
    }

    // Cancel existing reminder first to prevent duplicates
    await cancelHabitReminder(habit.id);

    final offset = habit.reminderMinutesBefore;
    final hour = habit.scheduledHour;
    final minute = habit.scheduledMinute;

    if (offset == null || offset <= 0 || hour == null || minute == null) {
      return;
    }

    try {
      // 1. Calculate exact reminder time: habit time minus offset
      final int totalHabitMinutes = (hour * 60) + minute;
      int totalReminderMinutes = totalHabitMinutes - offset;

      // Handle midnight wrap-around (e.g. 12:02 AM - 5 min -> 11:57 PM previous day)
      if (totalReminderMinutes < 0) {
        totalReminderMinutes += 24 * 60;
      }

      final int reminderHour = (totalReminderMinutes ~/ 60) % 24;
      final int reminderMinute = totalReminderMinutes % 60;

      // 2. Resolve local timezone DateTime
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminderHour,
        reminderMinute,
      );

      // If scheduled time has already passed today, advance to tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'fitstack_habit_reminders',
        'Habit Reminders',
        channelDescription: 'Notifications for scheduled daily habits and routines',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        _notificationId(habit.id),
        'Habit Reminder: ${habit.title}',
        'Scheduled in $offset minutes (${habit.time ?? ''})',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: habit.id,
      );

      debugPrint(
        '[NotificationService] Scheduled reminder for "${habit.title}" '
        'at $reminderHour:${reminderMinute.toString().padLeft(2, '0')} '
        '($offset min before ${habit.time})',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling habit reminder: $e');
    }
  }

  /// Cancels an existing habit reminder.
  Future<void> cancelHabitReminder(String habitId) async {
    if (kIsWeb) return;

    try {
      await _notificationsPlugin.cancel(_notificationId(habitId));
      debugPrint('[NotificationService] Cancelled reminder for: $habitId');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling reminder: $e');
    }
  }

  /// Converts a habit string ID into a consistent 32-bit positive integer notification ID.
  int _notificationId(String habitId) {
    return habitId.hashCode & 0x7fffffff;
  }
}
