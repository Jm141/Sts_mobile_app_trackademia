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
ini_set('display_errors', 0);
ini_set('log_errors', 1);

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
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendJsonResponse('error', 'Invalid JSON data received');
    }

    $parentEmail = $input['parent_email'] ?? '';
    $studentName = $input['student_name'] ?? '';
    $isInside = $input['is_inside'] ?? false;
    $latitude = $input['latitude'] ?? 0;
    $longitude = $input['longitude'] ?? 0;
    $timestamp = $input['timestamp'] ?? '';

    // Log received data
    error_log("Fence notification received - Parent: $parentEmail, Student: $studentName, Inside: " . ($isInside ? 'true' : 'false'));

    if (empty($parentEmail) || empty($studentName)) {
        sendJsonResponse('error', 'Missing required fields: parent_email or student_name');
    }

    // Insert fence event into database
    $stmt = $conn->prepare("INSERT INTO fence_events (parent_email, student_name, is_inside, latitude, longitude, timestamp) VALUES (?, ?, ?, ?, ?, ?)");
    
    if (!$stmt) {
        sendJsonResponse('error', 'Database prepare error: ' . $conn->error);
    }

    $isInsideInt = $isInside ? 1 : 0;
    $stmt->bind_param('ssidds', $parentEmail, $studentName, $isInsideInt, $latitude, $longitude, $timestamp);
    
    if (!$stmt->execute()) {
        sendJsonResponse('error', 'Database execute error: ' . $stmt->error);
    }

    // Log successful insertion
    error_log("Fence event recorded successfully for student: $studentName");

    // Here you could add additional notification logic:
    // - Send email to parent
    // - Send SMS notification
    // - Push notification
    // - Store in notification queue

    sendJsonResponse('success', 'Fence notification recorded successfully', [
        'event_id' => $stmt->insert_id,
        'timestamp' => $timestamp
    ]);

} catch (Exception $e) {
    error_log("Fence notification error: " . $e->getMessage());
    sendJsonResponse('error', 'Server error: ' . $e->getMessage());
}
?> 