// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import '../../features/habits/models/habit_item.dart';

Future<bool> requestWebPermission() async {
  try {
    final jsObj = js_util.getProperty(html.window, 'fitStackNotifications');
    if (jsObj != null) {
      final res = await js_util.promiseToFuture(
        js_util.callMethod(jsObj, 'requestPermission', []),
      );
      return res.toString() == 'granted';
    }
  } catch (_) {}

  try {
    final perm = await html.Notification.requestPermission();
    return perm == 'granted';
  } catch (_) {
    return false;
  }
}

String getWebPermissionState() {
  try {
    final jsObj = js_util.getProperty(html.window, 'fitStackNotifications');
    if (jsObj != null) {
      return js_util.callMethod(jsObj, 'getPermissionState', []).toString();
    }
  } catch (_) {}
  try {
    return html.Notification.permission ?? 'unsupported';
  } catch (_) {
    return 'unsupported';
  }
}

void scheduleWebReminder(HabitItem habit, int triggerTimestampMs) {
  try {
    final jsObj = js_util.getProperty(html.window, 'fitStackNotifications');
    if (jsObj != null) {
      final bodyText = 'Scheduled for ${habit.time ?? 'today'} (${habit.reminderMinutesBefore ?? 10}m before)';
      js_util.callMethod(jsObj, 'scheduleReminder', [
        habit.id,
        habit.title,
        bodyText,
        triggerTimestampMs,
      ]);
    }
  } catch (_) {}
}

void cancelWebReminder(String habitId) {
  try {
    final jsObj = js_util.getProperty(html.window, 'fitStackNotifications');
    if (jsObj != null) {
      js_util.callMethod(jsObj, 'cancelReminder', [habitId]);
    }
  } catch (_) {}
}

void showWebNotification(String title, String body, String tag) {
  try {
    final jsObj = js_util.getProperty(html.window, 'fitStackNotifications');
    if (jsObj != null) {
      js_util.callMethod(jsObj, 'showNotification', [title, body, tag, null]);
    }
  } catch (_) {}
}
