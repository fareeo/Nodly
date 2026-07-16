import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import 'settings_service.dart';
import 'storage_service.dart';

/// Handles periodic task-reminder notifications.
///
/// Singleton – access via `NotificationService()`.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 0;
  static const String _channelId = 'nodly_reminders';
  static const String _channelName = 'Nodly Reminders';
  static const String _channelDesc = 'Periodic reminders for your daily tasks';

  bool _initialised = false;

  // ── Initialisation ─────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _initialised = true;
  }

  // ── Permission ─────────────────────────────────────────────────────────

  /// Requests notification permission on Android 13+ (API 33+).
  /// Returns true if granted or already granted.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;

    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Schedule / Cancel ──────────────────────────────────────────────────

  /// Schedules (or reschedules) the periodic reminder based on current
  /// settings and today's tasks.
  Future<void> scheduleReminder() async {
    final settings = SettingsService();
    if (!settings.notificationsEnabled) {
      await cancelReminder();
      return;
    }

    // Ask for permission if not already granted
    final granted = await requestPermission();
    if (!granted) return;

    // Build notification body from today's tasks
    final body = await _buildNotificationBody();
    if (body == null) {
      // No tasks today – cancel any existing notification
      await cancelReminder();
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    final details = NotificationDetails(android: androidDetails);
    final periodMinutes = settings.notificationPeriodMinutes < 1
        ? 60
        : settings.notificationPeriodMinutes;

    // Cancel existing before rescheduling
    await _plugin.cancel(_notificationId);

    try {
      await _plugin.periodicallyShowWithDuration(
        _notificationId,
        'Nodly Reminder',
        body,
        Duration(minutes: periodMinutes),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling periodic notification: $e');
    }
  }

  /// Cancels the periodic reminder.
  Future<void> cancelReminder() async {
    await _plugin.cancel(_notificationId);
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Builds a summary string from today's tasks.
  /// Returns null if there are no tasks.
  Future<String?> _buildNotificationBody() async {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final items = await StorageService.loadItems(todayKey);
    if (items.isEmpty) return null;

    final count = items.length;
    final firstTask = items.first.text;

    if (count == 1) {
      return firstTask;
    }
    // Truncate first task if too long
    final truncated = firstTask.length > 60
        ? '${firstTask.substring(0, 57)}...'
        : firstTask;
    return 'You have $count tasks: $truncated';
  }
}
