--[[
	RoverNet Security Service
	
	Manages security events, attacks, and defenses.
	All "hacking" is represented as fictional game mechanics.
	
	Location: ServerScriptService.RoverNetServer.SecurityService
]]

local SecurityService = {}

-- Dependencies
local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)
local WebsiteService = require(script.Parent.WebsiteService)
local RoverNetShared = require(game.ReplicatedStorage.RoverNetShared)

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

local isInitialized = false

function SecurityService.Init()
	if isInitialized then
		warn("[SecurityService] Already initialized")
		return
	end
	
	isInitialized = true
	LoggingService.Log("[SecurityService] Initialized")
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- Get security stats for a company
function SecurityService.GetSecurityStats(companyData: any): any
	return companyData.Security
end

-- Trigger a fictional bot attack event
function SecurityService.TriggerBotAttack(companyData: any, websiteId: string, intensity: number): boolean
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		LoggingService.Log(string.format("Website %s not found for bot attack", websiteId), "WARN")
		return false
	end
	
	-- Calculate damage based on intensity and company's bot defense
	local botDefense = companyData.Security.BotDefense or 1
	local damageMultiplier = math.max(0.1, 1 - (botDefense / 20))  -- Higher defense = less damage
	
	local healthDamage = math.floor(Config.ATTACK_PARAMS.BotAttack.HealthDamage * intensity * damageMultiplier)
	local trafficPenalty = math.floor(Config.ATTACK_PARAMS.BotAttack.TrafficPenalty * intensity * damageMultiplier)
	
	-- Apply damage
	WebsiteService.AdjustHealth(companyData, websiteId, -healthDamage)
	WebsiteService.AdjustTrafficScore(companyData, websiteId, -trafficPenalty)
	
	-- Update last attack time
	companyData.Security.LastAttackAt = RoverNetShared.now()
	
	LoggingService.LogSecurityEvent(
		companyData.CompanyId,
		websiteId,
		"BotAttack",
		string.format("Intensity: %d, Health damage: %d, Traffic penalty: %d", intensity, healthDamage, trafficPenalty)
	)
	
	return true
end

-- Trigger a fictional corruption event
function SecurityService.ApplyCorruption(companyData: any, websiteId: string, severity: number): boolean
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		LoggingService.Log(string.format("Website %s not found for corruption", websiteId), "WARN")
		return false
	end
	
	-- Calculate damage based on severity and company's malware resistance
	local malwareResistance = companyData.Security.MalwareResistance or 1
	local damageMultiplier = math.max(0.1, 1 - (malwareResistance / 20))
	
	local sslDamage = math.floor(Config.ATTACK_PARAMS.Corruption.SSLDamage * severity * damageMultiplier)
	local healthDamage = math.floor(Config.ATTACK_PARAMS.Corruption.HealthDamage * severity * damageMultiplier)
	
	-- Apply damage
	WebsiteService.AdjustSSLLevel(companyData, websiteId, -sslDamage)
	WebsiteService.AdjustHealth(companyData, websiteId, -healthDamage)
	
	-- Update last attack time
	companyData.Security.LastAttackAt = RoverNetShared.now()
	
	LoggingService.LogSecurityEvent(
		companyData.CompanyId,
		websiteId,
		"Corruption",
		string.format("Severity: %d, SSL damage: %d, Health damage: %d", severity, sslDamage, healthDamage)
	)
	
	return true
end

-- Resolve a successful defense action
function SecurityService.ResolveDefenseSuccess(companyData: any, websiteId: string, defenseType: string): boolean
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		return false
	end
	
	-- Restore health based on defense type
	local healthRestore = 0
	local statIncrease = 0
	
	if defenseType == RoverNetShared.DefenseTypes.FIREWALL then
		healthRestore = Config.DEFENSE_BONUSES.Firewall.HealthRestore
		statIncrease = Config.DEFENSE_BONUSES.Firewall.StatIncrease
		
		-- Increase firewall level
		companyData.Security.FirewallLevel = RoverNetShared.clamp(
			companyData.Security.FirewallLevel + statIncrease,
			Config.MIN_SECURITY_STAT,
			Config.MAX_SECURITY_STAT
		)
		
	elseif defenseType == RoverNetShared.DefenseTypes.BOT_DEFENSE then
		healthRestore = Config.DEFENSE_BONUSES.BotDefense.HealthRestore
		statIncrease = Config.DEFENSE_BONUSES.BotDefense.StatIncrease
		
		-- Increase bot defense level
		companyData.Security.BotDefense = RoverNetShared.clamp(
			companyData.Security.BotDefense + statIncrease,
			Config.MIN_SECURITY_STAT,
			Config.MAX_SECURITY_STAT
		)
		
	elseif defenseType == RoverNetShared.DefenseTypes.MALWARE_SCAN then
		healthRestore = 20
		statIncrease = 2
		
		-- Increase malware resistance
		companyData.Security.MalwareResistance = RoverNetShared.clamp(
			companyData.Security.MalwareResistance + statIncrease,
			Config.MIN_SECURITY_STAT,
			Config.MAX_SECURITY_STAT
		)
	end
	
	-- Apply health restoration
	WebsiteService.AdjustHealth(companyData, websiteId, healthRestore)
	
	LoggingService.LogSecurityEvent(
		companyData.CompanyId,
		websiteId,
		"DefenseSuccess",
		string.format("Type: %s, Health restored: %d, Stat increased: %d", defenseType, healthRestore, statIncrease)
	)
	
	return true
end

-- Upgrade security stat (costs credits)
function SecurityService.UpgradeSecurityStat(companyData: any, statName: string, levels: number): boolean
	if not companyData.Security[statName] then
		LoggingService.Log(string.format("Invalid security stat: %s", statName), "WARN")
		return false
	end
	
	local currentLevel = companyData.Security[statName]
	local newLevel = RoverNetShared.clamp(
		currentLevel + levels,
		Config.MIN_SECURITY_STAT,
		Config.MAX_SECURITY_STAT
	)
	
	companyData.Security[statName] = newLevel
	
	LoggingService.Log(string.format("Upgraded %s from %d to %d for company %s", statName, currentLevel, newLevel, companyData.CompanyId))
	
	return true
end

return SecurityService
