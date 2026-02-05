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

$openai_api_key = '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';

$response = array();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $response['success'] = false;
    $response['message'] = 'Invalid request method';
    echo json_encode($response);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['user_id']) || !isset($input['quiz_name']) || 
    !isset($input['quiz_type']) || !isset($input['num_questions']) || 
    !isset($input['file_ids']) || !isset($input['file_contents'])) {
    $response['success'] = false;
    $response['message'] = 'Missing required fields';
    echo json_encode($response);
    exit;
}

$user_id = $input['user_id'];
$quiz_name = trim($input['quiz_name']);
$quiz_type = trim($input['quiz_type']);
$num_questions = intval($input['num_questions']);
$file_ids = $input['file_ids'];
$file_contents = $input['file_contents'];

if (empty($quiz_name) || $num_questions < 1 || $num_questions > 50) {
    $response['success'] = false;
    $response['message'] = 'Invalid quiz parameters';
    echo json_encode($response);
    exit;
}

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    if ($quiz_type === 'Multiple Choice') {
        $system_prompt = "You are a quiz generator. Create quiz questions that test understanding of the CONTENT and CONCEPTS within the provided text. Focus on facts, definitions, key concepts, and important details that someone studying this material should know. Do NOT ask questions about the document itself (like its format, structure, or meta-information).";
        
        $user_prompt = "Based on the following content, generate exactly {$num_questions} multiple choice questions. Each question should test knowledge of specific facts, concepts, or information from the material.

CONTENT TO STUDY:
{$file_contents}

IMPORTANT RULES:
- Ask about the actual information, facts, and concepts IN the content
- DO NOT ask about the document format, structure, or file type
- DO NOT ask generic questions like \"what is the main theme\"
- Focus on specific, testable knowledge from the material
- Each question must have exactly 4 options (A, B, C, D)
- Indicate the correct answer as an index (0 for A, 1 for B, 2 for C, 3 for D)

Return ONLY valid JSON in this exact format with no additional text:
[
  {
    \"question\": \"What is...\",
    \"options\": [\"Option A\", \"Option B\", \"Option C\", \"Option D\"],
    \"correct_answer\": 0
  }
]";

    } else {
        $system_prompt = "You are a quiz generator. Create quiz questions that test understanding of the CONTENT and CONCEPTS within the provided text. Focus on facts, definitions, key concepts, and important details that someone studying this material should know. Do NOT ask questions about the document itself (like its format, structure, or meta-information).";
        
        $user_prompt = "Based on the following content, generate exactly {$num_questions} short answer questions (answers should be 1-5 words). Each question should test knowledge of specific facts, concepts, or information from the material.

CONTENT TO STUDY:
{$file_contents}

IMPORTANT RULES:
- Ask about the actual information, facts, and concepts IN the content
- DO NOT ask about the document format, structure, or file type
- DO NOT ask generic questions like \"what is the main theme\"
- Focus on specific, testable knowledge from the material
- Answers must be brief (1-5 words)

Return ONLY valid JSON in this exact format with no additional text:
[
  {
    \"question\": \"What is...\",
    \"correct_answer\": \"brief answer\"
  }
]";
    }
    
    $openai_data = array(
        'model' => 'gpt-4o-mini',
        'messages' => array(
            array('role' => 'system', 'content' => $system_prompt),
            array('role' => 'user', 'content' => $user_prompt)
        ),
        'temperature' => 0.7,
        'max_tokens' => 4000,
        'response_format' => array('type' => 'json_object')
    );
    
    $ch = curl_init('https://api.openai.com/v1/chat/completions');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($openai_data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        'Content-Type: application/json',
        'Authorization: Bearer ' . $openai_api_key
    ));
    curl_setopt($ch, CURLOPT_TIMEOUT, 60);
    
    $openai_response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curl_error = curl_error($ch);
    curl_close($ch);
    
    if ($http_code !== 200) {
        $error_data = json_decode($openai_response, true);
        $response['success'] = false;
        $response['message'] = 'OpenAI API error: ' . ($error_data['error']['message'] ?? 'Unknown error');
        $response['http_code'] = $http_code;
        if ($curl_error) {
            $response['curl_error'] = $curl_error;
        }
        echo json_encode($response);
        exit;
    }
    
    $openai_result = json_decode($openai_response, true);
    
    if (!isset($openai_result['choices'][0]['message']['content'])) {
        $response['success'] = false;
        $response['message'] = 'Invalid OpenAI response structure';
        $response['debug_info'] = array(
            'full_response' => $openai_result,
            'response_preview' => substr($openai_response, 0, 1000)
        );
        echo json_encode($response);
        exit;
    }
    
    $generated_content = trim($openai_result['choices'][0]['message']['content']);
    
    if (empty($generated_content)) {
        $response['success'] = false;
        $response['message'] = 'OpenAI returned empty content';
        echo json_encode($response);
        exit;
    }
    
    $parsed_data = json_decode($generated_content, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        $response['success'] = false;
        $response['message'] = 'JSON parse error: ' . json_last_error_msg();
        $response['debug_info'] = array(
            'content' => substr($generated_content, 0, 1000),
            'json_error' => json_last_error_msg()
        );
        echo json_encode($response);
        exit;
    }
    
    $questions = null;
    
    if (is_array($parsed_data)) {
        if (isset($parsed_data[0]) && is_array($parsed_data[0]) && isset($parsed_data[0]['question'])) {
            $questions = $parsed_data;
        }
        else {
            foreach ($parsed_data as $value) {
                if (is_array($value) && isset($value[0]) && is_array($value[0]) && isset($value[0]['question'])) {
                    $questions = $value;
                    break;
                }
            }
        }
    }
    
    if (!is_array($questions) || count($questions) === 0) {
        $response['success'] = false;
        $response['message'] = 'Could not find questions array in AI response';
        $response['debug_info'] = array(
            'parsed_data' => $parsed_data,
            'generated_content' => substr($generated_content, 0, 1000)
        );
        echo json_encode($response);
        exit;
    }
    
    $validated_questions = array();
    
    foreach ($questions as $q) {
        if (!is_array($q) || !isset($q['question'])) {
            continue;
        }
        
        if ($quiz_type === 'Multiple Choice') {
            if (!isset($q['options']) || !isset($q['correct_answer'])) {
                continue;
            }
            
            if (!is_array($q['options']) || count($q['options']) < 3) {
                continue;
            }
            
            while (count($q['options']) < 4) {
                $q['options'][] = "Option " . chr(65 + count($q['options']));
            }
            $q['options'] = array_slice($q['options'], 0, 4);
            
            $correct_idx = is_numeric($q['correct_answer']) ? intval($q['correct_answer']) : 0;
            $q['correct_answer'] = max(0, min(3, $correct_idx));
            
            $validated_questions[] = $q;
            
        } else {
            if (!isset($q['correct_answer'])) {
                continue;
            }
            
            $answer = trim(strval($q['correct_answer']));
            $words = preg_split('/\s+/', $answer);
            if (count($words) > 5) {
                $answer = implode(' ', array_slice($words, 0, 5));
            }
            
            $q['correct_answer'] = $answer;
            $validated_questions[] = $q;
        }
    }
    
    if (count($validated_questions) === 0) {
        $response['success'] = false;
        $response['message'] = 'No valid questions after validation';
        echo json_encode($response);
        exit;
    }
    
    $validated_questions = array_slice($validated_questions, 0, $num_questions);
    
    $file_ids_string = implode(',', $file_ids);
    
    $stmt = $pdo->prepare("INSERT INTO quizzes (user_id, quiz_name, quiz_type, num_questions, file_ids) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$user_id, $quiz_name, $quiz_type, count($validated_questions), $file_ids_string]);
    
    $quiz_id = $pdo->lastInsertId();
    
    $questions_json = json_encode($validated_questions);
    $stmt = $pdo->prepare("INSERT INTO quiz_questions (quiz_id, questions_data) VALUES (?, ?)");
    $stmt->execute([$quiz_id, $questions_json]);
    
    $response['success'] = true;
    $response['message'] = 'AI quiz generated successfully';
    $response['quiz_id'] = $quiz_id;
    $response['questions_count'] = count($validated_questions);
    $response['quiz'] = [
        'id' => $quiz_id,
        'quiz_name' => $quiz_name,
        'quiz_type' => $quiz_type,
        'num_questions' => count($validated_questions),
        'created_date' => date('Y-m-d H:i:s')
    ];
    
} catch (PDOException $e) {
    $response['success'] = false;
    $response['message'] = 'Database error: ' . $e->getMessage();
} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = 'Error: ' . $e->getMessage();
}

echo json_encode($response);
?>