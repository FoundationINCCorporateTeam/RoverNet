<?php
/**
 * RoverNet Admin Log API
 * 
 * Appends admin actions to a centralized log file.
 * Accepts log entry via POST JSON body.
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
        'message' => 'Only POST requests are allowed'
    ]);
    exit();
}

// Get input
$input = file_get_contents('php://input');
$logEntry = json_decode($input, true);

// Validate required fields
if (!isset($logEntry['actorUserId']) || !is_numeric($logEntry['actorUserId'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid or missing actorUserId'
    ]);
    exit();
}

if (!isset($logEntry['action']) || empty($logEntry['action'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid or missing action'
    ]);
    exit();
}

if (!isset($logEntry['timestamp']) || !is_numeric($logEntry['timestamp'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid or missing timestamp'
    ]);
    exit();
}

// Ensure data directory exists
$dataDir = dirname(__DIR__) . '/data/logs';
if (!is_dir($dataDir)) {
    if (!mkdir($dataDir, 0755, true)) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create logs directory'
        ]);
        exit();
    }
}

// Construct file path
$filePath = $dataDir . '/admin_logs.json';

// Load existing logs or create new array
$logs = [];
if (file_exists($filePath)) {
    $fileContent = @file_get_contents($filePath);
    if ($fileContent !== false) {
        $decodedLogs = json_decode($fileContent, true);
        if (is_array($decodedLogs)) {
            $logs = $decodedLogs;
        }
    }
}

// Append new log entry
$logs[] = [
    'actorUserId' => intval($logEntry['actorUserId']),
    'targetUserId' => isset($logEntry['targetUserId']) ? intval($logEntry['targetUserId']) : null,
    'action' => strval($logEntry['action']),
    'details' => isset($logEntry['details']) ? strval($logEntry['details']) : '',
    'timestamp' => intval($logEntry['timestamp'])
];

// Write logs back to file
$jsonData = json_encode($logs, JSON_PRETTY_PRINT);
$result = @file_put_contents($filePath, $jsonData);

if ($result === false) {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to write admin log to file'
    ]);
    exit();
}

echo json_encode([
    'success' => true,
    'message' => 'Admin action logged successfully',
    'data' => [
        'totalLogs' => count($logs),
        'bytesWritten' => $result
    ]
]);
?>
