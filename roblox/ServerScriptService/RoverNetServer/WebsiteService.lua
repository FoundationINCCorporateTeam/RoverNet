--[[
	RoverNet Website Service
	
	Manages website creation, pages, and website-level operations.
	Handles SSL upgrades, page management, and element editing.
	
	Location: ServerScriptService.RoverNetServer.WebsiteService
]]

local WebsiteService = {}

-- Dependencies
local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)
local RoverNetShared = require(game.ReplicatedStorage.RoverNetShared)

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

local isInitialized = false

function WebsiteService.Init()
	if isInitialized then
		warn("[WebsiteService] Already initialized")
		return
	end
	
	isInitialized = true
	LoggingService.Log("[WebsiteService] Initialized")
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- Create a new website
function WebsiteService.CreateWebsite(companyData: any, domain: string, title: string): any?
	-- Validate website count
	local websiteCount = RoverNetShared.tableSize(companyData.Websites)
	if websiteCount >= Config.MAX_WEBSITES_PER_COMPANY then
		LoggingService.Log(string.format("Company %s has reached max websites", companyData.CompanyId), "WARN")
		return nil
	end
	
	-- Validate domain
	if not RoverNetShared.isValidDomain(domain) then
		LoggingService.Log(string.format("Invalid domain: %s", domain), "WARN")
		return nil
	end
	
	-- Check if domain is owned by company
	if not companyData.Domains[domain] then
		LoggingService.Log(string.format("Domain %s not owned by company %s", domain, companyData.CompanyId), "WARN")
		return nil
	end
	
	-- Generate website ID
	local websiteId = RoverNetShared.generateId("site")
	
	-- Create default homepage
	local homePageId = RoverNetShared.generateId("page")
	local homePage = {
		PageId = homePageId,
		Title = "Home",
		Elements = {
			{
				Type = RoverNetShared.ElementTypes.LABEL,
				Text = "Welcome to " .. title,
			},
			{
				Type = RoverNetShared.ElementTypes.LABEL,
				Text = "This is your new website!",
			}
		}
	}
	
	-- Create website data
	local websiteData = {
		WebsiteId = websiteId,
		Domain = domain,
		Title = title,
		Pages = {
			[homePageId] = homePage
		},
		SSLLevel = Config.DEFAULT_WEBSITE.SSLLevel,
		TrafficScore = Config.DEFAULT_WEBSITE.TrafficScore,
		Health = Config.DEFAULT_WEBSITE.Health,
	}
	
	companyData.Websites[websiteId] = websiteData
	
	LoggingService.Log(string.format("Created website %s (%s) for company %s", websiteId, domain, companyData.CompanyId))
	
	return websiteData
end

-- Get website by ID
function WebsiteService.GetWebsite(companyData: any, websiteId: string): any?
	return companyData.Websites[websiteId]
end

-- List all websites for a company
function WebsiteService.ListWebsites(companyData: any): {any}
	local websites = {}
	for _, website in pairs(companyData.Websites) do
		table.insert(websites, website)
	end
	return websites
end

-- Update website title
function WebsiteService.UpdateWebsiteTitle(companyData: any, websiteId: string, newTitle: string): boolean
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		LoggingService.Log(string.format("Website %s not found", websiteId), "WARN")
		return false
	end
	
	website.Title = RoverNetShared.sanitizeString(newTitle, 50)
	LoggingService.Debug(string.format("Updated title for website %s", websiteId))
	
	return true
end

-- Add a new page to a website
function WebsiteService.AddPage(companyData: any, websiteId: string, pageTitle: string): any?
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		LoggingService.Log(string.format("Website %s not found", websiteId), "WARN")
		return nil
	end
	
	-- Check page count
	local pageCount = RoverNetShared.tableSize(website.Pages)
	if pageCount >= Config.MAX_PAGES_PER_WEBSITE then
		LoggingService.Log(string.format("Website %s has reached max pages", websiteId), "WARN")
		return nil
	end
	
	-- Create new page
	local pageId = RoverNetShared.generateId("page")
	local pageData = {
		PageId = pageId,
		Title = RoverNetShared.sanitizeString(pageTitle, 50),
		Elements = {}
	}
	
	website.Pages[pageId] = pageData
	
	LoggingService.Log(string.format("Added page %s to website %s", pageId, websiteId))
	
	return pageData
end

-- Update page elements
function WebsiteService.UpdatePageElements(companyData: any, websiteId: string, pageId: string, elements: {any}): boolean
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		LoggingService.Log(string.format("Website %s not found", websiteId), "WARN")
		return false
	end
	
	local page = website.Pages[pageId]
	if not page then
		LoggingService.Log(string.format("Page %s not found in website %s", pageId, websiteId), "WARN")
		return false
	end
	
	-- Validate element count
	if #elements > Config.MAX_ELEMENTS_PER_PAGE then
		LoggingService.Log(string.format("Too many elements: %d > %d", #elements, Config.MAX_ELEMENTS_PER_PAGE), "WARN")
		return false
	end
	
	-- Validate and sanitize elements
	local sanitizedElements = {}
	for _, element in ipairs(elements) do
		if element.Type and element.Text then
			table.insert(sanitizedElements, {
				Type = element.Type,
				Text = RoverNetShared.sanitizeString(element.Text, 200),
				ActionId = element.ActionId,
			})
		end
	end
	
	page.Elements = sanitizedElements
	
	LoggingService.Debug(string.format("Updated elements for page %s", pageId))
	
	return true
end

-- Adjust SSL level
function WebsiteService.AdjustSSLLevel(companyData: any, websiteId: string, delta: number): boolean
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		LoggingService.Log(string.format("Website %s not found", websiteId), "WARN")
		return false
	end
	
	local newLevel = RoverNetShared.clamp(
		website.SSLLevel + delta,
		Config.MIN_SSL_LEVEL,
		Config.MAX_SSL_LEVEL
	)
	
	website.SSLLevel = newLevel
	
	LoggingService.Log(string.format("SSL level for website %s adjusted to %d", websiteId, newLevel))
	
	return true
end

-- Adjust website health
function WebsiteService.AdjustHealth(companyData: any, websiteId: string, delta: number): boolean
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		return false
	end
	
	website.Health = RoverNetShared.clamp(
		website.Health + delta,
		Config.MIN_WEBSITE_HEALTH,
		Config.MAX_WEBSITE_HEALTH
	)
	
	return true
end

-- Adjust traffic score
function WebsiteService.AdjustTrafficScore(companyData: any, websiteId: string, delta: number): boolean
	local website = WebsiteService.GetWebsite(companyData, websiteId)
	if not website then
		return false
	end
	
	website.TrafficScore = math.max(0, website.TrafficScore + delta)
	
	return true
end

return WebsiteService
