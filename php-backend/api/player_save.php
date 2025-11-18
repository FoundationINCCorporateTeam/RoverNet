<?php
/**
 * RoverNet Player Save API
 * 
 * Saves a player's data to JSON file storage.
 * Accepts full PlayerData object via POST JSON body.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'success' => false,
        'message' => 'Only POST requests are allowed',
        'data' => null
    ]);
    exit();
}

// Get input
$input = file_get_contents('php://input');
$requestData = json_decode($input, true);

// Validate input structure
if (!isset($requestData['data']) || !is_array($requestData['data'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing or invalid data field',
        'data' => null
    ]);
    exit();
}

$playerData = $requestData['data'];

// Validate required fields
if (!isset($playerData['UserId']) || !is_numeric($playerData['UserId']) || intval($playerData['UserId']) <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid or missing UserId',
        'data' => null
    ]);
    exit();
}

$userId = intval($playerData['UserId']);

// Ensure data directory exists
$dataDir = dirname(__DIR__) . '/data/players';
if (!is_dir($dataDir)) {
    if (!mkdir($dataDir, 0755, true)) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create data directory',
            'data' => null
        ]);
        exit();
    }
}

// Construct file path
$filePath = $dataDir . '/player_' . $userId . '.json';

// Write data to file
$jsonData = json_encode($playerData, JSON_PRETTY_PRINT);
$result = @file_put_contents($filePath, $jsonData);

if ($result === false) {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to write player data to file',
        'data' => null
    ]);
    exit();
}

echo json_encode([
    'success' => true,
    'message' => 'Player data saved successfully',
    'data' => [
        'userId' => $userId,
        'bytesWritten' => $result
    ]
]);
?>
