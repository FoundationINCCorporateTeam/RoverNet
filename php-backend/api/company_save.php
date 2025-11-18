<?php
/**
 * RoverNet Company Save API
 * 
 * Saves a company's data to JSON file storage.
 * Accepts full CompanyData object via POST JSON body.
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

$companyData = $requestData['data'];

// Validate required fields
if (!isset($companyData['CompanyId']) || empty($companyData['CompanyId'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid or missing CompanyId',
        'data' => null
    ]);
    exit();
}

$companyId = strval($companyData['CompanyId']);

// Sanitize companyId for filename (prevent directory traversal)
$safeCompanyId = preg_replace('/[^a-zA-Z0-9_-]/', '', $companyId);
if ($safeCompanyId !== $companyId) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid characters in CompanyId',
        'data' => null
    ]);
    exit();
}

// Ensure data directory exists
$dataDir = dirname(__DIR__) . '/data/companies';
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
$filePath = $dataDir . '/company_' . $safeCompanyId . '.json';

// Write data to file
$jsonData = json_encode($companyData, JSON_PRETTY_PRINT);
$result = @file_put_contents($filePath, $jsonData);

if ($result === false) {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to write company data to file',
        'data' => null
    ]);
    exit();
}

echo json_encode([
    'success' => true,
    'message' => 'Company data saved successfully',
    'data' => [
        'companyId' => $companyId,
        'bytesWritten' => $result
    ]
]);
?>
