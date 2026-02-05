<?php

// FOR created_quizzes.dart

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

if (!isset($input['quiz_id'])) {
    $response['success'] = false;
    $response['message'] = 'Missing quiz_id';
    echo json_encode($response);
    exit;
}

$quiz_id = $input['quiz_id'];

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("SELECT COUNT(*) as attempts FROM quiz_attempts WHERE quiz_id = ?");
    $stmt->execute([$quiz_id]);
    $attempts_result = $stmt->fetch(PDO::FETCH_ASSOC);
    $attempts = $attempts_result['attempts'];
    
    $average_score = 0;
    if ($attempts > 0) {
        $stmt = $pdo->prepare("
            SELECT AVG((score * 100.0) / total_questions) as avg_percentage 
            FROM quiz_attempts 
            WHERE quiz_id = ?
        ");
        $stmt->execute([$quiz_id]);
        $avg_result = $stmt->fetch(PDO::FETCH_ASSOC);
        $average_score = round($avg_result['avg_percentage'], 1);
    }
    
    $response['success'] = true;
    $response['attempts'] = $attempts;
    $response['average_score'] = $average_score;
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
}

echo json_encode($response);
?>