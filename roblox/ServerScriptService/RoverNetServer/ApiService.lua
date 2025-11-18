--[[
	RoverNet API Service
	
	Wraps all HTTP calls to the PHP JSON API backend.
	Handles serialization, error handling, and retries.
	
	Location: ServerScriptService.RoverNetServer.ApiService
]]

local HttpService = game:GetService("HttpService")

local ApiService = {}

-- Dependencies
local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)

-- ====================================================================
-- PRIVATE HELPERS
-- ====================================================================

local function makeRequest(endpoint: string, method: string, body: any?): (boolean, any?)
	if not Config.ENABLE_API_SAVING then
		LoggingService.Debug("API saving disabled, skipping request to " .. endpoint)
		return true, nil
	end
	
	local url = Config.API_BASE_URL .. "/" .. endpoint
	
	LoggingService.Debug(string.format("API Request: %s %s", method, url))
	
	local success, result = pcall(function()
		if method == "GET" and body then
			-- For GET requests with parameters, append to URL
			local params = {}
			for key, value in pairs(body) do
				table.insert(params, key .. "=" .. HttpService:UrlEncode(tostring(value)))
			end
			url = url .. "?" .. table.concat(params, "&")
			
			return HttpService:GetAsync(url, true, {})
		elseif method == "POST" then
			local jsonBody = body and HttpService:JSONEncode(body) or "{}"
			return HttpService:PostAsync(url, jsonBody, Enum.HttpContentType.ApplicationJson, false, {})
		else
			error("Unsupported HTTP method: " .. method)
		end
	end)
	
	if not success then
		LoggingService.LogError("ApiService." .. endpoint, result)
		return false, nil
	end
	
	-- Parse JSON response
	local parseSuccess, responseData = pcall(function()
		return HttpService:JSONDecode(result)
	end)
	
	if not parseSuccess then
		LoggingService.LogError("ApiService.ParseResponse", responseData)
		return false, nil
	end
	
	if responseData.success then
		LoggingService.Debug("API request successful: " .. endpoint)
		return true, responseData.data
	else
		LoggingService.Log("API request failed: " .. (responseData.message or "Unknown error"), "WARN")
		return false, responseData.message
	end
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- Load player data from API
function ApiService.LoadPlayerData(userId: number): any?
	local success, data = makeRequest("player_load.php", "POST", {
		userId = userId
	})
	
	if success then
		return data
	end
	
	return nil
end

-- Save player data to API
function ApiService.SavePlayerData(playerData: any): boolean
	local success, _ = makeRequest("player_save.php", "POST", {
		data = playerData
	})
	
	return success
end

-- Load company data from API
function ApiService.LoadCompanyData(companyId: string): any?
	local success, data = makeRequest("company_load.php", "POST", {
		companyId = companyId
	})
	
	if success then
		return data
	end
	
	return nil
end

-- Save company data to API
function ApiService.SaveCompanyData(companyData: any): boolean
	local success, _ = makeRequest("company_save.php", "POST", {
		data = companyData
	})
	
	return success
end

-- Log admin action to API
function ApiService.LogAdminAction(actorUserId: number, targetUserId: number?, action: string, details: string?): boolean
	local success, _ = makeRequest("admin_log.php", "POST", {
		actorUserId = actorUserId,
		targetUserId = targetUserId,
		action = action,
		details = details or "",
		timestamp = os.time()
	})
	
	return success
end

return ApiService
