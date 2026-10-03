import '../../features/habits/models/habit_item.dart';

Future<bool> requestWebPermission() async => false;
String getWebPermissionState() => 'unsupported';
void scheduleWebReminder(HabitItem habit, int triggerTimestampMs) {}
void cancelWebReminder(String habitId) {}
void showWebNotification(String title, String body, String tag) {}
