--[[
	RoverNet Client Script
	
	Creates all UI dynamically and handles client-side logic.
	Communicates with server via RemoteEvents.
	
	Location: StarterPlayer.StarterPlayerScripts.RoverNetClient
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Wait for shared module
local RoverNetShared = ReplicatedStorage:WaitForChild("RoverNetShared")
local Shared = require(RoverNetShared)

-- Wait for remotes
local remotesFolder = ReplicatedStorage:WaitForChild("RoverNetRemotes")
local AdminRequest = remotesFolder:WaitForChild("AdminRequest")
local TaskRequest = remotesFolder:WaitForChild("TaskRequest")
local WebsiteRequest = remotesFolder:WaitForChild("WebsiteRequest")
local SecurityRequest = remotesFolder:WaitForChild("SecurityRequest")
local NotificationEvent = remotesFolder:WaitForChild("NotificationEvent")
local PlayerDataRequest = remotesFolder:WaitForChild("PlayerDataRequest")

-- ====================================================================
-- STATE
-- ====================================================================

local playerCredits = 0
local isAdmin = false
local currentWebsites = {}
local taskCooldowns = {}

-- ====================================================================
-- UI CREATION HELPERS
-- ====================================================================

local function createFrame(properties)
	local frame = Instance.new("Frame")
	for prop, value in pairs(properties) do
		frame[prop] = value
	end
	return frame
end

local function createTextLabel(properties)
	local label = Instance.new("TextLabel")
	-- Defaults
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	
	for prop, value in pairs(properties) do
		label[prop] = value
	end
	return label
end

local function createTextButton(properties)
	local button = Instance.new("TextButton")
	-- Defaults
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 16
	button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	
	for prop, value in pairs(properties) do
		button[prop] = value
	end
	
	-- Add corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	
	return button
end

local function createTextBox(properties)
	local textbox = Instance.new("TextBox")
	-- Defaults
	textbox.Font = Enum.Font.Gotham
	textbox.TextColor3 = Color3.new(1, 1, 1)
	textbox.TextSize = 16
	textbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	textbox.BorderSizePixel = 0
	textbox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
	textbox.ClearTextOnFocus = false
	
	for prop, value in pairs(properties) do
		textbox[prop] = value
	end
	
	-- Add corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = textbox
	
	return textbox
end

local function addListLayout(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, padding or 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

local function addPadding(parent, all)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, all)
	padding.PaddingBottom = UDim.new(0, all)
	padding.PaddingLeft = UDim.new(0, all)
	padding.PaddingRight = UDim.new(0, all)
	padding.Parent = parent
	return padding
end

-- ====================================================================
-- MAIN UI CONTAINER
-- ====================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoverNetUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- ====================================================================
-- HUD BAR (Top)
-- ====================================================================

local hudBar = createFrame({
	Name = "HUDBar",
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(20, 20, 20),
	BorderSizePixel = 0,
	Parent = screenGui,
})

local hudLayout = Instance.new("UIListLayout")
hudLayout.FillDirection = Enum.FillDirection.Horizontal
hudLayout.Padding = UDim.new(0, 20)
hudLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hudLayout.Parent = hudBar

addPadding(hudBar, 10)

local titleLabel = createTextLabel({
	Name = "Title",
	Text = "🌐 RoverNet",
	Size = UDim2.new(0, 150, 1, 0),
	TextSize = 24,
	TextColor3 = Color3.fromRGB(0, 200, 255),
	Parent = hudBar,
})

local creditsLabel = createTextLabel({
	Name = "Credits",
	Text = "Credits: 0",
	Size = UDim2.new(0, 200, 1, 0),
	TextSize = 20,
	Parent = hudBar,
})

local apiStatusLabel = createTextLabel({
	Name = "APIStatus",
	Text = "API: Connecting...",
	Size = UDim2.new(0, 200, 1, 0),
	TextSize = 16,
	TextColor3 = Color3.fromRGB(255, 200, 0),
	Parent = hudBar,
})

-- ====================================================================
-- NOTIFICATION PANEL (Bottom Right)
-- ====================================================================

local notificationContainer = createFrame({
	Name = "NotificationContainer",
	Size = UDim2.new(0, 350, 0, 400),
	Position = UDim2.new(1, -360, 1, -410),
	BackgroundTransparency = 1,
	Parent = screenGui,
})

local notificationLayout = addListLayout(notificationContainer, 10)
notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

local function showNotification(messageType, messageText)
	local notif = createFrame({
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		Parent = notificationContainer,
	})
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif
	
	addPadding(notif, 10)
	
	local typeLabel = createTextLabel({
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		Text = messageType:upper(),
		TextSize = 14,
		TextColor3 = messageType == "Success" and Color3.fromRGB(0, 255, 100) or
		             messageType == "Error" and Color3.fromRGB(255, 50, 50) or
		             messageType == "Warning" and Color3.fromRGB(255, 200, 0) or
		             Color3.fromRGB(100, 200, 255),
		Font = Enum.Font.GothamBold,
		Parent = notif,
	})
	
	local msgLabel = createTextLabel({
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 22),
		Text = messageText,
		TextSize = 16,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = notif,
	})
	
	-- Auto-remove after 5 seconds
	task.delay(5, function()
		notif:Destroy()
	end)
end

-- ====================================================================
-- TASK PANEL (Bottom Left)
-- ====================================================================

local taskPanel = createFrame({
	Name = "TaskPanel",
	Size = UDim2.new(0, 300, 0, 400),
	Position = UDim2.new(0, 10, 1, -410),
	BackgroundColor3 = Color3.fromRGB(25, 25, 25),
	BorderSizePixel = 0,
	Visible = false,
	Parent = screenGui,
})

local taskCorner = Instance.new("UICorner")
taskCorner.CornerRadius = UDim.new(0, 10)
taskCorner.Parent = taskPanel

addPadding(taskPanel, 15)

local taskTitle = createTextLabel({
	Name = "Title",
	Text = "📋 Tasks",
	Size = UDim2.new(1, 0, 0, 30),
	TextSize = 22,
	TextColor3 = Color3.fromRGB(0, 200, 255),
	Parent = taskPanel,
})

local taskScrollFrame = Instance.new("ScrollingFrame")
taskScrollFrame.Name = "TaskList"
taskScrollFrame.Size = UDim2.new(1, 0, 1, -40)
taskScrollFrame.Position = UDim2.new(0, 0, 0, 40)
taskScrollFrame.BackgroundTransparency = 1
taskScrollFrame.BorderSizePixel = 0
taskScrollFrame.ScrollBarThickness = 6
taskScrollFrame.Parent = taskPanel

addListLayout(taskScrollFrame, 10)

local tasks = {
	"DeliverData",
	"ProcessLogs",
	"PatchServer",
	"OptimizeDatabase",
	"AuditSecurity",
}

for _, taskName in ipairs(tasks) do
	local taskFrame = createFrame({
		Name = taskName,
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
		Parent = taskScrollFrame,
	})
	
	local taskFrameCorner = Instance.new("UICorner")
	taskFrameCorner.CornerRadius = UDim.new(0, 8)
	taskFrameCorner.Parent = taskFrame
	
	addPadding(taskFrame, 10)
	
	local taskNameLabel = createTextLabel({
		Text = taskName,
		Size = UDim2.new(1, -10, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		TextSize = 18,
		Parent = taskFrame,
	})
	
	local cooldownLabel = createTextLabel({
		Name = "Cooldown",
		Text = "Ready",
		Size = UDim2.new(1, -10, 0, 16),
		Position = UDim2.new(0, 0, 0, 22),
		TextSize = 14,
		TextColor3 = Color3.fromRGB(150, 150, 150),
		Parent = taskFrame,
	})
	
	local taskButton = createTextButton({
		Name = "CompleteButton",
		Text = "Complete Task",
		Size = UDim2.new(1, -10, 0, 30),
		Position = UDim2.new(0, 0, 1, -35),
		Parent = taskFrame,
	})
	
	taskButton.MouseButton1Click:Connect(function()
		TaskRequest:FireServer({
			action = "CompleteTask",
			taskName = taskName,
		})
	end)
end

local taskToggleButton = createTextButton({
	Name = "TaskToggle",
	Text = "📋 Tasks",
	Size = UDim2.new(0, 100, 0, 40),
	Position = UDim2.new(0, 10, 1, -50),
	Parent = screenGui,
})

taskToggleButton.MouseButton1Click:Connect(function()
	taskPanel.Visible = not taskPanel.Visible
end)

-- ====================================================================
-- WEBSITE PANEL (Center Left)
-- ====================================================================

local websitePanel = createFrame({
	Name = "WebsitePanel",
	Size = UDim2.new(0, 400, 0, 500),
	Position = UDim2.new(0, 320, 0.5, -250),
	BackgroundColor3 = Color3.fromRGB(25, 25, 25),
	BorderSizePixel = 0,
	Visible = false,
	Parent = screenGui,
})

local websiteCorner = Instance.new("UICorner")
websiteCorner.CornerRadius = UDim.new(0, 10)
websiteCorner.Parent = websitePanel

addPadding(websitePanel, 15)

local websiteTitle = createTextLabel({
	Name = "Title",
	Text = "🌐 Websites",
	Size = UDim2.new(1, 0, 0, 30),
	TextSize = 22,
	TextColor3 = Color3.fromRGB(0, 200, 255),
	Parent = websitePanel,
})

local createWebsiteButton = createTextButton({
	Name = "CreateWebsite",
	Text = "+ Create Website",
	Size = UDim2.new(1, 0, 0, 35),
	Position = UDim2.new(0, 0, 0, 40),
	BackgroundColor3 = Color3.fromRGB(0, 200, 100),
	Parent = websitePanel,
})

local websiteScrollFrame = Instance.new("ScrollingFrame")
websiteScrollFrame.Name = "WebsiteList"
websiteScrollFrame.Size = UDim2.new(1, 0, 1, -85)
websiteScrollFrame.Position = UDim2.new(0, 0, 0, 85)
websiteScrollFrame.BackgroundTransparency = 1
websiteScrollFrame.BorderSizePixel = 0
websiteScrollFrame.ScrollBarThickness = 6
websiteScrollFrame.Parent = websitePanel

addListLayout(websiteScrollFrame, 10)

local function refreshWebsiteList(websites)
	-- Clear existing
	for _, child in ipairs(websiteScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Add websites
	for _, website in ipairs(websites or {}) do
		local websiteFrame = createFrame({
			Name = website.WebsiteId,
			Size = UDim2.new(1, 0, 0, 120),
			BackgroundColor3 = Color3.fromRGB(35, 35, 35),
			BorderSizePixel = 0,
			Parent = websiteScrollFrame,
		})
		
		local wCorner = Instance.new("UICorner")
		wCorner.CornerRadius = UDim.new(0, 8)
		wCorner.Parent = websiteFrame
		
		addPadding(websiteFrame, 10)
		
		local domainLabel = createTextLabel({
			Text = website.Domain,
			Size = UDim2.new(1, 0, 0, 20),
			TextSize = 18,
			TextColor3 = Color3.fromRGB(0, 255, 200),
			Parent = websiteFrame,
		})
		
		local titleLabel = createTextLabel({
			Text = website.Title,
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 0, 22),
			TextSize = 16,
			Parent = websiteFrame,
		})
		
		local statsLabel = createTextLabel({
			Text = string.format("SSL: %d | Health: %d | Traffic: %d", 
				website.SSLLevel, website.Health, website.TrafficScore),
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 0, 42),
			TextSize = 14,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			Parent = websiteFrame,
		})
		
		local sslButton = createTextButton({
			Text = "↑ SSL",
			Size = UDim2.new(0.48, 0, 0, 30),
			Position = UDim2.new(0, 0, 1, -35),
			BackgroundColor3 = Color3.fromRGB(100, 100, 200),
			Parent = websiteFrame,
		})
		
		sslButton.MouseButton1Click:Connect(function()
			WebsiteRequest:FireServer({
				action = "IncreaseSSL",
				websiteId = website.WebsiteId,
			})
		end)
		
		local pagesButton = createTextButton({
			Text = "📄 Pages",
			Size = UDim2.new(0.48, 0, 0, 30),
			Position = UDim2.new(0.52, 0, 1, -35),
			Parent = websiteFrame,
		})
		
		pagesButton.MouseButton1Click:Connect(function()
			showNotification("Info", "Page editor coming soon!")
		end)
	end
	
	websiteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, addListLayout(websiteScrollFrame).AbsoluteContentSize.Y)
end

-- Create website dialog
createWebsiteButton.MouseButton1Click:Connect(function()
	local dialog = createFrame({
		Size = UDim2.new(0, 350, 0, 250),
		Position = UDim2.new(0.5, -175, 0.5, -125),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = screenGui,
	})
	
	local dCorner = Instance.new("UICorner")
	dCorner.CornerRadius = UDim.new(0, 10)
	dCorner.Parent = dialog
	
	addPadding(dialog, 20)
	
	local dialogTitle = createTextLabel({
		Text = "Create New Website",
		Size = UDim2.new(1, 0, 0, 30),
		TextSize = 20,
		Parent = dialog,
	})
	
	local domainBox = createTextBox({
		PlaceholderText = "example.rvn",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 45),
		Parent = dialog,
	})
	
	local titleBox = createTextBox({
		PlaceholderText = "Website Title",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 95),
		Parent = dialog,
	})
	
	local createBtn = createTextButton({
		Text = "Create",
		Size = UDim2.new(0.48, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -45),
		BackgroundColor3 = Color3.fromRGB(0, 200, 100),
		Parent = dialog,
	})
	
	local cancelBtn = createTextButton({
		Text = "Cancel",
		Size = UDim2.new(0.48, 0, 0, 40),
		Position = UDim2.new(0.52, 0, 1, -45),
		BackgroundColor3 = Color3.fromRGB(200, 50, 50),
		Parent = dialog,
	})
	
	createBtn.MouseButton1Click:Connect(function()
		local domain = domainBox.Text
		local title = titleBox.Text
		
		if domain ~= "" and title ~= "" then
			WebsiteRequest:FireServer({
				action = "CreateWebsite",
				domain = domain,
				title = title,
			})
			dialog:Destroy()
		end
	end)
	
	cancelBtn.MouseButton1Click:Connect(function()
		dialog:Destroy()
	end)
end)

local websiteToggleButton = createTextButton({
	Name = "WebsiteToggle",
	Text = "🌐 Websites",
	Size = UDim2.new(0, 120, 0, 40),
	Position = UDim2.new(0, 120, 1, -50),
	Parent = screenGui,
})

websiteToggleButton.MouseButton1Click:Connect(function()
	websitePanel.Visible = not websitePanel.Visible
	if websitePanel.Visible then
		WebsiteRequest:FireServer({ action = "ListWebsites" })
	end
end)

-- ====================================================================
-- ADMIN PANEL (Top Right)
-- ====================================================================

local adminPanel = createFrame({
	Name = "AdminPanel",
	Size = UDim2.new(0, 400, 0, 500),
	Position = UDim2.new(1, -410, 0, 60),
	BackgroundColor3 = Color3.fromRGB(40, 20, 20),
	BorderSizePixel = 0,
	Visible = false,
	Parent = screenGui,
})

local adminCorner = Instance.new("UICorner")
adminCorner.CornerRadius = UDim.new(0, 10)
adminCorner.Parent = adminPanel

addPadding(adminPanel, 15)

local adminTitle = createTextLabel({
	Text = "⚙️ Admin Panel",
	Size = UDim2.new(1, 0, 0, 30),
	TextSize = 22,
	TextColor3 = Color3.fromRGB(255, 100, 100),
	Parent = adminPanel,
})

local refreshPlayersButton = createTextButton({
	Text = "🔄 Refresh Players",
	Size = UDim2.new(1, 0, 0, 35),
	Position = UDim2.new(0, 0, 0, 40),
	BackgroundColor3 = Color3.fromRGB(100, 50, 50),
	Parent = adminPanel,
})

local adminScrollFrame = Instance.new("ScrollingFrame")
adminScrollFrame.Name = "PlayerList"
adminScrollFrame.Size = UDim2.new(1, 0, 1, -85)
adminScrollFrame.Position = UDim2.new(0, 0, 0, 85)
adminScrollFrame.BackgroundTransparency = 1
adminScrollFrame.BorderSizePixel = 0
adminScrollFrame.ScrollBarThickness = 6
adminScrollFrame.Parent = adminPanel

addListLayout(adminScrollFrame, 10)

refreshPlayersButton.MouseButton1Click:Connect(function()
	AdminRequest:FireServer({ action = "GetOnlinePlayers" })
end)

local adminToggleButton = createTextButton({
	Name = "AdminToggle",
	Text = "⚙️ Admin",
	Size = UDim2.new(0, 100, 0, 40),
	Position = UDim2.new(1, -110, 0, 60),
	BackgroundColor3 = Color3.fromRGB(150, 50, 50),
	Visible = false,
	Parent = screenGui,
})

adminToggleButton.MouseButton1Click:Connect(function()
	adminPanel.Visible = not adminPanel.Visible
end)

-- ====================================================================
-- EVENT HANDLERS
-- ====================================================================

NotificationEvent.OnClientEvent:Connect(function(data)
	if not data then return end
	
	local messageType = data.messageType or "Info"
	local messageText = data.messageText or "Notification"
	local payload = data.payload
	
	showNotification(messageType, messageText)
	
	-- Update credits if provided
	if payload and payload.credits then
		playerCredits = payload.credits
		creditsLabel.Text = "Credits: " .. Shared.formatCredits(playerCredits)
	end
	
	-- Update admin flag
	if payload and payload.isAdmin ~= nil then
		isAdmin = payload.isAdmin
		adminToggleButton.Visible = isAdmin
	end
	
	-- Update task cooldowns
	if payload and payload.cooldowns then
		taskCooldowns = payload.cooldowns
	end
	
	-- Update task-specific cooldown
	if payload and payload.taskName and payload.cooldown then
		taskCooldowns[payload.taskName] = payload.cooldown
	end
	
	-- Update websites
	if payload and payload.websites then
		currentWebsites = payload.websites
		refreshWebsiteList(currentWebsites)
	end
	
	-- Single website update
	if payload and payload.website then
		WebsiteRequest:FireServer({ action = "ListWebsites" })
	end
end)

AdminRequest.OnClientEvent:Connect(function(response)
	if not response then return end
	
	if response.action == "GetOnlinePlayers" and response.success then
		-- Clear list
		for _, child in ipairs(adminScrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		-- Add players
		for _, playerData in ipairs(response.data or {}) do
			local playerFrame = createFrame({
				Size = UDim2.new(1, 0, 0, 100),
				BackgroundColor3 = Color3.fromRGB(50, 30, 30),
				BorderSizePixel = 0,
				Parent = adminScrollFrame,
			})
			
			local pCorner = Instance.new("UICorner")
			pCorner.CornerRadius = UDim.new(0, 8)
			pCorner.Parent = playerFrame
			
			addPadding(playerFrame, 10)
			
			local nameLabel = createTextLabel({
				Text = playerData.Username,
				Size = UDim2.new(1, 0, 0, 20),
				TextSize = 18,
				Parent = playerFrame,
			})
			
			local creditsLabel = createTextLabel({
				Text = "Credits: " .. Shared.formatCredits(playerData.Credits),
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.new(0, 0, 0, 22),
				TextSize = 16,
				Parent = playerFrame,
			})
			
			local deltaBox = createTextBox({
				PlaceholderText = "Credit delta",
				Text = "100",
				Size = UDim2.new(0.48, 0, 0, 30),
				Position = UDim2.new(0, 0, 1, -35),
				Parent = playerFrame,
			})
			
			local applyButton = createTextButton({
				Text = "Apply",
				Size = UDim2.new(0.48, 0, 0, 30),
				Position = UDim2.new(0.52, 0, 1, -35),
				BackgroundColor3 = Color3.fromRGB(0, 150, 100),
				Parent = playerFrame,
			})
			
			applyButton.MouseButton1Click:Connect(function()
				local delta = tonumber(deltaBox.Text)
				if delta then
					AdminRequest:FireServer({
						action = "ModifyPlayerCredits",
						targetUserId = playerData.UserId,
						delta = delta,
						reason = "Admin adjustment",
					})
				end
			end)
		end
		
		adminScrollFrame.CanvasSize = UDim2.new(0, 0, 0, addListLayout(adminScrollFrame).AbsoluteContentSize.Y)
	end
end)

-- ====================================================================
-- TASK COOLDOWN UPDATER
-- ====================================================================

task.spawn(function()
	while true do
		task.wait(1)
		
		for taskName, cooldown in pairs(taskCooldowns) do
			if cooldown > 0 then
				taskCooldowns[taskName] = cooldown - 1
				
				-- Update UI
				local taskFrame = taskScrollFrame:FindFirstChild(taskName)
				if taskFrame then
					local cooldownLabel = taskFrame:FindFirstChild("Cooldown")
					if cooldownLabel then
						if taskCooldowns[taskName] > 0 then
							cooldownLabel.Text = "Cooldown: " .. Shared.formatDuration(taskCooldowns[taskName])
							cooldownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
						else
							cooldownLabel.Text = "Ready"
							cooldownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
						end
					end
				end
			end
		end
	end
end)

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

-- Fetch initial data
task.wait(2)
local success, initialData = pcall(function()
	return PlayerDataRequest:InvokeServer()
end)

if success and initialData then
	playerCredits = initialData.Credits or 0
	isAdmin = initialData.IsAdmin or false
	currentWebsites = initialData.Websites or {}
	
	creditsLabel.Text = "Credits: " .. Shared.formatCredits(playerCredits)
	apiStatusLabel.Text = "API: Connected"
	apiStatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	adminToggleButton.Visible = isAdmin
	
	refreshWebsiteList(currentWebsites)
	
	-- Request initial cooldowns
	TaskRequest:FireServer({ action = "GetCooldowns" })
else
	apiStatusLabel.Text = "API: Error"
	apiStatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
end

print("[RoverNetClient] Initialized")
