// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import 'package:timezone/data/latest.dart' as tz;
// // import 'package:timezone/timezone.dart' as tz;

// // class NotificationService {
// //   static final _notifications = FlutterLocalNotificationsPlugin();

// //   static Future<void> init() async {
// //     await _notifications
// //     .resolvePlatformSpecificImplementation<
// //         AndroidFlutterLocalNotificationsPlugin>()
// //     ?.requestExactAlarmsPermission();

// //     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
// //     const settings = InitializationSettings(android: android);
// //     await _notifications.initialize(settings);

// //     tz.initializeTimeZones();
// //   }

// //   static Future<void> scheduleNotification({
// //   required int id,
// //   required String title,
// //   required String body,
// //   required DateTime scheduledDate,
// // }) async {
// //   if (scheduledDate.isBefore(DateTime.now())) {
// //     print("Scheduled time is in the past. Notification not set.");
// //     return;
// //   }

// //   await _notifications.zonedSchedule(
// //     id,
// //     title,
// //     body,
// //     tz.TZDateTime.from(scheduledDate, tz.local),
// //     const NotificationDetails(
// //       android: AndroidNotificationDetails(
// //         'task_channel',
// //         'Task Reminders',
// //         importance: Importance.max,
// //         priority: Priority.high,
// //       ),
// //     ),
// //     androidScheduleMode: AndroidScheduleMode.exact,
// //     matchDateTimeComponents: DateTimeComponents.dateAndTime,

// //   );
// // }

// //   static Future<void> cancelNotification(int id) async {
// //     await _notifications.cancel(id);
// //   }
// // }

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import '../data/models/case_model.dart';

// /// NotificationService
// /// Manages local notifications for scheduled Case hearings and generic alerts.
// /// Implementation avoids external timezone dependencies for simplicity; it
// /// schedules based on the device's local DateTime. Extend with timezone
// /// support (timezone + flutter_native_timezone) if cross‑region accuracy or
// /// DST adjustments become critical.
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _plugin =
//       FlutterLocalNotificationsPlugin();
//   static bool _initialized = false;

//   /// Initializes notification plugin and requests required Android permissions.
//   /// Safe to call multiple times (idempotent).
//   static Future<void> init() async {
//     if (_initialized) return;

//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const settings = InitializationSettings(android: androidInit);
//     await _plugin.initialize(settings);

//     // Timezone initialization for accurate scheduling
//     tz.initializeTimeZones();
//     // Attempt heuristic mapping using Dart's timeZoneName abbreviation.
//     final abbrev = DateTime.now().timeZoneName; // e.g. IST, GMT, PST
//     final mapped = _mapAbbreviationToTimezone(abbrev);
//     tz.setLocalLocation(tz.getLocation(mapped));
//     print('[NotificationService] Timezone set via heuristic. abbrev=$abbrev mapped=$mapped currentLocal=${tz.TZDateTime.now(tz.local)}');

//     // Explicitly create notification channels for Android
//     final androidImpl = _plugin.resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>();
    
//     if (androidImpl != null) {
//       // Create immediate channel
//       await androidImpl.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'immediate_channel',
//           'Immediate',
//           description: 'Immediate notifications',
//           importance: Importance.max,
//           playSound: true,
//           enableVibration: true,
//         ),
//       );
      
//       // Create scheduled channel
//       await androidImpl.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'scheduled_channel',
//           'Scheduled Notifications',
//           description: 'Scheduled reminders for legal case management',
//           importance: Importance.max,
//           playSound: true,
//           enableVibration: true,
//         ),
//       );
      
//       // Request permissions
//       await androidImpl.requestExactAlarmsPermission();
//       await androidImpl.requestNotificationsPermission();
      
//       print('[NotificationService] Channels created and permissions requested');
//     }

//     _initialized = true;
//   }

//   /// Displays an immediate foreground notification.
//   static Future<void> showInstant({
//     required int id,
//     required String title,
//     required String body,
//   }) async {
//     await init();
//     final details = _defaultDetails(channelId: 'immediate_channel', channelName: 'Immediate');
//     await _plugin.show(id, title, body, details);
//   }

//   /// Schedules a one‑off notification at the provided local DateTime.
//   /// Returns true if scheduled, false if skipped (past time).
//   static Future<bool> scheduleOneOff({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime when,
//   }) async {
//     await init();
//     if (when.isBefore(DateTime.now())) {
//       print('[NotificationService] ❌ Skipped: target time is in the past');
//       return false; // Do not schedule past events.
//     }

//     final details = _defaultDetails(
//       channelId: 'scheduled_channel',
//       channelName: 'Scheduled Notifications',
//     );

//     final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);
//     final nowLocal = tz.TZDateTime.now(tz.local);
//     final delay = tzWhen.difference(nowLocal);
    
//     print('[NotificationService] 📅 Scheduling id=$id');
//     print('[NotificationService]    Now:    $nowLocal');
//     print('[NotificationService]    Target: $tzWhen');
//     print('[NotificationService]    Delay:  ${delay.inSeconds}s (${delay.inMinutes}m)');
//     print('[NotificationService]    TZ:     ${tz.local.name}');
    
//     try {
//       await _plugin.zonedSchedule(
//         id,
//         title,
//         body,
//         tzWhen,
//         details,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       );
      
//       final pending = await _plugin.pendingNotificationRequests();
//       print('[NotificationService] ✅ Scheduled successfully! Pending count=${pending.length}');
      
//       // Log all pending for debugging
//       for (final p in pending) {
//         print('[NotificationService]    - ID ${p.id}: ${p.title}');
//       }
      
//       return true;
//     } catch (e) {
//       print('[NotificationService] ❌ Exact scheduling failed: $e');
      
//       // Fallback: attempt inexact schedule
//       try {
//         await _plugin.zonedSchedule(
//           id,
//           title,
//           body,
//           tzWhen,
//           details,
//           androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
//         );
//         print('[NotificationService] ⚠️ Fallback inexact schedule applied');
//         return true;
//       } catch (e2) {
//         print('[NotificationService] ❌ Fallback scheduling also failed: $e2');
//         return false;
//       }
//     }
//   }

//   /// Convenience method for scheduling a reminder tied to a Case's next hearing.
//   /// Schedules THREE strategic reminders:
//   /// - 2 days before at 9:00 AM
//   /// - 1 day before at 9:00 AM
//   /// - Morning of hearing at 8:00 AM
//   /// 
//   /// Uses the case's UUID hashCode as a stable integer id base for cancellation/rescheduling.
//   /// Returns true if at least one reminder was scheduled, false if no hearing or all times are past.
//   static Future<bool> scheduleCaseHearingReminder(CaseModel caseModel) async {
//     final hearing = caseModel.nextHearing;
//     if (hearing == null) return false;
    
//     // First cancel any existing reminders for this case
//     await cancelCaseHearingReminder(caseModel);
    
//     final baseId = caseModel.id.hashCode & 0x7fffffff; // Ensure positive int base
//     final caseTitle = caseModel.title;
//     final caseNo = caseModel.caseNo;
    
//     // Extract the date part of hearing (ignore original time, we'll set strategic times)
//     final hearingDay = DateTime(hearing.year, hearing.month, hearing.day);
    
//     // Define three strategic reminder times
//     final reminders = [
//       {
//         'id': baseId + 1,
//         'time': DateTime(hearingDay.year, hearingDay.month, hearingDay.day - 2, 9, 0), // 2 days before at 9 AM
//         'label': '2 days before hearing',
//       },
//       {
//         'id': baseId + 2,
//         'time': DateTime(hearingDay.year, hearingDay.month, hearingDay.day - 1, 9, 0), // 1 day before at 9 AM
//         'label': '1 day before hearing',
//       },
//       {
//         'id': baseId + 3,
//         'time': DateTime(hearingDay.year, hearingDay.month, hearingDay.day, 8, 0), // Morning of at 8 AM
//         'label': 'Morning of hearing',
//       },
//     ];
    
//     int scheduledCount = 0;
    
//     for (final reminder in reminders) {
//       final reminderTime = reminder['time'] as DateTime;
//       final label = reminder['label'] as String;
//       final id = reminder['id'] as int;
      
//       final title = '⚖️ Case Hearing Reminder';
//       final body = '$label: "$caseTitle" (Case $caseNo) on ${_formatDateTime(hearing)}';
      
//       final success = await scheduleOneOff(
//         id: id,
//         title: title,
//         body: body,
//         when: reminderTime,
//       );
      
//       if (success) {
//         scheduledCount++;
//         print('[NotificationService] ✅ Scheduled $label for: $caseTitle at ${_formatDateTime(reminderTime)}');
//       } else {
//         print('[NotificationService] ⚠️ Skipped $label (time already passed)');
//       }
//     }
    
//     if (scheduledCount > 0) {
//       print('[NotificationService] 🎯 Total reminders scheduled: $scheduledCount for case: $caseTitle');
//       return true;
//     } else {
//       print('[NotificationService] ⚠️ No reminders scheduled (all times are in the past)');
//       return false;
//     }
//   }

//   /// Cancels all scheduled hearing reminders for the given case (all 3 notification IDs).
//   static Future<void> cancelCaseHearingReminder(CaseModel caseModel) async {
//     final baseId = caseModel.id.hashCode & 0x7fffffff;
//     // Cancel all three possible reminder IDs
//     await cancel(baseId + 1);
//     await cancel(baseId + 2);
//     await cancel(baseId + 3);
//     print('[NotificationService] 🗑️ Cancelled all reminders for case: ${caseModel.title}');
//   }

//   /// Generic cancellation by id.
//   static Future<void> cancel(int id) async {
//     await init();
//     await _plugin.cancel(id);
//   }

//   /// Cancels all scheduled notifications.
//   static Future<void> cancelAll() async {
//     await init();
//     await _plugin.cancelAll();
//   }

//   /// Diagnostic method to check notification status and permissions
//   static Future<void> printDiagnostics() async {
//     await init();
    
//     print('\n========== NOTIFICATION DIAGNOSTICS ==========');
    
//     final androidImpl = _plugin.resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>();
    
//     if (androidImpl != null) {
//       try {
//         // Check exact alarm permission
//         final exactAlarmPerm = await androidImpl.canScheduleExactNotifications();
//         if (exactAlarmPerm == null) {
//           print('📋 Exact Alarm Permission: ⚠️ UNKNOWN (null - API may not be supported on this device/Android version)');
//         } else if (exactAlarmPerm == true) {
//           print('📋 Exact Alarm Permission: ✅ GRANTED');
//         } else {
//           print('📋 Exact Alarm Permission: ❌ DENIED');
//         }
//       } catch (e) {
//         print('📋 Exact Alarm Permission: ⚠️ Cannot check (error: $e)');
//       }
      
//       try {
//         // Check notification permission
//         final notifPerm = await androidImpl.areNotificationsEnabled();
//         if (notifPerm == null) {
//           print('📋 Notifications Enabled: ⚠️ UNKNOWN (null)');
//         } else if (notifPerm == true) {
//           print('📋 Notifications Enabled: ✅ YES');
//         } else {
//           print('📋 Notifications Enabled: ❌ NO');
//         }
//       } catch (e) {
//         print('📋 Notifications Enabled: ⚠️ Cannot check (error: $e)');
//       }
//     } else {
//       print('📋 Android implementation not available');
//     }
    
//     // List all pending notifications
//     final pending = await _plugin.pendingNotificationRequests();
//     print('📋 Pending Notifications: ${pending.length}');
    
//     if (pending.isNotEmpty) {
//       for (final p in pending) {
//         print('   • ID ${p.id}: ${p.title} - ${p.body}');
//       }
//     } else {
//       print('   (none scheduled)');
//     }
    
//     // Timezone info
//     print('📋 Timezone: ${tz.local.name}');
//     print('📋 Current Local Time: ${tz.TZDateTime.now(tz.local)}');
//     print('📋 System Time: ${DateTime.now()}');
    
//     print('==============================================\n');
//   }

//   /// Builds platform notification details for Android (extend for iOS).
//   static NotificationDetails _defaultDetails({
//     required String channelId,
//     required String channelName,
//   }) {
//     final android = AndroidNotificationDetails(
//       channelId,
//       channelName,
//       channelDescription: 'Local reminders for legal case management',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
//     return NotificationDetails(android: android);
//   }

//   /// Formats DateTime for human‑readable body content.
//   static String _formatDateTime(DateTime dt) {
//     final date = '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';
//     final time = '${_pad(dt.hour)}:${_pad(dt.minute)}';
//     return '$date $time';
//   }

//   static String _pad(int v) => v.toString().padLeft(2, '0');

//   /// Heuristic mapping from timezone abbreviation to full tz database name.
//   /// Falls back to 'UTC' if unknown. Extend this map as needed.
//   static String _mapAbbreviationToTimezone(String abbrev) {
//     final map = <String, String>{
//       'UTC': 'UTC',
//       'GMT': 'UTC',
//       'IST': 'Asia/Kolkata',
//       'CET': 'Europe/Paris',
//       'CEST': 'Europe/Paris',
//       'EET': 'Europe/Helsinki',
//       'BST': 'Europe/London',
//       'PST': 'America/Los_Angeles',
//       'PDT': 'America/Los_Angeles',
//       'MST': 'America/Denver',
//       'MDT': 'America/Denver',
//       'CST': 'America/Chicago',
//       'CDT': 'America/Chicago',
//       'EST': 'America/New_York',
//       'EDT': 'America/New_York',
//       'JST': 'Asia/Tokyo',
//       'KST': 'Asia/Seoul',
//       'HKT': 'Asia/Hong_Kong',
//       'AWST': 'Australia/Perth',
//       'AEST': 'Australia/Sydney',
//       'AEDT': 'Australia/Sydney',
//     };
//     return map[abbrev] ?? 'UTC';
//   }
// }
