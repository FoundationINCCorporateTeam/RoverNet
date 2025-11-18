--[[
	RoverNet Logging Service
	
	Provides centralized logging for the game.
	Handles console output and forwarding to admin log API.
	
	Location: ServerScriptService.RoverNetServer.LoggingService
]]

local LoggingService = {}

-- Dependencies
local Config = require(script.Parent.Config)

-- ====================================================================
-- PRIVATE STATE
-- ====================================================================

local isInitialized = false

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

function LoggingService.Init()
	if isInitialized then
		warn("[LoggingService] Already initialized")
		return
	end
	
	isInitialized = true
	print("[LoggingService] Initialized")
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- General logging
function LoggingService.Log(message: string, level: string?)
	level = level or "INFO"
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local formattedMessage = string.format("[%s] [%s] %s", timestamp, level, message)
	
	if level == "ERROR" then
		warn(formattedMessage)
	elseif Config.DEBUG_MODE or level ~= "DEBUG" then
		print(formattedMessage)
	end
end

-- Log economy changes
function LoggingService.LogEconomyChange(player: Player, delta: number, reason: string?)
	local message = string.format(
		"Player %s (%d) credits changed by %+d. Reason: %s",
		player.Name,
		player.UserId,
		delta,
		reason or "Unknown"
	)
	LoggingService.Log(message, "ECONOMY")
end

-- Log admin actions (also forwards to API)
function LoggingService.LogAdminAction(actor: Player, target: Player?, action: string, details: string?)
	local message = string.format(
		"Admin %s (%d) performed action: %s on %s. Details: %s",
		actor.Name,
		actor.UserId,
		action,
		target and string.format("%s (%d)", target.Name, target.UserId) or "N/A",
		details or "None"
	)
	LoggingService.Log(message, "ADMIN")
	
	-- Forward to API (done in AdminService to avoid circular dependency)
end

-- Log security events
function LoggingService.LogSecurityEvent(companyId: string, websiteId: string, eventType: string, details: string?)
	local message = string.format(
		"Security Event [%s] on website %s (company %s). Details: %s",
		eventType,
		websiteId,
		companyId,
		details or "None"
	)
	LoggingService.Log(message, "SECURITY")
end

-- Log errors with stack trace
function LoggingService.LogError(context: string, err: any)
	local message = string.format(
		"Error in %s: %s",
		context,
		tostring(err)
	)
	LoggingService.Log(message, "ERROR")
end

-- Debug logging (only when DEBUG_MODE is enabled)
function LoggingService.Debug(message: string)
	if Config.DEBUG_MODE then
		LoggingService.Log(message, "DEBUG")
	end
end

return LoggingService
