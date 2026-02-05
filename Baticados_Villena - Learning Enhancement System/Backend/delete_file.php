<?php

// FOR home.dart

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

if (!isset($input['file_id']) || !isset($input['user_id'])) {
    $response['success'] = false;
    $response['message'] = 'Missing required fields';
    echo json_encode($response);
    exit;
}

$file_id = $input['file_id'];
$user_id = $input['user_id'];

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("SELECT id FROM uploaded_files WHERE id = ? AND user_id = ?");
    $stmt->execute([$file_id, $user_id]);
    
    if ($stmt->rowCount() === 0) {
        $response['success'] = false;
        $response['message'] = 'File not found or you do not have permission to delete it';
        echo json_encode($response);
        exit;
    }
    
    $stmt = $pdo->prepare("DELETE FROM uploaded_files WHERE id = ? AND user_id = ?");
    $stmt->execute([$file_id, $user_id]);
    
    $response['success'] = true;
    $response['message'] = 'File deleted successfully';
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
}

echo json_encode($response);
?>