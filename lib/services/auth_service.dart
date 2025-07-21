import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'https://stsapi.bccbsis.com/user_api.php';
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      developer.log('Making login request to $baseUrl');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'email': email,
          'password': password,
        },
      );

      developer.log('Response status code: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['message'] == 'Login successful') {
          var user = responseBody['user'];
          // Create a standardized user data structure
          Map<String, dynamic> standardizedUserData = {
            'id': user['id'],
            'name': user['name'],
            'email': user['email'],
            'access': user['access'],
            'userCode': user['userCode'],
          };

          // Save the standardized user data
          await _saveUserData(standardizedUserData);
          await _saveToken(responseBody['token'] ?? '');

          return {
            'success': true,
            'message': 'Login successful',
            'user': standardizedUserData,
          };
        } else {
          return {
            'success': false,
            'message': responseBody['message'] ?? 'Login failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      developer.log('Error during login: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      developer.log('User logged out successfully');
    } catch (e) {
      developer.log('Error during logout: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(userData));
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
