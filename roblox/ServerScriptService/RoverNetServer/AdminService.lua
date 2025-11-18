--[[
	RoverNet Admin Service
	
	Handles admin-only commands and operations.
	All actions are logged and require admin privileges.
	
	Location: ServerScriptService.RoverNetServer.AdminService
]]

local AdminService = {}

-- Dependencies
local Players = game:GetService("Players")
local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)
local EconomyService = require(script.Parent.EconomyService)
local PlayerDataStore = require(script.Parent.PlayerDataStore)
local CompanyService = require(script.Parent.CompanyService)
local SecurityService = require(script.Parent.SecurityService)
local ApiService = require(script.Parent.ApiService)

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

local isInitialized = false

function AdminService.Init()
	if isInitialized then
		warn("[AdminService] Already initialized")
		return
	end
	
	isInitialized = true
	LoggingService.Log("[AdminService] Initialized")
end

-- ====================================================================
-- PRIVATE HELPERS
-- ====================================================================

local function isAdmin(player: Player): boolean
	return Config.ADMINS[player.UserId] == true
end

local function logAdminAction(actor: Player, target: Player?, action: string, details: string?)
	LoggingService.LogAdminAction(actor, target, action, details)
	
	-- Also log to API
	ApiService.LogAdminAction(
		actor.UserId,
		target and target.UserId or nil,
		action,
		details
	)
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- Check if player is an admin
function AdminService.IsAdmin(player: Player): boolean
	return isAdmin(player)
end

-- Get list of online players (admin only)
function AdminService.GetOnlinePlayers(caller: Player): {any}?
	if not isAdmin(caller) then
		LoggingService.Log(string.format("%s attempted admin action without permission", caller.Name), "WARN")
		return nil
	end
	
	local playerList = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local credits = EconomyService.GetCredits(player)
		table.insert(playerList, {
			UserId = player.UserId,
			Username = player.Name,
			Credits = credits,
			IsAdmin = isAdmin(player),
		})
	end
	
	logAdminAction(caller, nil, "GetOnlinePlayers", string.format("%d players online", #playerList))
	
	return playerList
end

-- Modify player credits (admin only)
function AdminService.ModifyPlayerCredits(caller: Player, targetUserId: number, delta: number, reason: string?): (boolean, string?)
	if not isAdmin(caller) then
		return false, "Permission denied"
	end
	
	-- Find target player
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return false, "Target player not online"
	end
	
	-- Apply credit change
	local success = false
	if delta > 0 then
		success = EconomyService.AddCredits(targetPlayer, delta, reason or "Admin grant")
	elseif delta < 0 then
		success = EconomyService.RemoveCredits(targetPlayer, math.abs(delta), reason or "Admin deduction")
	else
		return false, "Delta must be non-zero"
	end
	
	if success then
		logAdminAction(
			caller,
			targetPlayer,
			"ModifyCredits",
			string.format("Delta: %+d, Reason: %s", delta, reason or "None")
		)
		return true, "Credits modified successfully"
	else
		return false, "Failed to modify credits"
	end
end

-- Trigger test attack on a player's website (admin only)
function AdminService.TriggerTestAttack(caller: Player, targetUserId: number, websiteId: string, attackType: string): (boolean, string?)
	if not isAdmin(caller) then
		return false, "Permission denied"
	end
	
	-- Find target player
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return false, "Target player not online"
	end
	
	-- Get target's company
	local company = CompanyService.GetCompanyByPlayer(targetPlayer)
	if not company then
		return false, "Target has no company"
	end
	
	-- Trigger attack
	local success = false
	if attackType == "BotAttack" then
		success = SecurityService.TriggerBotAttack(company, websiteId, 1.0)
	elseif attackType == "Corruption" then
		success = SecurityService.ApplyCorruption(company, websiteId, 1.0)
	else
		return false, "Invalid attack type"
	end
	
	if success then
		-- Save company data
		CompanyService.SaveCompany(company)
		
		logAdminAction(
			caller,
			targetPlayer,
			"TriggerTestAttack",
			string.format("Type: %s, Website: %s", attackType, websiteId)
		)
		return true, "Test attack triggered"
	else
		return false, "Failed to trigger attack"
	end
end

-- Get player details (admin only)
function AdminService.GetPlayerDetails(caller: Player, targetUserId: number): (boolean, any?)
	if not isAdmin(caller) then
		return false, nil
	end
	
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return false, nil
	end
	
	local playerData = PlayerDataStore.GetPlayerData(targetPlayer)
	local company = CompanyService.GetCompanyByPlayer(targetPlayer)
	
	logAdminAction(caller, targetPlayer, "GetPlayerDetails", "")
	
	return true, {
		PlayerData = playerData,
		CompanyData = company,
	}
end

-- Ban/unban player (admin only)
function AdminService.SetPlayerBanStatus(caller: Player, targetUserId: number, banned: boolean): (boolean, string?)
	if not isAdmin(caller) then
		return false, "Permission denied"
	end
	
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return false, "Target player not online"
	end
	
	local playerData = PlayerDataStore.GetPlayerData(targetPlayer)
	if not playerData then
		return false, "No player data"
	end
	
	playerData.Flags.IsBanned = banned
	PlayerDataStore.SetPlayerData(targetPlayer, playerData)
	PlayerDataStore.SavePlayer(targetPlayer)
	
	logAdminAction(
		caller,
		targetPlayer,
		banned and "BanPlayer" or "UnbanPlayer",
		""
	)
	
	if banned then
		-- Kick the player
		targetPlayer:Kick("You have been banned from RoverNet.")
	end
	
	return true, banned and "Player banned" or "Player unbanned"
end

return AdminService
