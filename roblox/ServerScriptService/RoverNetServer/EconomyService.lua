--[[
	RoverNet Economy Service
	
	Manages player-level credits and transactions.
	All economy operations go through this service.
	
	Location: ServerScriptService.RoverNetServer.EconomyService
]]

local EconomyService = {}

-- Dependencies
local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)
local PlayerDataStore = require(script.Parent.PlayerDataStore)

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

local isInitialized = false

function EconomyService.Init()
	if isInitialized then
		warn("[EconomyService] Already initialized")
		return
	end
	
	isInitialized = true
	LoggingService.Log("[EconomyService] Initialized")
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- Get player's current credits
function EconomyService.GetCredits(player: Player): number
	local playerData = PlayerDataStore.GetPlayerData(player)
	if not playerData then
		LoggingService.Log(string.format("No data for %s when getting credits", player.Name), "WARN")
		return 0
	end
	
	return playerData.Credits or 0
end

-- Add credits to player
function EconomyService.AddCredits(player: Player, amount: number, reason: string?): boolean
	if amount <= 0 then
		LoggingService.Log("Cannot add negative or zero credits", "WARN")
		return false
	end
	
	local playerData = PlayerDataStore.GetPlayerData(player)
	if not playerData then
		LoggingService.Log(string.format("No data for %s when adding credits", player.Name), "WARN")
		return false
	end
	
	playerData.Credits = (playerData.Credits or 0) + amount
	PlayerDataStore.SetPlayerData(player, playerData)
	
	LoggingService.LogEconomyChange(player, amount, reason)
	
	return true
end

-- Remove credits from player
function EconomyService.RemoveCredits(player: Player, amount: number, reason: string?): boolean
	if amount <= 0 then
		LoggingService.Log("Cannot remove negative or zero credits", "WARN")
		return false
	end
	
	local playerData = PlayerDataStore.GetPlayerData(player)
	if not playerData then
		LoggingService.Log(string.format("No data for %s when removing credits", player.Name), "WARN")
		return false
	end
	
	local currentCredits = playerData.Credits or 0
	if currentCredits < amount then
		LoggingService.Log(string.format("%s has insufficient credits: %d < %d", player.Name, currentCredits, amount), "WARN")
		return false
	end
	
	playerData.Credits = currentCredits - amount
	PlayerDataStore.SetPlayerData(player, playerData)
	
	LoggingService.LogEconomyChange(player, -amount, reason)
	
	return true
end

-- Check if player can afford something
function EconomyService.CanAfford(player: Player, amount: number): boolean
	local credits = EconomyService.GetCredits(player)
	return credits >= amount
end

-- Transfer credits between players (admin feature)
function EconomyService.TransferCredits(fromPlayer: Player, toPlayer: Player, amount: number, reason: string?): boolean
	if amount <= 0 then
		return false
	end
	
	if not EconomyService.CanAfford(fromPlayer, amount) then
		return false
	end
	
	if EconomyService.RemoveCredits(fromPlayer, amount, reason or "Transfer to " .. toPlayer.Name) then
		return EconomyService.AddCredits(toPlayer, amount, reason or "Transfer from " .. fromPlayer.Name)
	end
	
	return false
end

return EconomyService
