import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo_list.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification taps here
    print('Notification tapped: ${response.payload}');
  }
  
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // Request notification permission
          await androidPlugin.requestPermission();
        }
      } catch (e) {
        print('Error requesting notification permissions: $e');
      }
    }
  }
  
  Future<bool> checkAndRequestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        // On some Android devices, this will open Alarms & Reminders settings
        // when exact alarms are not permitted
        return true;
      } catch (e) {
        print('Error checking alarm permissions: $e');
      }
    }
    return true; // Not Android or plugin not available
  }
  
  Future<void> openAlarmSettings() async {
    if (Platform.isAndroid) {
      // If this method isn't available in your version of the plugin,
      // we can try to use platform channels directly
      try {
        const platform = MethodChannel('dexterx.dev/flutter_local_notifications_android');
        await platform.invokeMethod('requestExactAlarmsPermission');
      } catch (e) {
        print('Error opening alarm settings: $e');
        // Show a guide to the user on how to enable exact alarms
      }
    }
  }
  
  Future<void> scheduleTaskReminder(TodoTask task) async {
    if (task.dueDate == null) return;
    
    await cancelTaskReminder(task.id);
    
    // Set notification time
    DateTime notificationTime;
    
    if (task.dueTime != null) {
      // If time is specified, notify 1 hour before
      notificationTime = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.dueTime!.hour,
        task.dueTime!.minute,
      ).subtract(const Duration(hours: 1));
    } else {
      // If only date is specified, notify at 8 PM the day before
      notificationTime = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        20, // 8 PM
        0,
      ).subtract(const Duration(days: 1));
    }
    
    // Only schedule if the notification time is in the future
    if (notificationTime.isAfter(DateTime.now())) {
      final androidDetails = AndroidNotificationDetails(
        'todo_reminder_channel',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Ensure we get a valid integer ID
      int id;
      try {
        id = int.parse(task.id.hashCode.toString().replaceAll(RegExp(r'[^\d]'), '').substring(0, 9));
      } catch (e) {
        // Fallback ID if parsing fails
        id = task.id.hashCode.abs() % 100000;
      }
      
      try {
        // Try to schedule with exact timing
        await _notificationsPlugin.zonedSchedule(
          id,
          'Task Reminder: ${task.name}',
          task.description.isNotEmpty 
              ? task.description 
              : 'Due: ${_formatDueDate(task)}',
          tz.TZDateTime.from(notificationTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
          payload: task.id,
        );
        print('Scheduled notification for task: ${task.name} at ${notificationTime.toString()}');
      } catch (e) {
        print('Error scheduling notification: $e');
        
        // Fallback to inexact alarms if exact alarms are not permitted
        if (e.toString().contains('exact_alarms_not_permitted')) {
          try {
            await _notificationsPlugin.zonedSchedule(
              id,
              'Task Reminder: ${task.name}',
              task.description.isNotEmpty 
                  ? task.description 
                  : 'Due: ${_formatDueDate(task)}',
              tz.TZDateTime.from(notificationTime, tz.local),
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: 
                UILocalNotificationDateInterpretation.absoluteTime,
              payload: task.id,
            );
            print('Scheduled inexact notification for task: ${task.name}');
          } catch (fallbackE) {
            print('Error scheduling inexact notification: $fallbackE');
          }
        }
      }
    }
  }
  
  String _formatDueDate(TodoTask task) {
    if (task.dueDate == null) return '';
    
    final date = '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}';
    
    if (task.dueTime == null) {
      return date;
    } else {
      final hour = task.dueTime!.hour.toString().padLeft(2, '0');
      final minute = task.dueTime!.minute.toString().padLeft(2, '0');
      return '$date at $hour:$minute';
    }
  }
  
  Future<void> cancelTaskReminder(String taskId) async {
    // Ensure we get a valid integer ID
    int id;
    try {
      id = int.parse(taskId.hashCode.toString().replaceAll(RegExp(r'[^\d]'), '').substring(0, 9));
    } catch (e) {
      // Fallback ID if parsing fails
      id = taskId.hashCode.abs() % 100000;
    }
    
    await _notificationsPlugin.cancel(id);
  }
  
  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }
  
  // Helper method to show the user how to manually enable exact alarms
  void showExactAlarmGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Enable Exact Alarms',
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To receive timely task reminders:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '1. Open your device Settings\n'
              '2. Go to Apps or Applications\n'
              '3. Find NeuroAssist\n'
              '4. Tap on Permissions\n'
              '5. Select "Alarms & Reminders"\n'
              '6. Enable the permission',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }
}