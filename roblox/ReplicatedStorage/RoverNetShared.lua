--[[
	RoverNet Shared Module
	
	Contains shared types, constants, and utility functions
	used by both client and server.
	
	Location: ReplicatedStorage.RoverNetShared
]]

local RoverNetShared = {}

-- ====================================================================
-- TYPE DEFINITIONS
-- ====================================================================

--[[ PlayerData Type
	{
		UserId: number,
		Username: string,
		Credits: number,
		CreatedAt: number,
		UpdatedAt: number,
		CompanyId: string?,
		Flags: {
			IsAdmin: boolean?,
			IsTestUser: boolean?,
			IsBanned: boolean?,
		}
	}
]]

--[[ CompanyData Type
	{
		CompanyId: string,
		OwnerUserId: number,
		Name: string,
		CreatedAt: number,
		UpdatedAt: number,
		Credits: number,
		Domains: { [string]: boolean },
		Websites: { [string]: WebsiteData },
		Security: SecurityStats,
	}
]]

--[[ WebsiteData Type
	{
		WebsiteId: string,
		Domain: string,
		Title: string,
		Pages: { [string]: PageData },
		SSLLevel: number,
		TrafficScore: number,
		Health: number,
	}
]]

--[[ PageData Type
	{
		PageId: string,
		Title: string,
		Elements: {
			{
				Type: "Label" | "Button",
				Text: string,
				ActionId: string?,
			}
		}
	}
]]

--[[ SecurityStats Type
	{
		FirewallLevel: number,
		BotDefense: number,
		MalwareResistance: number,
		LastAttackAt: number?,
	}
]]

-- ====================================================================
-- ENUMS
-- ====================================================================

RoverNetShared.TaskTypes = {
	DELIVER_DATA = "DeliverData",
	PROCESS_LOGS = "ProcessLogs",
	PATCH_SERVER = "PatchServer",
	OPTIMIZE_DATABASE = "OptimizeDatabase",
	AUDIT_SECURITY = "AuditSecurity",
}

RoverNetShared.SecurityEventTypes = {
	BOT_ATTACK = "BotAttack",
	CORRUPTION = "Corruption",
	GLITCH_STORM = "GlitchStorm",
	DATA_BREACH = "DataBreach",
}

RoverNetShared.ElementTypes = {
	LABEL = "Label",
	BUTTON = "Button",
	TEXTBOX = "TextBox",
}

RoverNetShared.DefenseTypes = {
	FIREWALL = "Firewall",
	BOT_DEFENSE = "BotDefense",
	MALWARE_SCAN = "MalwareScan",
}

RoverNetShared.NotificationTypes = {
	INFO = "Info",
	SUCCESS = "Success",
	WARNING = "Warning",
	ERROR = "Error",
	ATTACK = "Attack",
}

-- ====================================================================
-- UTILITY FUNCTIONS
-- ====================================================================

-- Deep copy a table
function RoverNetShared.deepCopy(original: any): any
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = RoverNetShared.deepCopy(value)
	end
	
	return copy
end

-- Safely convert value to number, with fallback
function RoverNetShared.safeNumber(value: any, fallback: number): number
	local num = tonumber(value)
	if num then
		return num
	end
	return fallback or 0
end

-- Get current timestamp
function RoverNetShared.now(): number
	return os.time()
end

-- Generate a unique ID with prefix
function RoverNetShared.generateId(prefix: string): string
	local timestamp = os.time()
	local random = math.random(10000, 99999)
	return string.format("%s_%d_%d", prefix, timestamp, random)
end

-- Clamp a value between min and max
function RoverNetShared.clamp(value: number, min: number, max: number): number
	if value < min then return min end
	if value > max then return max end
	return value
end

-- Check if a value is in a table (array)
function RoverNetShared.contains(tbl: {any}, value: any): boolean
	for _, v in ipairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

-- Get table size (works for dictionaries)
function RoverNetShared.tableSize(tbl: {[any]: any}): number
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- Merge two tables (shallow)
function RoverNetShared.merge(t1: {[any]: any}, t2: {[any]: any}): {[any]: any}
	local result = {}
	for k, v in pairs(t1) do
		result[k] = v
	end
	for k, v in pairs(t2) do
		result[k] = v
	end
	return result
end

-- Format credits with commas
function RoverNetShared.formatCredits(credits: number): string
	local formatted = tostring(credits)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

-- Format time duration in human-readable format
function RoverNetShared.formatDuration(seconds: number): string
	if seconds < 60 then
		return string.format("%ds", seconds)
	elseif seconds < 3600 then
		local mins = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%dm %ds", mins, secs)
	else
		local hours = math.floor(seconds / 3600)
		local mins = math.floor((seconds % 3600) / 60)
		return string.format("%dh %dm", hours, mins)
	end
end

-- Validate domain name format (simple check)
function RoverNetShared.isValidDomain(domain: string): boolean
	if not domain or #domain < 3 then
		return false
	end
	
	-- Must end with .rvn
	if not string.match(domain, "%.rvn$") then
		return false
	end
	
	-- Must not contain invalid characters
	if string.match(domain, "[^a-zA-Z0-9%-%.%_]") then
		return false
	end
	
	return true
end

-- Sanitize string for display
function RoverNetShared.sanitizeString(str: string, maxLength: number?): string
	if not str then return "" end
	
	-- Remove control characters
	str = string.gsub(str, "[%c]", "")
	
	-- Trim length if specified
	if maxLength and #str > maxLength then
		str = string.sub(str, 1, maxLength) .. "..."
	end
	
	return str
end

return RoverNetShared
