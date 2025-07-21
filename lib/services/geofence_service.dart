import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceService {
  static const String _fencePrefsKey = 'geofence_enabled';
  static const String _lastFenceStatusKey = 'last_fence_status';
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  GeofenceService() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(initializationSettings);
  }

  // Check fence status based on existing insideStatus from API
  Future<void> checkFenceStatusFromAPI(String familyCode, String parentEmail) async {
    try {
      // Fetch latest location data from the existing API
      final response = await http.get(
        Uri.parse('https://stsapi.bccbsis.com/geofence_check.php?family_code=$familyCode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['message'] == 'Success' && data['geoLocationDetails'] != null) {
          final locationDetails = data['geoLocationDetails'] as List;
          
          if (locationDetails.isNotEmpty) {
            // Get the most recent location entry
            final latestLocation = locationDetails.first;
            final studentName = latestLocation['student_name'] ?? 'Unknown Student';
            final insideStatus = latestLocation['insideStatus'] ?? 'Unknown';
            final timestamp = latestLocation['created_at'] ?? '';
            
            // Check if status changed and send notification
            await _checkStatusChangeAndNotify(studentName, insideStatus, timestamp, parentEmail);
          }
        }
      }
    } catch (e) {
      print('Error checking fence status from API: $e');
    }
  }

  // Check if status changed and send notification
  Future<void> _checkStatusChangeAndNotify(String studentName, String currentStatus, String timestamp, String parentEmail) async {
    try {
      // Get last known fence status
      final prefs = await SharedPreferences.getInstance();
      final lastStatus = prefs.getString('${_lastFenceStatusKey}_$studentName');
      
      // Only send notification if status changed
      if (lastStatus == null) {
        // First time checking - save current status
        await prefs.setString('${_lastFenceStatusKey}_$studentName', currentStatus);
        return;
      }
      
      if (currentStatus != lastStatus) {
        // Status changed - send notification
        String notificationTitle = '';
        String notificationBody = '';
        
        if (currentStatus == 'Inside') {
          notificationTitle = 'Student Entered School';
          notificationBody = '$studentName has entered the school premises at ${_formatTimeFromString(timestamp)}';
        } else if (currentStatus == 'Outside') {
          notificationTitle = 'Student Left School';
          notificationBody = '$studentName has left the school premises at ${_formatTimeFromString(timestamp)}';
        }
        
        if (notificationTitle.isNotEmpty) {
          // Send local notification
          await _showFenceNotification(notificationTitle, notificationBody);
          
          // Send notification to parent via API
          await _sendParentNotification(parentEmail, studentName, currentStatus == 'Inside', timestamp);
          
          // Update last known status
          await prefs.setString('${_lastFenceStatusKey}_$studentName', currentStatus);
        }
      }
    } catch (e) {
      print('Error checking status change: $e');
    }
  }

  // Send notification to parent via API
  Future<void> _sendParentNotification(String parentEmail, String studentName, bool isInside, String timestamp) async {
    try {
      final response = await http.post(
        Uri.parse('https://stsapi.bccbsis.com/fence_notification.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parent_email': parentEmail,
          'student_name': studentName,
          'is_inside': isInside,
          'timestamp': timestamp,
          'status': isInside ? 'Inside' : 'Outside',
        }),
      );
      
      if (response.statusCode == 200) {
        print('Fence notification sent to parent successfully');
      } else {
        print('Failed to send fence notification to parent');
      }
    } catch (e) {
      print('Error sending fence notification: $e');
    }
  }

  // Show local fence notification
  Future<void> _showFenceNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Alerts',
      channelDescription: 'Notifications for student fence events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Format timestamp from string for notification
  String _formatTimeFromString(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown time';
    }
  }

  // Enable/disable geofence monitoring
  Future<void> setGeofenceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fencePrefsKey, enabled);
  }

  // Check if geofence monitoring is enabled
  Future<bool> isGeofenceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fencePrefsKey) ?? false;
  }

  // Get current fence status for a student
  Future<String?> getCurrentFenceStatus(String studentName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_lastFenceStatusKey}_$studentName');
  }

  // Clear fence status for a student (useful for testing)
  Future<void> clearFenceStatus(String studentName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_lastFenceStatusKey}_$studentName');
  }

  // Start periodic fence checking (for background monitoring)
  Future<void> startPeriodicFenceChecking(String familyCode, String parentEmail) async {
    // Check every 5 minutes
    const Duration checkInterval = Duration(minutes: 5);
    
    while (await isGeofenceEnabled()) {
      await checkFenceStatusFromAPI(familyCode, parentEmail);
      await Future.delayed(checkInterval);
    }
  }
} 