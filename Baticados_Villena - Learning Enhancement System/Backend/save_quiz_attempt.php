<?php

// FOR quiz_result.dart

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    header('Access-Control-Max-Age: 86400');
    http_response_code(200);
    exit;
}

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$db_host = 'localhost';
$db_name = 'learnquik';
$db_user = 'root';
$db_pass = '';

$response = array();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $response['success'] = false;
    $response['message'] = 'Invalid request method';
    echo json_encode($response);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['quiz_id']) || !isset($input['user_id']) || 
    !isset($input['score']) || !isset($input['total_questions']) || 
    !isset($input['answers'])) {
    $response['success'] = false;
    $response['message'] = 'Missing required fields';
    echo json_encode($response);
    exit;
}

$quiz_id = $input['quiz_id'];
$user_id = $input['user_id'];
$score = intval($input['score']);
$total_questions = intval($input['total_questions']);
$answers = json_encode($input['answers']);

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("INSERT INTO quiz_attempts (quiz_id, user_id, score, total_questions, answers) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$quiz_id, $user_id, $score, $total_questions, $answers]);
    
    $response['success'] = true;
    $response['message'] = 'Quiz attempt saved successfully';
    $response['attempt_id'] = $pdo->lastInsertId();
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
}

echo json_encode($response);
?>