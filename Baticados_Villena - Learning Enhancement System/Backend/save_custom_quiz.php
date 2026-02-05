<?php

// FOR custom_quiz_creation.dart

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

if (!isset($data['user_id']) || !isset($data['quiz_name']) || !isset($data['quiz_type']) || 
    !isset($data['num_questions']) || !isset($data['questions'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required fields'
    ]);
    exit();
}

$user_id = intval($data['user_id']);
$quiz_name = $conn->real_escape_string($data['quiz_name']);
$quiz_type = $conn->real_escape_string($data['quiz_type']);
$num_questions = intval($data['num_questions']);
$num_choices = isset($data['num_choices']) ? intval($data['num_choices']) : 4;
$questions = $data['questions'];

if (!is_array($questions) || count($questions) !== $num_questions) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid questions data'
    ]);
    exit();
}

$conn->begin_transaction();

try {
    $sql = "INSERT INTO custom_quizzes (user_id, quiz_name, quiz_type, num_questions, num_choices) 
            VALUES (?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("issii", $user_id, $quiz_name, $quiz_type, $num_questions, $num_choices);
    
    if (!$stmt->execute()) {
        throw new Exception('Failed to insert quiz: ' . $stmt->error);
    }
    
    $quiz_id = $conn->insert_id;
    $stmt->close();
    
    $questions_json = json_encode($questions);
    $sql = "INSERT INTO custom_quiz_questions (quiz_id, questions_data) VALUES (?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("is", $quiz_id, $questions_json);
    
    if (!$stmt->execute()) {
        throw new Exception('Failed to insert questions: ' . $stmt->error);
    }
    
    $stmt->close();
    
    $conn->commit();
    
    echo json_encode([
        'success' => true,
        'message' => 'Custom quiz saved successfully',
        'quiz_id' => $quiz_id
    ]);
    
} catch (Exception $e) {
    $conn->rollback();
    
    echo json_encode([
        'success' => false,
        'message' => 'Error saving quiz: ' . $e->getMessage()
    ]);
}

$conn->close();
?>