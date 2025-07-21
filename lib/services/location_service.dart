import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'geofence_service.dart';

class LocationService {
  static const String _locationPrefsKey = 'location_tracking_enabled';
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final GeofenceService _geofenceService = GeofenceService();
  
  LocationService() {
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

  // Method to get the current location of the user
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // Get the current position with high accuracy
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );

    print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    return position;
  }

  // Method to send the location data to the API
  Future<void> sendLocationToApi(
    Position position,
    String email,
    String userCode,
  ) async {
    try {
      final String apiUrl = 'https://stsapi.bccbsis.com/location_service.php';

      final Map<String, dynamic> locationData = {
        'email': email,
        'userCode': userCode,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(locationData),
      );

      if (response.statusCode == 200) {
        print('Location sent successfully');
        print('Response: ${response.body}');
        
        // Show notification for successful location update
        await _showNotification(
          'Location Update',
          'Your location has been updated successfully.',
        );
        
        // Check fence status using existing API data
        await _checkFenceStatusFromAPI(userCode, email);
      } else {
        print('Failed to send location. Status code: ${response.statusCode}');
        await _showNotification(
          'Location Update Failed',
          'Failed to update your location. Please check your connection.',
        );
      }
    } catch (e) {
      print('Error sending location: $e');
      await _showNotification(
        'Location Error',
        'An error occurred while updating your location.',
      );
    }
  }

  // Method to get location and send it to the API with user details
  Future<void> getAndSendLocation(String email, String userCode) async {
    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        await sendLocationToApi(position, email, userCode);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Method to start background location tracking
  Future<void> startBackgroundTracking(String email, String userCode) async {
    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPrefsKey, true);
    
    // Start background location updates using position stream
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: const Duration(minutes: 10), // Update every 10 minutes
      ),
    ).listen((Position position) async {
      await sendLocationToApi(position, email, userCode);
    });
  }

  // Method to stop background location tracking
  Future<void> stopBackgroundTracking() async {
    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPrefsKey, false);
    
    // Note: The stream will automatically stop when the app is closed
    // or when the widget is disposed
  }

  // Method to check if background tracking is enabled
  Future<bool> isBackgroundTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPrefsKey) ?? false;
  }

  // Helper method to show notifications
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'location_tracking_channel',
      'Location Tracking',
      channelDescription: 'Notifications for location tracking updates',
      importance: Importance.low,
      priority: Priority.low,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // NEW: Check fence status using existing API data
  Future<void> _checkFenceStatusFromAPI(String userCode, String email) async {
    try {
      bool isGeofenceEnabled = await _geofenceService.isGeofenceEnabled();
      if (isGeofenceEnabled) {
        await _geofenceService.checkFenceStatusFromAPI(userCode, email);
      }
    } catch (e) {
      print('Error checking fence status: $e');
      // Don't throw error - fence checking should not break location tracking
    }
  }

  // NEW: Enable/disable geofence monitoring
  Future<void> setGeofenceEnabled(bool enabled) async {
    await _geofenceService.setGeofenceEnabled(enabled);
  }

  // NEW: Check if geofence monitoring is enabled
  Future<bool> isGeofenceEnabled() async {
    return await _geofenceService.isGeofenceEnabled();
  }

  // NEW: Start periodic fence checking for background monitoring
  Future<void> startPeriodicFenceChecking(String userCode, String email) async {
    await _geofenceService.startPeriodicFenceChecking(userCode, email);
  }
} 