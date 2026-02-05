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

if (!isset($data['quiz_id'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Quiz ID is required'
    ]);
    exit();
}

$quiz_id = intval($data['quiz_id']);

$sql = "SELECT 
            COUNT(*) as attempts,
            COALESCE(ROUND(AVG((score / total_questions) * 100), 1), 0) as average_score
        FROM custom_quiz_attempts 
        WHERE quiz_id = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $quiz_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $stats = $result->fetch_assoc();
    
    echo json_encode([
        'success' => true,
        'attempts' => intval($stats['attempts']),
        'average_score' => floatval($stats['average_score'])
    ]);
} else {
    echo json_encode([
        'success' => true,
        'attempts' => 0,
        'average_score' => 0
    ]);
}

$stmt->close();
$conn->close();
?>