class AttendanceSession {
  final String date;
  final String hourSlot;
  final String roomCode;
  final String roomName;
  final int studentCount;
  final int teacherCount;
  final List<String> students;
  final List<String> teachers;
  final String sessionStart;
  final String sessionEnd;
  final int durationMinutes;

  AttendanceSession({
    required this.date,
    required this.hourSlot,
    required this.roomCode,
    required this.roomName,
    required this.studentCount,
    required this.teacherCount,
    required this.students,
    required this.teachers,
    required this.sessionStart,
    required this.sessionEnd,
    required this.durationMinutes,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      date: json['date'] ?? '',
      hourSlot: json['hour_slot'] ?? '',
      roomCode: json['room_code'] ?? '',
      roomName: json['room_name'] ?? '',
      studentCount: json['student_count'] ?? 0,
      teacherCount: json['teacher_count'] ?? 0,
      students: List<String>.from(json['students'] ?? []),
      teachers: List<String>.from(json['teachers'] ?? []),
      sessionStart: json['session_start'] ?? '',
      sessionEnd: json['session_end'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'hour_slot': hourSlot,
      'room_code': roomCode,
      'room_name': roomName,
      'student_count': studentCount,
      'teacher_count': teacherCount,
      'students': students,
      'teachers': teachers,
      'session_start': sessionStart,
      'session_end': sessionEnd,
      'duration_minutes': durationMinutes,
    };
  }

  String get formattedTime {
    final start = DateTime.parse(sessionStart);
    final end = DateTime.parse(sessionEnd);
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    final dateTime = DateTime.parse(date);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
} 