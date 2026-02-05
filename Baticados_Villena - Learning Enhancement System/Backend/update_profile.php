<?php

// FOR profile.dart

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

if (!isset($input['user_id']) || !isset($input['fname']) || 
    !isset($input['lname']) || !isset($input['username'])) {
    $response['success'] = false;
    $response['message'] = 'Missing required fields';
    echo json_encode($response);
    exit;
}

$user_id = $input['user_id'];
$first_name = trim($input['fname']);
$last_name = trim($input['lname']);
$user_name = trim($input['username']);
$new_password = isset($input['password']) ? $input['password'] : null;

if (empty($first_name) || empty($last_name) || empty($user_name)) {
    $response['success'] = false;
    $response['message'] = 'Name and username cannot be empty';
    echo json_encode($response);
    exit;
}

if (strlen($user_name) < 3) {
    $response['success'] = false;
    $response['message'] = 'Username must be at least 3 characters';
    echo json_encode($response);
    exit;
}

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("SELECT id FROM user WHERE username = ? AND id != ?");
    $stmt->execute([$user_name, $user_id]);
    
    if ($stmt->rowCount() > 0) {
        $response['success'] = false;
        $response['message'] = 'Username already taken by another user';
        echo json_encode($response);
        exit;
    }
    
    if (!empty($new_password) && $new_password !== '********') {
        if (strlen($new_password) < 6) {
            $response['success'] = false;
            $response['message'] = 'Password must be at least 6 characters';
            echo json_encode($response);
            exit;
        }
        
        $hashed_pass = password_hash($new_password, PASSWORD_DEFAULT);
        $stmt = $pdo->prepare("UPDATE user SET fname = ?, lname = ?, username = ?, password = ? WHERE id = ?");
        $stmt->execute([$first_name, $last_name, $user_name, $hashed_pass, $user_id]);
    } else {
        $stmt = $pdo->prepare("UPDATE user SET fname = ?, lname = ?, username = ? WHERE id = ?");
        $stmt->execute([$first_name, $last_name, $user_name, $user_id]);
    }
    
    $stmt = $pdo->prepare("SELECT id, fname, lname, username FROM user WHERE id = ?");
    $stmt->execute([$user_id]);
    $updated_user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $response['success'] = true;
    $response['message'] = 'Profile updated successfully';
    $response['user'] = $updated_user;
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
}

echo json_encode($response);
?>