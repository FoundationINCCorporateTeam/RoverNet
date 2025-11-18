--[[
	RoverNet Player Data Store
	
	Manages in-memory cache of player data.
	Handles loading from and saving to API.
	
	Location: ServerScriptService.RoverNetServer.PlayerDataStore
]]

local PlayerDataStore = {}

-- Dependencies
local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)
local ApiService = require(script.Parent.ApiService)
local RoverNetShared = require(game.ReplicatedStorage.RoverNetShared)

-- ====================================================================
-- PRIVATE STATE
-- ====================================================================

local playerDataCache = {}  -- [Player] = PlayerData
local isInitialized = false

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

function PlayerDataStore.Init()
	if isInitialized then
		warn("[PlayerDataStore] Already initialized")
		return
	end
	
	isInitialized = true
	LoggingService.Log("[PlayerDataStore] Initialized")
end

-- ====================================================================
-- PRIVATE HELPERS
-- ====================================================================

local function createDefaultPlayerData(player: Player): any
	return {
		UserId = player.UserId,
		Username = player.Name,
		Credits = Config.DEFAULT_STARTING_CREDITS,
		CreatedAt = RoverNetShared.now(),
		UpdatedAt = RoverNetShared.now(),
		CompanyId = nil,
		Flags = {
			IsAdmin = Config.ADMINS[player.UserId] or false,
			IsTestUser = false,
			IsBanned = false,
		}
	}
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- Load player data on join
function PlayerDataStore.LoadPlayer(player: Player): any
	LoggingService.Log(string.format("Loading data for player %s (%d)", player.Name, player.UserId))
	
	-- Try to load from API
	local apiData = ApiService.LoadPlayerData(player.UserId)
	
	local playerData
	if apiData then
		-- Player exists in API
		playerData = apiData
		playerData.Username = player.Name  -- Update username in case it changed
		playerData.UpdatedAt = RoverNetShared.now()
		LoggingService.Log(string.format("Loaded existing data for %s", player.Name))
	else
		-- New player, create defaults
		playerData = createDefaultPlayerData(player)
		LoggingService.Log(string.format("Created new data for %s", player.Name))
	end
	
	-- Cache it
	playerDataCache[player] = playerData
	
	return playerData
end

-- Save player data
function PlayerDataStore.SavePlayer(player: Player): boolean
	local playerData = playerDataCache[player]
	if not playerData then
		LoggingService.Log(string.format("No data to save for %s", player.Name), "WARN")
		return false
	end
	
	playerData.UpdatedAt = RoverNetShared.now()
	
	local success = ApiService.SavePlayerData(playerData)
	if success then
		LoggingService.Debug(string.format("Saved data for %s", player.Name))
	else
		LoggingService.Log(string.format("Failed to save data for %s", player.Name), "WARN")
	end
	
	return success
end

-- Get cached player data
function PlayerDataStore.GetPlayerData(player: Player): any?
	return playerDataCache[player]
end

-- Set player data (updates cache)
function PlayerDataStore.SetPlayerData(player: Player, data: any)
	playerDataCache[player] = data
end

-- Remove player from cache
function PlayerDataStore.UnloadPlayer(player: Player)
	playerDataCache[player] = nil
	LoggingService.Debug(string.format("Unloaded data for %s", player.Name))
end

-- Save all players (for shutdown or periodic save)
function PlayerDataStore.SaveAll(): number
	local count = 0
	for player, _ in pairs(playerDataCache) do
		if PlayerDataStore.SavePlayer(player) then
			count = count + 1
		end
	end
	LoggingService.Log(string.format("Saved data for %d players", count))
	return count
end

return PlayerDataStore
