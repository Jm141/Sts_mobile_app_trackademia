# Teacher Attendance Feature Setup Guide

## Overview
This feature allows teachers to view attendance data grouped by time and room. When a teacher scans a room QR code, the system groups all students who were in that room during the same time period and displays them in an organized attendance view.

## Database Requirements

### Attendance Table Structure
The attendance table should have the following structure:
```sql
CREATE TABLE attendance (
    id BIGINT(20) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    userCode VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    roomCode VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
    role VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
    status VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
    time_scan TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

### Required Related Tables
- `rooms` table with `room_code` and `room_name` fields
- `users` table with `userCode`, `name`, and `email` fields

## Setup Instructions

### 1. Database Configuration
Update `db_conn.php` with your database credentials:
```php
$host = 'your_host';
$username = 'your_username';
$password = 'your_password';
$database = 'your_database_name';
```

### 2. API Configuration
Update the base URL in `lib/services/attendance_service.dart`:
```dart
static const String baseUrl = 'http://your-domain.com'; // Replace with your actual domain
```

### 3. File Placement
Place the PHP files in your web server directory:
- `get_teacher_attendance.php`
- `db_conn.php`

## How It Works

### 1. QR Code Scanning
- Students and teachers scan room QR codes using the existing QR scanner
- Each scan creates an attendance record with role (student/teacher)
- Records are timestamped and linked to specific rooms

### 2. Attendance Grouping
The system groups attendance by:
- **Date**: Daily attendance records
- **Hour Slot**: Groups records by hour (e.g., 8:00, 9:00, 10:00)
- **Room**: Groups by specific room codes
- **Teacher Presence**: Only shows sessions where the teacher was present

### 3. Teacher View
Teachers can:
- View attendance grouped by time and room
- See student and teacher counts per session
- Expand session details to see individual names
- Filter by date
- View session duration and timing

## API Endpoints

### GET Teacher Attendance
**URL**: `POST /get_teacher_attendance.php`

**Parameters**:
- `teacher_user_code` (required): The teacher's user code
- `date_filter` (optional): Date in YYYY-MM-DD format (defaults to today)

**Response**:
```json
{
  "status": "success",
  "message": "Attendance data retrieved successfully",
  "grouped_attendance": [
    {
      "date": "2024-01-15",
      "hour_slot": "08:00",
      "room_code": "ROOM101",
      "room_name": "Computer Lab 1",
      "student_count": 15,
      "teacher_count": 1,
      "students": ["John Doe (STU001)", "Jane Smith (STU002)"],
      "teachers": ["Dr. Johnson (TCH001)"],
      "session_start": "2024-01-15 08:00:00",
      "session_end": "2024-01-15 09:00:00",
      "duration_minutes": 60
    }
  ],
  "date_filter": "2024-01-15",
  "total_sessions": 1
}
```

## Flutter Implementation

### Navigation
The attendance feature is accessible through the teacher dashboard navigation. When a teacher clicks "Attendance", they are taken to the `TeacherAttendancePage`.

### Features
- **Date Selection**: Teachers can select any date to view historical attendance
- **Session Cards**: Each session shows room, time, duration, and participant counts
- **Expandable Details**: Click on session cards to see individual student and teacher names
- **Real-time Updates**: Refresh button to reload attendance data
- **Error Handling**: Graceful error handling with retry options

## Usage Flow

1. **Teacher scans room QR code** → Creates attendance record
2. **Students scan same room QR code** → Creates student attendance records
3. **System groups records** → Groups by time, room, and teacher presence
4. **Teacher views attendance** → Sees organized session data with student lists

## Troubleshooting

### Common Issues

1. **No attendance data showing**
   - Check if teacher has scanned any rooms
   - Verify date selection
   - Check database connection

2. **API errors**
   - Verify database credentials in `db_conn.php`
   - Check web server permissions
   - Review PHP error logs

3. **Flutter app errors**
   - Verify API base URL in `attendance_service.dart`
   - Check network connectivity
   - Ensure user data contains valid `userCode`

### Debug Steps
1. Check PHP error logs for API issues
2. Verify database table structure matches requirements
3. Test API endpoint directly with Postman or similar tool
4. Check Flutter console for network errors

## Security Considerations

- Validate teacher permissions before showing attendance data
- Sanitize all database inputs
- Use HTTPS for API communications
- Implement proper authentication for API endpoints
- Consider data retention policies for attendance records 