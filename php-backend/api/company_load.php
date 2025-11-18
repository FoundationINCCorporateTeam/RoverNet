<?php
/**
 * RoverNet Company Load API
 * 
 * Loads a company's data from JSON file storage.
 * Accepts companyId via POST or GET.
 * Returns company data if exists, or null if not found.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get companyId from POST or GET
$companyId = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    $companyId = isset($data['companyId']) ? strval($data['companyId']) : null;
} else {
    $companyId = isset($_GET['companyId']) ? strval($_GET['companyId']) : null;
}

// Validate input
if (!$companyId || empty($companyId)) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid companyId provided',
        'data' => null
    ]);
    exit();
}

// Sanitize companyId for filename (prevent directory traversal)
$safeCompanyId = preg_replace('/[^a-zA-Z0-9_-]/', '', $companyId);
if ($safeCompanyId !== $companyId) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid characters in companyId',
        'data' => null
    ]);
    exit();
}

// Construct file path
$dataDir = dirname(__DIR__) . '/data/companies';
$filePath = $dataDir . '/company_' . $safeCompanyId . '.json';

// Check if file exists
if (file_exists($filePath)) {
    $fileContent = @file_get_contents($filePath);
    
    if ($fileContent === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to read company data file',
            'data' => null
        ]);
        exit();
    }
    
    $companyData = json_decode($fileContent, true);
    
    if ($companyData === null) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to decode company data',
            'data' => null
        ]);
        exit();
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Company data loaded successfully',
        'data' => $companyData
    ]);
} else {
    // Company doesn't exist
    echo json_encode([
        'success' => true,
        'message' => 'Company not found',
        'data' => null
    ]);
}
?>
