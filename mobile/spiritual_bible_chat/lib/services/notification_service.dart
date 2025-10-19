import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/onboarding_profile.dart';
import '../utils/reminders.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  static const int _reminderNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final StreamController<String> _tapStreamController =
      StreamController<String>.broadcast();

  Stream<String> get taps => _tapStreamController.stream;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _tapStreamController.add(payload);
        }
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
          alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> scheduleReminder(ReminderSlot slot, DateTime dateTime) async {
    if (!_initialized || kIsWeb) return;
    await cancelReminder();

    final tzDateTime = tz.TZDateTime.from(dateTime, tz.local);
    final label = reminderLabel(slot);
    try {
      await _plugin.zonedSchedule(
        _reminderNotificationId,
        'Spiritual Bible Chat',
        '$label is ready for you',
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders',
            'Daily Reminders',
            channelDescription: 'Daily inspiration reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'open_today',
      );
    } on PlatformException catch (error) {
      debugPrint('Failed to schedule reminder: $error');
    }
  }

  Future<void> cancelReminder() async {
    if (!_initialized || kIsWeb) return;
    await _plugin.cancel(_reminderNotificationId);
  }

  Future<void> cancelAll() async {
    if (!_initialized || kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<String?> getLaunchPayload() async {
    if (!_initialized || kIsWeb) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }
}
