import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'geofence_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'data_persistence_service.dart';
import 'package:intl/intl.dart';

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

  // Helper to get Manila time formatted string
  String _getManilaNowString() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8)); // Manila is UTC+8
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }

  // Method to get location and always cache, then sync if online
  Future<void> getAndCacheAndSendLocation(String email, String userCode) async {
    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        final Map<String, dynamic> locationData = {
          'email': email,
          'userCode': userCode,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': position.timestamp?.toIso8601String() ?? '', // GPS timestamp (optional)
          'cached_at': _getManilaNowString(), // Manila time when cached
        };
        print('Always caching location: ${jsonEncode(locationData)}');
        await DataPersistenceService.addLocationToHistory(locationData);
        await syncCachedLocations();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Method to start background location tracking
  Future<void> startBackgroundTracking(String email, String userCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPrefsKey, true);
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeLimit: const Duration(minutes: 10),
      ),
    ).listen((Position position) async {
      final Map<String, dynamic> locationData = {
        'email': email,
        'userCode': userCode,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp?.toIso8601String() ?? '', // GPS timestamp (optional)
        'cached_at': _getManilaNowString(), // Manila time when cached
      };
      print('Always caching location (background): ${jsonEncode(locationData)}');
      await DataPersistenceService.addLocationToHistory(locationData);
      await syncCachedLocations();
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

  // Remove a location from cache after successful sync
  Future<void> _removeLocationFromCache(Map<String, dynamic> location) async {
    final history = await DataPersistenceService.getLocationHistory();
    history.removeWhere((item) =>
      item['email'] == location['email'] &&
      item['userCode'] == location['userCode'] &&
      item['timestamp'] == location['timestamp']
    );
    await DataPersistenceService.saveLocationHistory(history);
    print('Removed cached location after successful sync: ${jsonEncode(location)}');
  }

  // Method to sync cached locations when internet is available
  Future<void> syncCachedLocations() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('No internet connection. Skipping sync.');
      return;
    }
    final cachedLocations = await DataPersistenceService.getLocationHistory();
    if (cachedLocations.isEmpty) {
      print('No cached locations to sync.');
      return;
    }
    print('Syncing ${cachedLocations.length} cached locations...');
    for (final location in List<Map<String, dynamic>>.from(cachedLocations)) {
      try {
        // Use cached_at as the timestamp for the API
        final Map<String, dynamic> apiPayload = {
          'email': location['email'],
          'userCode': location['userCode'],
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'timestamp': location['cached_at'],
        };
        final response = await http.post(
          Uri.parse('https://stsapi.bccbsis.com/location_service.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(apiPayload),
        );
        if (response.statusCode == 200) {
          print('Synced cached location: ${location['cached_at']}');
          await _removeLocationFromCache(location);
        } else {
          print('Failed to sync cached location: ${location['cached_at']}');
        }
      } catch (e) {
        print('Error syncing cached location: ${e}');
      }
    }
  }

  // Listen for connectivity changes and sync when online
  void listenForConnectivityAndSync() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      if (result != ConnectivityResult.none) {
        await syncCachedLocations();
      }
    });
  }
} 