--[[
	RoverNet Task Service
	
	Manages player tasks/jobs for earning credits.
	Handles task cooldowns and rewards.
	
	Location: ServerScriptService.RoverNetServer.TaskService
]]

local TaskService = {}

-- Dependencies
local Config = require(script.Parent.Config)
local LoggingService = require(script.Parent.LoggingService)
local EconomyService = require(script.Parent.EconomyService)
local RoverNetShared = require(game.ReplicatedStorage.RoverNetShared)

-- ====================================================================
-- PRIVATE STATE
-- ====================================================================

-- Per-player, per-task cooldowns
-- Structure: [player] = { [taskName] = nextAvailableTime }
local taskCooldowns = {}

local isInitialized = false

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

function TaskService.Init()
	if isInitialized then
		warn("[TaskService] Already initialized")
		return
	end
	
	isInitialized = true
	LoggingService.Log("[TaskService] Initialized")
end

-- ====================================================================
-- PRIVATE HELPERS
-- ====================================================================

local function isTaskAvailable(player: Player, taskName: string): (boolean, number?)
	if not taskCooldowns[player] then
		taskCooldowns[player] = {}
	end
	
	local nextAvailable = taskCooldowns[player][taskName]
	if not nextAvailable then
		return true, nil
	end
	
	local now = RoverNetShared.now()
	if now >= nextAvailable then
		return true, nil
	else
		return false, nextAvailable - now
	end
end

local function setTaskCooldown(player: Player, taskName: string, cooldownSeconds: number)
	if not taskCooldowns[player] then
		taskCooldowns[player] = {}
	end
	
	taskCooldowns[player][taskName] = RoverNetShared.now() + cooldownSeconds
end

-- ====================================================================
-- PUBLIC FUNCTIONS
-- ====================================================================

-- Attempt to complete a task
function TaskService.CompleteTask(player: Player, taskName: string): (boolean, string?, number?)
	-- Validate task exists
	if not Config.TASK_REWARDS[taskName] then
		return false, "Invalid task", nil
	end
	
	-- Check cooldown
	local available, remainingTime = isTaskAvailable(player, taskName)
	if not available then
		return false, "Task on cooldown", remainingTime
	end
	
	-- Get reward and cooldown
	local reward = Config.TASK_REWARDS[taskName]
	local cooldown = Config.TASK_COOLDOWNS[taskName]
	
	-- Award credits
	local success = EconomyService.AddCredits(player, reward, "Task: " .. taskName)
	if not success then
		return false, "Failed to award credits", nil
	end
	
	-- Set cooldown
	setTaskCooldown(player, taskName, cooldown)
	
	LoggingService.Log(string.format("Player %s completed task %s, earned %d credits", player.Name, taskName, reward))
	
	return true, "Task completed", cooldown
end

-- Get remaining cooldown for a task
function TaskService.GetTaskCooldown(player: Player, taskName: string): number
	local available, remainingTime = isTaskAvailable(player, taskName)
	if available then
		return 0
	else
		return remainingTime or 0
	end
end

-- Get all task cooldowns for a player
function TaskService.GetAllTaskCooldowns(player: Player): {[string]: number}
	local cooldowns = {}
	
	for taskName, _ in pairs(Config.TASK_REWARDS) do
		cooldowns[taskName] = TaskService.GetTaskCooldown(player, taskName)
	end
	
	return cooldowns
end

-- Clear player cooldowns (when they leave)
function TaskService.ClearPlayerCooldowns(player: Player)
	taskCooldowns[player] = nil
end

return TaskService
