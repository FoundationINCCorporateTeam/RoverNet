<?php
/**
 * RoverNet Player Load API
 * 
 * Loads a player's data from JSON file storage.
 * Accepts userId via POST or GET.
 * Returns player data if exists, or null if new player.
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

// Get userId from POST or GET
$userId = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    $userId = isset($data['userId']) ? intval($data['userId']) : null;
} else {
    $userId = isset($_GET['userId']) ? intval($_GET['userId']) : null;
}

// Validate input
if (!$userId || $userId <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid userId provided',
        'data' => null
    ]);
    exit();
}

// Construct file path
$dataDir = dirname(__DIR__) . '/data/players';
$filePath = $dataDir . '/player_' . $userId . '.json';

// Check if file exists
if (file_exists($filePath)) {
    $fileContent = @file_get_contents($filePath);
    
    if ($fileContent === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to read player data file',
            'data' => null
        ]);
        exit();
    }
    
    $playerData = json_decode($fileContent, true);
    
    if ($playerData === null) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to decode player data',
            'data' => null
        ]);
        exit();
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Player data loaded successfully',
        'data' => $playerData
    ]);
} else {
    // Player doesn't exist yet - return null data so Roblox can create defaults
    echo json_encode([
        'success' => true,
        'message' => 'Player not found, ready for creation',
        'data' => null
    ]);
}
?>
