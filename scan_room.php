<?php
// Prevent any output before JSON response
ob_start();

require 'db_conn.php';

// Set proper headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 0); // Disable display_errors to prevent output
ini_set('log_errors', 1); // Enable error logging

// Function to send JSON response
function sendJsonResponse($status, $message, $additionalData = []) {
    $response = array_merge([
        'status' => $status,
        'message' => $message
    ], $additionalData);
    
    // Clear any previous output
    ob_clean();
    
    // Send JSON response
    echo json_encode($response);
    exit;
}

try {
    // Get POST data
    $user_code = $_POST['user_code'] ?? '';
    $room_code = $_POST['room_code'] ?? '';
    $role = $_POST['role'] ?? '';

    // Log received data
    error_log("Received data - user_code: $user_code, room_code: $room_code, role: $role");

    if (empty($user_code) || empty($room_code) || empty($role)) {
        sendJsonResponse('error', 'Missing user_code, room_code, or role.');
    }

    // Fetch room name
    $stmt = $conn->prepare("SELECT room FROM rooms WHERE room_code = ?");
    if (!$stmt) {
        sendJsonResponse('error', 'Database prepare error: ' . $conn->error);
    }

    $stmt->bind_param('s', $room_code);
    if (!$stmt->execute()) {
        sendJsonResponse('error', 'Database execute error: ' . $stmt->error);
    }

    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        sendJsonResponse('error', 'Room not found.');
    }

    // Check if user already has an active (login) attendance for this room
    $check = $conn->prepare("SELECT id FROM attendance WHERE userCode = ? AND roomCode = ? AND status = 'login' ORDER BY id DESC LIMIT 1");
    if (!$check) {
        sendJsonResponse('error', 'Database prepare error: ' . $conn->error);
    }

    $check->bind_param('ss', $user_code, $room_code);
    if (!$check->execute()) {
        sendJsonResponse('error', 'Database execute error: ' . $check->error);
    }

    $check_result = $check->get_result();
    $status = 'login';

    if ($check_result->num_rows > 0) {
        $row = $check_result->fetch_assoc();
        $update = $conn->prepare("UPDATE attendance SET status = 'logout' WHERE userCode = ?");
        if (!$update) {
            sendJsonResponse('error', 'Database prepare error: ' . $conn->error);
        }

        $update->bind_param('s', $row['userCode']);
        if (!$update->execute()) {
            sendJsonResponse('error', 'Database execute error: ' . $update->error);
        }
        $status = 'logout';
    }

    $room = $result->fetch_assoc();
    $room_name = $room['room_name'];

    // Insert new attendance record
    $stmt2 = $conn->prepare("INSERT INTO attendance (userCode, roomCode, role, status, time_scan, created_at, updated_at) VALUES (?, ?, ?, ?, NOW(), NOW(), NOW())");
    if (!$stmt2) {
        sendJsonResponse('error', 'Database prepare error: ' . $conn->error);
    }

    $stmt2->bind_param('ssss', $user_code, $room_code, $role, $status);
    if (!$stmt2->execute()) {
        sendJsonResponse('error', 'Failed to record attendance: ' . $stmt2->error);
    }

    // Success response
    sendJsonResponse('success', 'Attendance recorded.', [
        'room_name' => $room_name,
        'attendance_status' => $status
    ]);

} catch (Exception $e) {
    error_log("Error in scan_room.php: " . $e->getMessage());
    sendJsonResponse('error', 'Server error: ' . $e->getMessage());
}
?> 