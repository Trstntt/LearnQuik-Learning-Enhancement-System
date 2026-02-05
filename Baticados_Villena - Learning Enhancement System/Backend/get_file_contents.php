<?php

// FOR quiz_creation.dart

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

if (!isset($input['file_ids']) || !is_array($input['file_ids'])) {
    $response['success'] = false;
    $response['message'] = 'Missing or invalid file_ids';
    echo json_encode($response);
    exit;
}

$file_ids = $input['file_ids'];

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $placeholders = implode(',', array_fill(0, count($file_ids), '?'));
    $stmt = $pdo->prepare("SELECT file_name, file_content FROM uploaded_files WHERE id IN ($placeholders)");
    $stmt->execute($file_ids);
    
    $files = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $combined_content = '';
    foreach ($files as $file) {
        $combined_content .= "\n\n--- Content from: " . $file['file_name'] . " ---\n";
        $combined_content .= $file['file_content'] ?? 'No content available';
    }
    
    $response['success'] = true;
    $response['content'] = trim($combined_content);
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
}

echo json_encode($response);
?>