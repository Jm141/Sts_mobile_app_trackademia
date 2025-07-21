import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'geofence_service.dart';

class BackgroundService {
  static final GeofenceService _geofenceService = GeofenceService();

  static Future<void> initializeService() async {
    // Skip initialization on web platform
    if (kIsWeb) {
      print('Background Service: Skipping initialization on web platform');
      return;
    }

    final service = FlutterBackgroundService();

    // Configure notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'triconnect_foreground',
      'Triconnect Location Service',
      description: 'This channel is used for location tracking notifications.',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'triconnect_foreground',
        initialNotificationTitle: 'Triconnect Location Service',
        initialNotificationContent: 'Tracking location in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    print('Background Service: Service started successfully');
    print('Background Service: Current time: ${DateTime.now()}');

    // Save service status
    await setServiceStatus(true);
    await _saveLog('🟢 Background service started');

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        print('Background Service: Set as foreground');
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        print('Background Service: Set as background');
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      print('Background Service: Service stopped');
      setServiceStatus(false);
      service.stopSelf();
    });

    print(
        'Background Service: Starting continuous location updates (every 1 minute)');

    // Send location immediately when service starts
    print('Background Service: Sending initial location');
    await testLocationSending();

    // Start fence checking in parallel
    _startFenceChecking();

    // Use a continuous loop with shorter delays for better reliability
    int counter = 0;
    while (true) {
      try {
        // Wait for 1 minute (60 seconds)
        for (int i = 0; i < 60; i++) {
          await Future.delayed(const Duration(seconds: 1));
          counter++;

          // Update notification every 10 seconds to show service is alive
          if (counter % 10 == 0 && service is AndroidServiceInstance) {
            final currentTime = DateTime.now().toString().substring(11, 19);
            service.setForegroundNotificationInfo(
              title: 'Triconnect Location Service',
              content: 'Active - Next update in ${60 - counter} seconds',
            );
          }
        }

        // Reset counter and send location
        counter = 0;
        print(
            'Background Service: Timer triggered at ${DateTime.now()} - sending location');
        await _saveLog('⏰ Timer triggered - sending location');

        // Use the exact same function that works with the test button
        await testLocationSending();

        // Update service notification with timestamp
        if (service is AndroidServiceInstance) {
          final currentTime = DateTime.now().toString().substring(11, 19);
          service.setForegroundNotificationInfo(
            title: 'Triconnect Location Service',
            content: 'Active - Last update: $currentTime',
          );
        }
      } catch (e) {
        print('Background Service: Error in location loop: $e');
        await _saveLog('❌ Background loop error: ${e.toString()}');

        // Wait a bit before retrying
        await Future.delayed(const Duration(seconds: 30));
      }
    }
  }

  // NEW: Start fence checking in background
  static Future<void> _startFenceChecking() async {
    try {
      // Check if geofence is enabled
      bool isGeofenceEnabled = await _geofenceService.isGeofenceEnabled();
      if (!isGeofenceEnabled) {
        print('Background Service: Geofence monitoring is disabled');
        await _saveLog('🚫 Geofence monitoring disabled');
        return;
      }

      print('Background Service: Starting fence checking');
      await _saveLog('🔍 Starting fence checking');

      // Get user data
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null) {
        print('Background Service: No user data found for fence checking');
        await _saveLog('❌ No user data for fence checking');
        return;
      }

      final userData = json.decode(userDataString);
      final userCode = userData['userCode'];
      final email = userData['email'];

      if (userCode == null || email == null) {
        print('Background Service: Missing user data for fence checking');
        await _saveLog('❌ Missing user data for fence checking');
        return;
      }

      // Start periodic fence checking
      await _geofenceService.startPeriodicFenceChecking(userCode, email);
    } catch (e) {
      print('Background Service: Error starting fence checking: $e');
      await _saveLog('❌ Error starting fence checking: ${e.toString()}');
    }
  }

  // Manual function to start the background service
  static Future<void> startBackgroundService() async {
    // Skip on web platform
    if (kIsWeb) {
      print('Background Service: Skipping startBackgroundService on web platform');
      return;
    }

    print('Background Service: Manually starting background service');
    await _saveLog('🔄 Manually starting background service...');

    final service = FlutterBackgroundService();

    // Check if service is running
    final isRunning = await service.isRunning();
    print('Background Service: Is service running? $isRunning');
    await _saveLog(
        '📊 Service status: ${isRunning ? "Running" : "Not running"}');

    if (!isRunning) {
      print('Background Service: Starting service...');
      await _saveLog('🚀 Starting background service...');

      try {
        // Initialize the service first
        await initializeService();
        await _saveLog('✅ Service initialized successfully');

        // Wait a moment for service to start
        await Future.delayed(const Duration(seconds: 2));

        // Check if service is now running
        final nowRunning = await service.isRunning();
        print('Background Service: Service now running? $nowRunning');
        await _saveLog('📊 Service now running: $nowRunning');

        if (nowRunning) {
          await _saveLog('🎉 Background service started successfully!');
        } else {
          await _saveLog('❌ Failed to start background service');
        }
      } catch (e) {
        print('Background Service: Error starting service: $e');
        await _saveLog('❌ Error starting service: ${e.toString()}');
      }
    } else {
      print('Background Service: Service is already running');
      await _saveLog('ℹ️ Service is already running');
    }
  }

  // Manual test function to trigger location sending immediately
  static Future<void> testLocationSending() async {
    // Skip on web platform
    if (kIsWeb) {
      print('Background Service: Skipping testLocationSending on web platform');
      return;
    }

    print('Background Service: Manual test triggered');

    try {
      // Get stored user data
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null) {
        print('Background Service: No user data found in SharedPreferences');
        await _saveLog('❌ No user data found');
        return;
      }

      final userData = json.decode(userDataString);
      final userCode = userData['userCode'];
      final email = userData['email'];

      print(
          'Background Service: User data - userCode: $userCode, email: $email');
      await _saveLog('👤 User: $email');

      if (userCode == null || email == null) {
        print('Background Service: Missing userCode or email in user data');
        await _saveLog('❌ Missing user data');
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
          'Background Service: Got location - Lat: ${position.latitude}, Lng: ${position.longitude}');
      await _saveLog(
          '📍 Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');

      // Send location to server using the correct API endpoint and format
      const String apiUrl = 'https://stsapi.bccbsis.com/location_service.php';

      final Map<String, dynamic> locationData = {
        'email': email,
        'userCode': userCode,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.toIso8601String(),
      };

      print(
          'Background Service: Sending data to API: ${jsonEncode(locationData)}');
      await _saveLog('📤 Sending to API...');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(locationData),
      );

      print('Background Service: API Response Status: ${response.statusCode}');
      print('Background Service: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Background Service: Manual test - Location sent successfully');
        await _saveLog(
            '✅ Location sent successfully at ${DateTime.now().toString().substring(11, 19)}');
      } else {
        print(
            'Background Service: Manual test - Failed to send location. Status code: ${response.statusCode}');
        print(
            'Background Service: Manual test - Response body: ${response.body}');
        await _saveLog(
            '❌ Failed to send location (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Background Service: Manual test - Error: $e');
      print(
          'Background Service: Manual test - Stack trace: ${StackTrace.current}');
      await _saveLog('❌ Error: ${e.toString()}');
    }
  }

  // Helper function to save logs locally
  static Future<void> _saveLog(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toString().substring(11, 19);
      final logEntry = '[$now] $message';

      // Get existing logs
      final existingLogs = prefs.getStringList('location_logs') ?? [];

      // Add new log entry
      existingLogs.insert(0, logEntry);

      // Keep only last 20 logs
      if (existingLogs.length > 20) {
        existingLogs.removeRange(20, existingLogs.length);
      }

      // Save logs
      await prefs.setStringList('location_logs', existingLogs);
    } catch (e) {
      print('Error saving log: $e');
    }
  }

  // Function to get logs
  static Future<List<String>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('location_logs') ?? [];
    } catch (e) {
      return [];
    }
  }

  // Function to clear logs
  static Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('location_logs');
    } catch (e) {
      print('Error clearing logs: $e');
    }
  }

  // Function to save service status
  static Future<void> setServiceStatus(bool isRunning) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_service_running', isRunning);
    } catch (e) {
      print('Error saving service status: $e');
    }
  }

  // Function to get service status
  static Future<bool> isServiceRunning() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('background_service_running') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Function to stop the background service
  static Future<void> stopBackgroundService() async {
    print('Background Service: Stopping background service');
    await _saveLog('🛑 Stopping background service...');

    try {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      await setServiceStatus(false);
      await _saveLog('✅ Background service stopped');
    } catch (e) {
      print('Background Service: Error stopping service: $e');
      await _saveLog('❌ Error stopping service: ${e.toString()}');
    }
  }
}
