--[[
	RoverNet Company Service
	
	Manages company data and operations.
	Handles company creation, domain management, and company credits.
	
	Location: ServerScriptService.RoverNetServer.CompanyService
]]

local CompanyService = {}

-- Dependencies
local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)
local PlayerDataStore = require(script.Parent.PlayerDataStore)
local ApiService = require(script.Parent.ApiService)
local RoverNetShared = require(game.ReplicatedStorage.RoverNetShared)

-- ====================================================================
-- PRIVATE STATE
-- ====================================================================

local companyCache = {}  -- [companyId] = CompanyData
local isInitialized = false

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

function CompanyService.Init()
	if isInitialized then
		warn("[CompanyService] Already initialized")
		return
	end
	
	isInitialized = true
	LoggingService.Log("[CompanyService] Initialized")
end

-- ====================================================================
-- PRIVATE HELPERS
-- ====================================================================

local function createDefaultCompany(player: Player): any
	local companyId = RoverNetShared.generateId("cmp")
	local defaultDomain = string.lower(player.Name) .. ".rvn"
	
	-- Sanitize domain
	defaultDomain = string.gsub(defaultDomain, "[^a-z0-9%-]", "")
	if not string.match(defaultDomain, "%.rvn$") then
		defaultDomain = defaultDomain .. ".rvn"
	end
	
	return {
		CompanyId = companyId,
		OwnerUserId = player.UserId,
		Name = player.Name .. " Labs",
		CreatedAt = RoverNetShared.now(),
		UpdatedAt = RoverNetShared.now(),
		Credits = Config.DEFAULT_COMPANY_CREDITS,
		Domains = {
			[defaultDomain] = true
		},
		Websites = {},
		Security = RoverNetShared.deepCopy(Config.DEFAULT_SECURITY),
	}
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- Ensure player has a company (create if doesn't exist)
function CompanyService.EnsureCompanyForPlayer(player: Player): any
	local playerData = PlayerDataStore.GetPlayerData(player)
	if not playerData then
		LoggingService.Log(string.format("No player data for %s when ensuring company", player.Name), "WARN")
		return nil
	end
	
	-- Check if player already has a company
	if playerData.CompanyId then
		local company = CompanyService.GetCompanyById(playerData.CompanyId)
		if company then
			return company
		end
	end
	
	-- Create new company
	local newCompany = createDefaultCompany(player)
	companyCache[newCompany.CompanyId] = newCompany
	
	-- Update player data with company ID
	playerData.CompanyId = newCompany.CompanyId
	PlayerDataStore.SetPlayerData(player, playerData)
	
	-- Save to API
	CompanyService.SaveCompany(newCompany)
	PlayerDataStore.SavePlayer(player)
	
	LoggingService.Log(string.format("Created company %s for %s", newCompany.CompanyId, player.Name))
	
	return newCompany
end

-- Get company by player
function CompanyService.GetCompanyByPlayer(player: Player): any?
	local playerData = PlayerDataStore.GetPlayerData(player)
	if not playerData or not playerData.CompanyId then
		return nil
	end
	
	return CompanyService.GetCompanyById(playerData.CompanyId)
end

-- Get company by ID
function CompanyService.GetCompanyById(companyId: string): any?
	-- Check cache first
	if companyCache[companyId] then
		return companyCache[companyId]
	end
	
	-- Try to load from API
	local companyData = ApiService.LoadCompanyData(companyId)
	if companyData then
		companyCache[companyId] = companyData
		return companyData
	end
	
	return nil
end

-- Save company data
function CompanyService.SaveCompany(companyData: any): boolean
	if not companyData or not companyData.CompanyId then
		LoggingService.Log("Invalid company data for save", "WARN")
		return false
	end
	
	companyData.UpdatedAt = RoverNetShared.now()
	companyCache[companyData.CompanyId] = companyData
	
	local success = ApiService.SaveCompanyData(companyData)
	if success then
		LoggingService.Debug(string.format("Saved company %s", companyData.CompanyId))
	else
		LoggingService.Log(string.format("Failed to save company %s", companyData.CompanyId), "WARN")
	end
	
	return success
end

-- Add domain to company
function CompanyService.AddDomain(companyData: any, domain: string): boolean
	if not RoverNetShared.isValidDomain(domain) then
		LoggingService.Log(string.format("Invalid domain: %s", domain), "WARN")
		return false
	end
	
	local domainCount = RoverNetShared.tableSize(companyData.Domains)
	if domainCount >= Config.MAX_DOMAINS_PER_COMPANY then
		LoggingService.Log(string.format("Company %s has reached max domains", companyData.CompanyId), "WARN")
		return false
	end
	
	companyData.Domains[domain] = true
	LoggingService.Log(string.format("Added domain %s to company %s", domain, companyData.CompanyId))
	
	return true
end

-- Add credits to company
function CompanyService.AddCreditsToCompany(companyData: any, amount: number): boolean
	if amount <= 0 then
		return false
	end
	
	companyData.Credits = (companyData.Credits or 0) + amount
	LoggingService.Debug(string.format("Added %d credits to company %s", amount, companyData.CompanyId))
	
	return true
end

-- Spend company credits
function CompanyService.SpendCompanyCredits(companyData: any, amount: number): boolean
	if amount <= 0 then
		return false
	end
	
	local currentCredits = companyData.Credits or 0
	if currentCredits < amount then
		LoggingService.Log(string.format("Company %s has insufficient credits: %d < %d", companyData.CompanyId, currentCredits, amount), "WARN")
		return false
	end
	
	companyData.Credits = currentCredits - amount
	LoggingService.Debug(string.format("Spent %d credits from company %s", amount, companyData.CompanyId))
	
	return true
end

-- Save all companies (for shutdown)
function CompanyService.SaveAll(): number
	local count = 0
	for _, companyData in pairs(companyCache) do
		if CompanyService.SaveCompany(companyData) then
			count = count + 1
		end
	end
	LoggingService.Log(string.format("Saved data for %d companies", count))
	return count
end

return CompanyService
