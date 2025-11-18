--[[
	RoverNet Main Server Script
	
	Initializes all services and handles player lifecycle.
	Wires up RemoteEvents and RemoteFunctions.
	
	Location: ServerScriptService.RoverNetServer.MainServer
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ====================================================================
-- SERVICES
-- ====================================================================

local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)
local ApiService = require(script.Parent.ApiService)
local PlayerDataStore = require(script.Parent.PlayerDataStore)
local EconomyService = require(script.Parent.EconomyService)
local CompanyService = require(script.Parent.CompanyService)
local WebsiteService = require(script.Parent.WebsiteService)
local SecurityService = require(script.Parent.SecurityService)
local TaskService = require(script.Parent.TaskService)
local AdminService = require(script.Parent.AdminService)
local RoverNetShared = require(ReplicatedStorage.RoverNetShared)

-- ====================================================================
-- REMOTES SETUP
-- ====================================================================

-- Create RemoteEvents folder if it doesn't exist
local remotesFolder = ReplicatedStorage:FindFirstChild("RoverNetRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "RoverNetRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local function getOrCreateRemote(name: string, className: string): any
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote
end

local AdminRequest = getOrCreateRemote("AdminRequest", "RemoteEvent")
local TaskRequest = getOrCreateRemote("TaskRequest", "RemoteEvent")
local WebsiteRequest = getOrCreateRemote("WebsiteRequest", "RemoteEvent")
local SecurityRequest = getOrCreateRemote("SecurityRequest", "RemoteEvent")
local NotificationEvent = getOrCreateRemote("NotificationEvent", "RemoteEvent")
local PlayerDataRequest = getOrCreateRemote("PlayerDataRequest", "RemoteFunction")

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

LoggingService.Init()
PlayerDataStore.Init()
EconomyService.Init()
CompanyService.Init()
WebsiteService.Init()
SecurityService.Init()
TaskService.Init()
AdminService.Init()

LoggingService.Log("=== RoverNet Server Starting ===")
LoggingService.Log("API Base URL: " .. Config.API_BASE_URL)
LoggingService.Log("API Saving: " .. tostring(Config.ENABLE_API_SAVING))

-- ====================================================================
-- PLAYER LIFECYCLE
-- ====================================================================

-- Send notification to player
local function notifyPlayer(player: Player, messageType: string, messageText: string, payload: any?)
	NotificationEvent:FireClient(player, {
		messageType = messageType,
		messageText = messageText,
		payload = payload,
	})
end

-- Player joined
Players.PlayerAdded:Connect(function(player)
	LoggingService.Log(string.format("Player %s (%d) joined", player.Name, player.UserId))
	
	-- Load player data
	local playerData = PlayerDataStore.LoadPlayer(player)
	
	-- Check if banned
	if playerData and playerData.Flags and playerData.Flags.IsBanned then
		player:Kick("You are banned from RoverNet.")
		return
	end
	
	-- Ensure company exists
	local company = CompanyService.EnsureCompanyForPlayer(player)
	
	-- Send initial data to client
	task.wait(1)  -- Give client time to set up
	
	notifyPlayer(player, RoverNetShared.NotificationTypes.SUCCESS, 
		string.format("Welcome to RoverNet! Credits: %d", playerData.Credits),
		{
			credits = playerData.Credits,
			isAdmin = playerData.Flags.IsAdmin,
			companyId = company.CompanyId,
		}
	)
	
	LoggingService.Log(string.format("Player %s initialization complete", player.Name))
end)

-- Player leaving
Players.PlayerRemoving:Connect(function(player)
	LoggingService.Log(string.format("Player %s (%d) leaving", player.Name, player.UserId))
	
	-- Save player data
	PlayerDataStore.SavePlayer(player)
	
	-- Save company data
	local company = CompanyService.GetCompanyByPlayer(player)
	if company then
		CompanyService.SaveCompany(company)
	end
	
	-- Clear task cooldowns
	TaskService.ClearPlayerCooldowns(player)
	
	-- Unload from cache
	PlayerDataStore.UnloadPlayer(player)
	
	LoggingService.Log(string.format("Player %s data saved", player.Name))
end)

-- ====================================================================
-- TASK REQUEST HANDLER
-- ====================================================================

TaskRequest.OnServerEvent:Connect(function(player, requestData)
	if not requestData or not requestData.action then
		return
	end
	
	if requestData.action == "CompleteTask" then
		local taskName = requestData.taskName
		if not taskName then
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Invalid task request")
			return
		end
		
		local success, message, cooldown = TaskService.CompleteTask(player, taskName)
		
		if success then
			local playerData = PlayerDataStore.GetPlayerData(player)
			local reward = Config.TASK_REWARDS[taskName]
			
			notifyPlayer(player, RoverNetShared.NotificationTypes.SUCCESS,
				string.format("+%d Credits from %s", reward, taskName),
				{
					credits = playerData.Credits,
					cooldown = cooldown,
					taskName = taskName,
				}
			)
		else
			notifyPlayer(player, RoverNetShared.NotificationTypes.WARNING,
				message or "Task failed",
				{
					remainingCooldown = cooldown,
					taskName = taskName,
				}
			)
		end
		
	elseif requestData.action == "GetCooldowns" then
		local cooldowns = TaskService.GetAllTaskCooldowns(player)
		notifyPlayer(player, RoverNetShared.NotificationTypes.INFO, "Cooldowns updated", {
			cooldowns = cooldowns,
		})
	end
end)

-- ====================================================================
-- WEBSITE REQUEST HANDLER
-- ====================================================================

WebsiteRequest.OnServerEvent:Connect(function(player, requestData)
	if not requestData or not requestData.action then
		return
	end
	
	local company = CompanyService.GetCompanyByPlayer(player)
	if not company then
		notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "No company found")
		return
	end
	
	if requestData.action == "CreateWebsite" then
		local domain = requestData.domain
		local title = requestData.title
		
		if not domain or not title then
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Invalid website data")
			return
		end
		
		-- Check if player can afford it
		if not EconomyService.CanAfford(player, Config.COSTS.CREATE_WEBSITE) then
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Insufficient credits")
			return
		end
		
		-- Create website
		local website = WebsiteService.CreateWebsite(company, domain, title)
		if website then
			EconomyService.RemoveCredits(player, Config.COSTS.CREATE_WEBSITE, "Create website: " .. domain)
			CompanyService.SaveCompany(company)
			
			local playerData = PlayerDataStore.GetPlayerData(player)
			notifyPlayer(player, RoverNetShared.NotificationTypes.SUCCESS,
				"Website created: " .. domain,
				{
					website = website,
					credits = playerData.Credits,
				}
			)
		else
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Failed to create website")
		end
		
	elseif requestData.action == "AddPage" then
		local websiteId = requestData.websiteId
		local pageTitle = requestData.pageTitle
		
		if not websiteId or not pageTitle then
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Invalid page data")
			return
		end
		
		-- Check if player can afford it
		if not EconomyService.CanAfford(player, Config.COSTS.CREATE_PAGE) then
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Insufficient credits")
			return
		end
		
		local page = WebsiteService.AddPage(company, websiteId, pageTitle)
		if page then
			EconomyService.RemoveCredits(player, Config.COSTS.CREATE_PAGE, "Create page: " .. pageTitle)
			CompanyService.SaveCompany(company)
			
			notifyPlayer(player, RoverNetShared.NotificationTypes.SUCCESS,
				"Page created: " .. pageTitle,
				{ page = page }
			)
		else
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Failed to create page")
		end
		
	elseif requestData.action == "IncreaseSSL" then
		local websiteId = requestData.websiteId
		
		if not websiteId then
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Invalid website ID")
			return
		end
		
		if not EconomyService.CanAfford(player, Config.COSTS.INCREASE_SSL) then
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Insufficient credits")
			return
		end
		
		if WebsiteService.AdjustSSLLevel(company, websiteId, 1) then
			EconomyService.RemoveCredits(player, Config.COSTS.INCREASE_SSL, "Increase SSL")
			CompanyService.SaveCompany(company)
			
			notifyPlayer(player, RoverNetShared.NotificationTypes.SUCCESS, "SSL level increased")
		else
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Failed to increase SSL")
		end
		
	elseif requestData.action == "UpdatePageElements" then
		local websiteId = requestData.websiteId
		local pageId = requestData.pageId
		local elements = requestData.elements
		
		if WebsiteService.UpdatePageElements(company, websiteId, pageId, elements) then
			CompanyService.SaveCompany(company)
			notifyPlayer(player, RoverNetShared.NotificationTypes.SUCCESS, "Page updated")
		else
			notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Failed to update page")
		end
		
	elseif requestData.action == "ListWebsites" then
		local websites = WebsiteService.ListWebsites(company)
		notifyPlayer(player, RoverNetShared.NotificationTypes.INFO, "Websites loaded", {
			websites = websites,
		})
	end
end)

-- ====================================================================
-- SECURITY REQUEST HANDLER
-- ====================================================================

SecurityRequest.OnServerEvent:Connect(function(player, requestData)
	if not requestData or not requestData.action then
		return
	end
	
	local company = CompanyService.GetCompanyByPlayer(player)
	if not company then
		return
	end
	
	if requestData.action == "DefenseSuccess" then
		local websiteId = requestData.websiteId
		local defenseType = requestData.defenseType
		
		if SecurityService.ResolveDefenseSuccess(company, websiteId, defenseType) then
			CompanyService.SaveCompany(company)
			notifyPlayer(player, RoverNetShared.NotificationTypes.SUCCESS,
				"Defense successful! Systems restored."
			)
		end
	end
end)

-- ====================================================================
-- ADMIN REQUEST HANDLER
-- ====================================================================

AdminRequest.OnServerEvent:Connect(function(player, requestData)
	if not requestData or not requestData.action then
		return
	end
	
	if not AdminService.IsAdmin(player) then
		notifyPlayer(player, RoverNetShared.NotificationTypes.ERROR, "Permission denied")
		return
	end
	
	if requestData.action == "GetOnlinePlayers" then
		local playerList = AdminService.GetOnlinePlayers(player)
		AdminRequest:FireClient(player, {
			action = "GetOnlinePlayers",
			success = true,
			data = playerList,
		})
		
	elseif requestData.action == "ModifyPlayerCredits" then
		local targetUserId = requestData.targetUserId
		local delta = requestData.delta
		local reason = requestData.reason
		
		local success, message = AdminService.ModifyPlayerCredits(player, targetUserId, delta, reason)
		
		AdminRequest:FireClient(player, {
			action = "ModifyPlayerCredits",
			success = success,
			message = message,
		})
		
		-- Notify target player if online
		if success then
			local targetPlayer = Players:GetPlayerByUserId(targetUserId)
			if targetPlayer then
				local playerData = PlayerDataStore.GetPlayerData(targetPlayer)
				notifyPlayer(targetPlayer, RoverNetShared.NotificationTypes.INFO,
					string.format("Credits adjusted by admin: %+d", delta),
					{ credits = playerData.Credits }
				)
			end
		end
		
	elseif requestData.action == "TriggerTestAttack" then
		local targetUserId = requestData.targetUserId
		local websiteId = requestData.websiteId
		local attackType = requestData.attackType
		
		local success, message = AdminService.TriggerTestAttack(player, targetUserId, websiteId, attackType)
		
		AdminRequest:FireClient(player, {
			action = "TriggerTestAttack",
			success = success,
			message = message,
		})
		
		-- Notify target player
		if success then
			local targetPlayer = Players:GetPlayerByUserId(targetUserId)
			if targetPlayer then
				notifyPlayer(targetPlayer, RoverNetShared.NotificationTypes.ATTACK,
					string.format("%s detected on your website!", attackType)
				)
			end
		end
	end
end)

-- ====================================================================
-- PLAYER DATA REQUEST FUNCTION
-- ====================================================================

PlayerDataRequest.OnServerInvoke = function(player)
	local playerData = PlayerDataStore.GetPlayerData(player)
	local company = CompanyService.GetCompanyByPlayer(player)
	
	if not playerData then
		return nil
	end
	
	-- Return safe summary (don't expose everything)
	return {
		Credits = playerData.Credits,
		IsAdmin = playerData.Flags and playerData.Flags.IsAdmin or false,
		CompanyId = playerData.CompanyId,
		CompanyName = company and company.Name or nil,
		Websites = company and WebsiteService.ListWebsites(company) or {},
		SecurityStats = company and company.Security or nil,
	}
end

-- ====================================================================
-- AUTO-SAVE
-- ====================================================================

task.spawn(function()
	while true do
		task.wait(Config.AUTO_SAVE_INTERVAL)
		
		LoggingService.Log("Auto-saving all player and company data...")
		local playerCount = PlayerDataStore.SaveAll()
		local companyCount = CompanyService.SaveAll()
		LoggingService.Log(string.format("Auto-save complete: %d players, %d companies", playerCount, companyCount))
	end
end)

-- ====================================================================
-- SHUTDOWN HANDLER
-- ====================================================================

game:BindToClose(function()
	LoggingService.Log("Server shutting down, saving all data...")
	PlayerDataStore.SaveAll()
	CompanyService.SaveAll()
	LoggingService.Log("Shutdown save complete")
	task.wait(2)  -- Give time for final saves
end)

LoggingService.Log("=== RoverNet Server Ready ===")
