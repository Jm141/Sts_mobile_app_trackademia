import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceService {
  static const String baseUrl = 'https://stsapi.bccbsis.com';

  static Future<Map<String, dynamic>> getTeacherAttendance({
    required String teacherUserCode,
    String? dateFilter,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_attendance.php'),
        body: {
          'teacher_user_code': teacherUserCode,
          'date_filter': dateFilter ?? DateTime.now().toString().split(' ')[0],
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceByDate({
    required String teacherUserCode,
    required String date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_attendance.php'),
        body: {
          'teacher_user_code': teacherUserCode,
          'date_filter': date,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['grouped_attendance']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load attendance data');
        }
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 