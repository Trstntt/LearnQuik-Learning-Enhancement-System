<?php

// FOR sign_up.dart

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

if (!isset($input['fname']) || !isset($input['lname']) || 
    !isset($input['username']) || !isset($input['password'])) {
    $response['success'] = false;
    $response['message'] = 'Missing required fields';
    echo json_encode($response);
    exit;
}

$first_name = trim($input['fname']);
$last_name = trim($input['lname']);
$user_name = trim($input['username']);
$user_pass = $input['password'];

if (empty($first_name) || empty($last_name) || empty($user_name) || empty($user_pass)) {
    $response['success'] = false;
    $response['message'] = 'All fields are required';
    echo json_encode($response);
    exit;
}

if (strlen($user_name) < 3) {
    $response['success'] = false;
    $response['message'] = 'Username must be at least 3 characters';
    echo json_encode($response);
    exit;
}

if (strlen($user_pass) < 6) {
    $response['success'] = false;
    $response['message'] = 'Password must be at least 6 characters';
    echo json_encode($response);
    exit;
}

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("SELECT id FROM user WHERE username = ?");
    $stmt->execute([$user_name]);
    
    if ($stmt->rowCount() > 0) {
        $response['success'] = false;
        $response['message'] = 'Username already exists';
        echo json_encode($response);
        exit;
    }
    
    $hashed_pass = password_hash($user_pass, PASSWORD_DEFAULT);
    
    $stmt = $pdo->prepare("INSERT INTO user (fname, lname, username, password) VALUES (?, ?, ?, ?)");
    $stmt->execute([$first_name, $last_name, $user_name, $hashed_pass]);
    
    $response['success'] = true;
    $response['message'] = 'Account created successfully';
    $response['user_id'] = $pdo->lastInsertId();
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
}

echo json_encode($response);
?>