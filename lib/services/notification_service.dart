import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // CHANGE CHANNEL ID TO FORCE UPDATE ON DEVICE
  static const String channelId = 'journal_reminders_v5_final'; 
  static const String channelName = 'Daily Journal Reminders';
  static const String channelDescription = 'Reminds you to write your journal';

  Future<void> init() async {
    await configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    final AndroidNotificationChannel channel = const AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max, // Explicitly set to MAX
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      
      // Fix for devices returning legacy "Asia/Calcutta"
      if (timeZoneName == 'Asia/Calcutta') {
        timeZoneName = 'Asia/Kolkata';
      }

      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Local timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('Could not get local timezone: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        debugPrint('Fallback to Asia/Kolkata success');
      } catch (e2) {
         debugPrint('Fallback failed. Using UTC. Error: $e2');
      }
    }
  }

  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final notificationStatus = await Permission.notification.request();
      
      // For exact alarms (Android 12+)
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (alarmStatus.isDenied) {
          await Permission.scheduleExactAlarm.request();
      }
      
      return notificationStatus.isGranted;
    }
    return true;
  }
  
  // Method to check if permissions are granted
  Future<bool> arePermissionsGranted() async {
     return await Permission.notification.isGranted;
  }

  Future<void> cancelReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Schedules multiple notifications at the given interval (in minutes)
  /// starting from [startTime] (or now if null).
  /// This schedules reminders for the next 24 hours to ensure coverage.
  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      888, 
      'Instant Test ⚡', 
      'This is an instant notification to test display.', 
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> scheduleReminders({required int intervalMinutes}) async {
    debugPrint('Step 1: scheduleReminders called with interval: $intervalMinutes');
    await cancelReminders(); // Clear first

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', true);
    await prefs.setInt('reminder_interval', intervalMinutes);

    // If user has already journaled today, don't schedule anything new.
    final lastDate = prefs.getString('last_journal_date');
    final today = DateTime.now().toIso8601String().split('T')[0];

    debugPrint('Step 2: Checking date. Last: $lastDate, Today: $today');

    if (lastDate == today) {
        debugPrint('Already journaled today. Reminders paused.');
        return; 
    }

    final now = tz.TZDateTime.now(tz.local);
    debugPrint('Step 3: Scheduling from now: $now');
    
    // Check exact alarm permission status for debugging
    if (defaultTargetPlatform == TargetPlatform.android) {
       final status = await Permission.scheduleExactAlarm.status;
       debugPrint('Exact Alarm Permission Status: $status');
    }

    int maxNotifications = 10; 

    for (int i = 1; i <= maxNotifications; i++) {
        final scheduledTime = now.add(Duration(minutes: intervalMinutes * i));
        
        debugPrint('Scheduling notification #$i at $scheduledTime');

        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            i,
            'Journal Time ✍️',
            'Please write your journal.',
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                channelName,
                channelDescription: channelDescription,
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e) {
          debugPrint('Error scheduling notification #$i: $e');
        }
    }
  }

  /// Stops reminders for the current day, but keeps the preference enabled.
  Future<void> completeForToday() async {
    await cancelReminders();
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_journal_date', today);
    await prefs.setBool('reminders_auto_paused', true);
    debugPrint('Journal completed for today. Reminders auto-paused.');
  }

  /// Resumes reminders after a journal deletion leaves no entries for today.
  Future<void> resumeReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminders_enabled') ?? false;
    if (!enabled) {
      debugPrint('Reminders were not enabled. Nothing to resume.');
      return;
    }

    // Clear the "journaled today" marker so scheduling proceeds
    await prefs.remove('last_journal_date');
    await prefs.setBool('reminders_auto_paused', false);

    final interval = prefs.getInt('reminder_interval') ?? 120;
    await scheduleReminders(intervalMinutes: interval);
    debugPrint('Reminders resumed at $interval min interval after journal deletion.');
  }

  /// Checks if we need to resume reminders (e.g., app opened on a new day)
  Future<void> checkAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminders_enabled') ?? false;
    
    if (!enabled) return;

    final lastDate = prefs.getString('last_journal_date');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != today) {
       // New day! User hasn't journaled yet.
       // Resume reminders.
       final interval = prefs.getInt('reminder_interval') ?? 60; 
       await scheduleReminders(intervalMinutes: interval);
       debugPrint('New day detected. Rescheduling reminders every $interval min.');
    } else {
       debugPrint('Still same day and already journaled. No reminders.');
    }
  }
}
