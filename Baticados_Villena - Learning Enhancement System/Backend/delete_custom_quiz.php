<?php

// FOR custom_created_quizzes.dart

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "learnquik";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $conn->connect_error
    ]);
    exit();
}

$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!isset($data['quiz_id']) || !isset($data['user_id'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required fields'
    ]);
    exit();
}

$quiz_id = intval($data['quiz_id']);
$user_id = intval($data['user_id']);

$sql = "DELETE FROM custom_quizzes WHERE id = ? AND user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $quiz_id, $user_id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Quiz deleted successfully'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Quiz not found'
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to delete quiz: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>