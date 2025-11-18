--[[
	RoverNet Config Module
	
	Stores all game configuration constants, including:
	- API endpoint URL
	- Admin user IDs
	- Economic settings
	- Rate limits
	- Feature toggles
	
	Location: ServerScriptService.RoverNetServer.Config
]]

local Config = {}

-- ====================================================================
-- API CONFIGURATION
-- ====================================================================

-- Base URL for the PHP JSON API backend
-- IMPORTANT: Change this to your actual web server URL before deployment
Config.API_BASE_URL = "https://example.com/rovernet/api"

-- Enable/disable API saving (for local testing without backend)
Config.ENABLE_API_SAVING = true

-- HTTP request timeout in seconds
Config.HTTP_TIMEOUT = 30

-- ====================================================================
-- ADMIN CONFIGURATION
-- ====================================================================

-- Dictionary of admin UserIds
-- Add your admin UserIds here: [UserId] = true
Config.ADMINS = {
	[1] = true,  -- Example admin (replace with real UserIds)
	[261] = true, -- Another example
}

-- ====================================================================
-- ECONOMY SETTINGS
-- ====================================================================

-- Starting credits for new players
Config.DEFAULT_STARTING_CREDITS = 1000

-- Starting company credits
Config.DEFAULT_COMPANY_CREDITS = 500

-- Credit costs for various actions
Config.COSTS = {
	CREATE_WEBSITE = 100,
	CREATE_PAGE = 50,
	INCREASE_SSL = 200,
	UPGRADE_FIREWALL = 300,
	UPGRADE_BOT_DEFENSE = 250,
	REGISTER_DOMAIN = 150,
}

-- Task rewards
Config.TASK_REWARDS = {
	DeliverData = 50,
	ProcessLogs = 75,
	PatchServer = 100,
	OptimizeDatabase = 125,
	AuditSecurity = 150,
}

-- ====================================================================
-- RATE LIMITS & CONSTRAINTS
-- ====================================================================

-- Maximum number of websites per company
Config.MAX_WEBSITES_PER_COMPANY = 10

-- Maximum number of pages per website
Config.MAX_PAGES_PER_WEBSITE = 20

-- Maximum number of elements per page
Config.MAX_ELEMENTS_PER_PAGE = 50

-- Maximum number of domains per company
Config.MAX_DOMAINS_PER_COMPANY = 20

-- Task cooldowns in seconds
Config.TASK_COOLDOWNS = {
	DeliverData = 60,       -- 1 minute
	ProcessLogs = 120,      -- 2 minutes
	PatchServer = 180,      -- 3 minutes
	OptimizeDatabase = 240, -- 4 minutes
	AuditSecurity = 300,    -- 5 minutes
}

-- Save interval in seconds (auto-save player data)
Config.AUTO_SAVE_INTERVAL = 300  -- 5 minutes

-- ====================================================================
-- GAME BALANCE SETTINGS
-- ====================================================================

-- SSL level constraints
Config.MIN_SSL_LEVEL = 0
Config.MAX_SSL_LEVEL = 5

-- Website health constraints
Config.MIN_WEBSITE_HEALTH = 0
Config.MAX_WEBSITE_HEALTH = 100

-- Security stats constraints
Config.MIN_SECURITY_STAT = 0
Config.MAX_SECURITY_STAT = 100

-- Default values for new websites
Config.DEFAULT_WEBSITE = {
	SSLLevel = 1,
	Health = 100,
	TrafficScore = 0,
}

-- Default security stats for new companies
Config.DEFAULT_SECURITY = {
	FirewallLevel = 1,
	BotDefense = 1,
	MalwareResistance = 1,
}

-- Attack parameters
Config.ATTACK_PARAMS = {
	BotAttack = {
		HealthDamage = 20,
		TrafficPenalty = 10,
	},
	Corruption = {
		SSLDamage = 1,
		HealthDamage = 15,
	},
}

-- Defense success bonuses
Config.DEFENSE_BONUSES = {
	Firewall = {
		HealthRestore = 10,
		StatIncrease = 5,
	},
	BotDefense = {
		HealthRestore = 15,
		StatIncrease = 3,
	},
}

-- ====================================================================
-- FEATURE FLAGS
-- ====================================================================

-- Enable debug logging
Config.DEBUG_MODE = false

-- Enable admin panel
Config.ENABLE_ADMIN_PANEL = true

-- Enable security events
Config.ENABLE_SECURITY_EVENTS = true

-- Enable auto-attacks (for testing)
Config.ENABLE_AUTO_ATTACKS = false
Config.AUTO_ATTACK_INTERVAL = 600  -- 10 minutes

return Config
