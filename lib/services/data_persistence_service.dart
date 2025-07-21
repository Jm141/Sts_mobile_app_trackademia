import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataPersistenceService {
  static const String USER_DATA_KEY = 'user_data';
  static const String LOCATION_HISTORY_KEY = 'location_history';
  static const String LAST_SYNC_KEY = 'last_sync';

  // Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(USER_DATA_KEY, json.encode(userData));
  }

  // Get user data
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(USER_DATA_KEY);
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return {};
  }

  // Save location history
  static Future<void> saveLocationHistory(List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LOCATION_HISTORY_KEY, json.encode(history));
  }

  // Get location history
  static Future<List<Map<String, dynamic>>> getLocationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(LOCATION_HISTORY_KEY);
    if (historyString != null) {
      final List<dynamic> decoded = json.decode(historyString);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Add new location to history
  static Future<void> addLocationToHistory(Map<String, dynamic> location) async {
    final history = await getLocationHistory();
    history.insert(0, location); // Add new location at the beginning
    if (history.length > 100) { // Keep only last 100 locations
      history.removeLast();
    }
    await saveLocationHistory(history);
  }

  // Save last sync time
  static Future<void> saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LAST_SYNC_KEY, DateTime.now().toIso8601String());
  }

  // Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSyncString = prefs.getString(LAST_SYNC_KEY);
    if (lastSyncString != null) {
      return DateTime.parse(lastSyncString);
    }
    return null;
  }

  // Clear all stored data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
} 