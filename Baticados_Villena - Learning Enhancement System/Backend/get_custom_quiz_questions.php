<?php

// FOR quiz_id.dart
// FOR quiz_mc.dart

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

$custom_sql = "SELECT questions_data FROM custom_quiz_questions WHERE quiz_id = ?";
$stmt = $conn->prepare($custom_sql);
$stmt->bind_param("i", $quiz_id);
$stmt->execute();
$custom_result = $stmt->get_result();

if ($custom_result->num_rows > 0) {
    $row = $custom_result->fetch_assoc();
    $questions = json_decode($row['questions_data'], true);
    
    foreach ($questions as &$question) {
        if (isset($question['options']) && is_array($question['options'])) {
            $correct_answer = $question['options'][0];
            shuffle($question['options']);
            $question['correct_answer'] = array_search($correct_answer, $question['options']);
        }
    }
    
    $stmt->close();
    $conn->close();
    
    echo json_encode([
        'success' => true,
        'questions' => $questions,
        'is_custom' => true
    ]);
} else {
    $stmt->close();
    
    $regular_sql = "SELECT questions_data FROM quiz_questions WHERE quiz_id = ?";
    $stmt = $conn->prepare($regular_sql);
    $stmt->bind_param("i", $quiz_id);
    $stmt->execute();
    $regular_result = $stmt->get_result();
    
    if ($regular_result->num_rows > 0) {
        $row = $regular_result->fetch_assoc();
        $questions = json_decode($row['questions_data'], true);
        
        $stmt->close();
        $conn->close();
        
        echo json_encode([
            'success' => true,
            'questions' => $questions,
            'is_custom' => false
        ]);
    } else {
        $stmt->close();
        $conn->close();
        
        echo json_encode([
            'success' => false,
            'message' => 'Quiz not found'
        ]);
    }
}
?>