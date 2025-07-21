<?php
ob_start();
require 'db_conn.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

function sendJsonResponse($status, $message, $additionalData = []) {
    $response = array_merge([
        'status' => $status,
        'message' => $message
    ], $additionalData);
    
    ob_clean();
    echo json_encode($response);
    exit;
}

try {
    $teacher_user_code = $_POST['teacher_user_code'] ?? '';
    $date_filter = $_POST['date_filter'] ?? date('Y-m-d');

    if (empty($teacher_user_code)) {
        sendJsonResponse('error', 'Missing teacher_user_code.');
    }

    // 1. Get all attendance for the date, ordered by room and time
    $query = "
        SELECT 
            a.*, 
            r.room_name, 
            u.name as user_name, 
            u.access as user_access
        FROM attendance a
        LEFT JOIN rooms r ON a.roomCode = r.room_code
        LEFT JOIN users u ON a.userCode = u.userCode
        WHERE DATE(a.time_scan) = ?
        ORDER BY a.roomCode, a.time_scan ASC
    ";
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        sendJsonResponse('error', 'Database prepare error: ' . $conn->error);
    }
    $stmt->bind_param('s', $date_filter);
    if (!$stmt->execute()) {
        sendJsonResponse('error', 'Database execute error: ' . $stmt->error);
    }
    $result = $stmt->get_result();

    // 2. Organize records by room
    $room_attendance = [];
    while ($row = $result->fetch_assoc()) {
        $room = $row['roomCode'];
        if (!isset($room_attendance[$room])) {
            $room_attendance[$room] = [];
        }
        $room_attendance[$room][] = $row;
    }

    $attendance_data = [];
    foreach ($room_attendance as $roomCode => $records) {
        $i = 0;
        $n = count($records);
        while ($i < $n) {
            $slot_start = strtotime($records[$i]['time_scan']);
            $slot_end = $slot_start + 3600; // 1 hour slot
            $students = [];
            $teachers = [];
            $session_start = $records[$i]['time_scan'];
            $session_end = $session_start;
            $room_name = $records[$i]['room_name'];
            $has_teacher = false;

            // Collect all records within this slot
            $j = $i;
            while ($j < $n && strtotime($records[$j]['time_scan']) < $slot_end) {
                $rec = $records[$j];
                if ($rec['role'] === 'student') {
                    $students[$rec['userCode']] = $rec['user_name'] . ' (' . $rec['userCode'] . ')';
                } elseif ($rec['role'] === 'teacher') {
                    $teachers[$rec['userCode']] = $rec['user_name'] . ' (' . $rec['userCode'] . ')';
                    if ($rec['userCode'] === $teacher_user_code) {
                        $has_teacher = true;
                    }
                }
                if ($rec['time_scan'] > $session_end) {
                    $session_end = $rec['time_scan'];
                }
                $j++;
            }

            // Only include slots where the teacher was present
            if ($has_teacher) {
                $attendance_data[] = [
                    'room_code' => $roomCode,
                    'room_name' => $room_name,
                    'slot_start' => date('Y-m-d H:i:s', $slot_start),
                    'slot_end' => date('Y-m-d H:i:s', $slot_end),
                    'student_count' => count($students),
                    'teacher_count' => count($teachers),
                    'students' => array_values($students),
                    'teachers' => array_values($teachers),
                    'session_start' => $session_start,
                    'session_end' => $session_end,
                    'duration_minutes' => round((strtotime($session_end) - $slot_start) / 60)
                ];
            }
            $i = $j;
        }
    }

    sendJsonResponse('success', 'Attendance data retrieved successfully.', [
        'grouped_attendance' => $attendance_data,
        'date_filter' => $date_filter,
        'total_sessions' => count($attendance_data)
    ]);

} catch (Exception $e) {
    error_log("Error in get_teacher_attendance.php: " . $e->getMessage());
    sendJsonResponse('error', 'Server error: ' . $e->getMessage());
}
?> 