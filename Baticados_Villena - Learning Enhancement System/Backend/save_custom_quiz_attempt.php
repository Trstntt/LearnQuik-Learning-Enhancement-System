<?php

// FOR quiz_result.dart

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

if (!isset($data['quiz_id']) || !isset($data['user_id']) || !isset($data['score']) || 
    !isset($data['total_questions']) || !isset($data['answers'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required fields'
    ]);
    exit();
}

$quiz_id = intval($data['quiz_id']);
$user_id = intval($data['user_id']);
$score = intval($data['score']);
$total_questions = intval($data['total_questions']);
$answers = json_encode($data['answers']);

$sql = "INSERT INTO custom_quiz_attempts (quiz_id, user_id, score, total_questions, answers) 
        VALUES (?, ?, ?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("iiiis", $quiz_id, $user_id, $score, $total_questions, $answers);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Quiz attempt saved successfully'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to save quiz attempt: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>