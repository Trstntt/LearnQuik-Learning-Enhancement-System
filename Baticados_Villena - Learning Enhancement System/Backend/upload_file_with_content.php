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

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$db_host = 'localhost';
$db_name = 'learnquik';
$db_user = 'root';
$db_pass = '';

$response = array();

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    $input = json_decode(file_get_contents('php://input'), true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception('Invalid JSON input: ' . json_last_error_msg());
    }

    if (!isset($input['user_id']) || !isset($input['file_name']) || !isset($input['file_content'])) {
        throw new Exception('Missing required fields');
    }

    $user_id = $input['user_id'];
    $file_name = trim($input['file_name']);
    $file_content = $input['file_content'];

    if (empty($file_name)) {
        throw new Exception('File name cannot be empty');
    }

    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8mb4", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $extracted_text = '';
    $file_extension = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));
    
    $decoded_content = base64_decode($file_content);
    
    if ($decoded_content === false) {
        throw new Exception('Failed to decode file content');
    }
    
    if ($file_extension === 'txt') {
        $extracted_text = $decoded_content;
        
    } elseif ($file_extension === 'docx') {
        if (!class_exists('ZipArchive')) {
            throw new Exception('DOCX files are not supported on this server. Please convert your file to .txt format or enable the ZIP extension in PHP.');
        }
        $extracted_text = extractDocxText($decoded_content);
        
    } elseif ($file_extension === 'pdf') {
        $extracted_text = extractPdfText($decoded_content);
        
    } elseif ($file_extension === 'doc') {
        throw new Exception('Please convert .doc files to .txt format');
        
    } else {
        $extracted_text = $decoded_content;
    }
    
    $extracted_text = preg_replace('/\r\n|\r/', "\n", $extracted_text);
    $extracted_text = preg_replace('/\n{3,}/', "\n\n", $extracted_text);
    $extracted_text = trim($extracted_text);
    
    if (empty($extracted_text) || strlen($extracted_text) < 10) {
        throw new Exception("Could not extract readable text from $file_name. Please ensure the file contains text content.");
    }
    
    $stmt = $pdo->prepare("INSERT INTO uploaded_files (user_id, file_name, file_content) VALUES (?, ?, ?)");
    $stmt->execute([$user_id, $file_name, $extracted_text]);
    
    $file_id = $pdo->lastInsertId();
    
    $response['success'] = true;
    $response['message'] = 'File uploaded successfully';
    $response['file_id'] = $file_id;
    $response['content_length'] = strlen($extracted_text);
    $response['file'] = [
        'id' => $file_id,
        'file_name' => $file_name,
        'upload_date' => date('Y-m-d H:i:s')
    ];
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = $e->getMessage();
}

echo json_encode($response);
exit;

function extractDocxText($content) {
    $temp_file = tempnam(sys_get_temp_dir(), 'docx_');
    file_put_contents($temp_file, $content);
    
    try {
        $zip = new ZipArchive();
        
        if ($zip->open($temp_file) !== TRUE) {
            unlink($temp_file);
            throw new Exception("Could not open DOCX file");
        }
        
        $xml_content = $zip->getFromName('word/document.xml');
        
        if ($xml_content === false) {
            $zip->close();
            unlink($temp_file);
            throw new Exception("Could not find document.xml in DOCX");
        }
        
        $zip->close();
        unlink($temp_file);
        
        $xml = simplexml_load_string($xml_content);
        
        if ($xml === false) {
            throw new Exception("Could not parse document XML");
        }
        
        $xml->registerXPathNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main');
        $text_nodes = $xml->xpath('//w:t');
        
        $text = '';
        foreach ($text_nodes as $node) {
            $text .= (string)$node . ' ';
        }
        
        return trim($text);
        
    } catch (Exception $e) {
        if (file_exists($temp_file)) {
            unlink($temp_file);
        }
        throw new Exception("DOCX extraction error: " . $e->getMessage());
    }
}

function extractPdfText($content) {
    $temp_file = tempnam(sys_get_temp_dir(), 'pdf_');
    file_put_contents($temp_file, $content);
    
    try {
        if (function_exists('shell_exec')) {
            $output = @shell_exec("pdftotext " . escapeshellarg($temp_file) . " - 2>&1");
            
            if (!empty($output) && strpos($output, 'command not found') === false && strlen($output) > 20) {
                unlink($temp_file);
                return trim($output);
            }
        }
        
        unlink($temp_file);
        throw new Exception("PDF extraction requires conversion. Please convert to .txt or .docx format, or install pdftotext on the server.");
        
    } catch (Exception $e) {
        if (file_exists($temp_file)) {
            unlink($temp_file);
        }
        throw $e;
    }
}
?>