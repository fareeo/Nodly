import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

    // Initialize timezone database (required for zonedSchedule)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_resolveLocalTimezone()));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialised = true;
  }

  /// Resolve local timezone name for the tz library.
  String _resolveLocalTimezone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      // Try to match by offset; fallback to UTC
      for (final location in tz.timeZoneDatabase.locations.values) {
        final tzNow = tz.TZDateTime.now(location);
        if (tzNow.timeZoneOffset == offset) {
          return location.name;
        }
      }
    } catch (_) {}
    return 'UTC';
  }

  /// Called when user taps on a notification.
  void _onNotificationTap(NotificationResponse response) {
    // App is opened automatically by the system; no extra action needed.
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

  /// Schedules (or reschedules) the reminder based on current settings and
  /// today's tasks. Uses [zonedSchedule] for reliability across device
  /// reboots, Doze mode, and battery optimizations.
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

    final periodMinutes = settings.notificationPeriodMinutes < 1
        ? 60
        : settings.notificationPeriodMinutes;

    // Cancel existing before rescheduling
    await _plugin.cancel(_notificationId);

    // Schedule the next notification at (now + period)
    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      Duration(minutes: periodMinutes),
    );

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        _notificationId,
        'Nodly Reminder',
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      debugPrint(
          'Nodly: Notification scheduled for $scheduledDate (in ${periodMinutes}m)');
    } catch (e) {
      debugPrint('Nodly: Error scheduling notification: $e');
    }
  }

  /// Cancels the reminder.
  Future<void> cancelReminder() async {
    await _plugin.cancel(_notificationId);
  }

  /// Fires an immediate test notification so the user can verify
  /// notifications are working.
  Future<void> showTestNotification() async {
    final body = await _buildNotificationBody();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation:
          BigTextStyleInformation(body ?? 'No tasks for today – add some!'),
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      99, // different ID so it doesn't cancel the periodic one
      'Nodly Reminder',
      body ?? 'No tasks for today – add some!',
      details,
    );
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
