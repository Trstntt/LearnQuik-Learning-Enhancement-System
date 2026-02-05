<?php

// FOR main.dart

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

if (!isset($input['username']) || !isset($input['password'])) {
    $response['success'] = false;
    $response['message'] = 'Username and password are required';
    echo json_encode($response);
    exit;
}

$user_name = trim($input['username']);
$user_pass = $input['password'];

if (empty($user_name) || empty($user_pass)) {
    $response['success'] = false;
    $response['message'] = 'Username and password cannot be empty';
    echo json_encode($response);
    exit;
}

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("SELECT id, fname, lname, username, password FROM user WHERE username = ?");
    $stmt->execute([$user_name]);
    
    if ($stmt->rowCount() === 0) {
        $response['success'] = false;
        $response['message'] = 'Invalid username or password';
        echo json_encode($response);
        exit;
    }
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (password_verify($user_pass, $user['password'])) {
        $response['success'] = true;
        $response['message'] = 'Login successful';
        $response['user'] = [
            'id' => $user['id'],
            'fname' => $user['fname'],
            'lname' => $user['lname'],
            'username' => $user['username']
        ];
    } else {
        $response['success'] = false;
        $response['message'] = 'Invalid username or password';
    }
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
}

echo json_encode($response);
?>