-- BackpackUI.client.lua (READY + ROBUST)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local invEvent = ReplicatedStorage:WaitForChild("InventoryEvent")

local CAPACITY = 5
local BACKPACK_TOOL_NAME = "Backpack"

-- ===== align with StatsCard =====
local RIGHT_PAD = 20
local BOTTOM_Y = 0.95
local EXTRA_DOWN = 0.03 -- опусти чуть ниже (подбирай 0.02..0.05)

local gui = Instance.new("ScreenGui")
gui.Name = "BackpackUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")
gui.Enabled = false

local container = Instance.new("Frame")
container.Name = "Container"
container.Parent = gui
local BOTTOM_PAD = 24
local SIDE_PAD = 20

container.AnchorPoint = Vector2.new(1, 1)
container.Position = UDim2.new(1, -SIDE_PAD, 1, -BOTTOM_PAD)

container.Size = UDim2.fromOffset(220, 90)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
container.BackgroundTransparency = 0.15
container.BorderSizePixel = 0

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = container

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Transparency = 0.75
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Parent = container

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = container
title.Position = UDim2.fromOffset(10, 6)
title.Size = UDim2.new(1, -20, 0, 22)
title.BackgroundTransparency = 1
title.Text = "BACKPACK"
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

local capacityText = Instance.new("TextLabel")
capacityText.Name = "CapacityText"
capacityText.Parent = container
capacityText.Position = UDim2.fromOffset(10, 32)
capacityText.Size = UDim2.new(1, -20, 0, 22)
capacityText.BackgroundTransparency = 1
capacityText.Text = ("0 / %d"):format(CAPACITY)
capacityText.Font = Enum.Font.GothamMedium
capacityText.TextSize = 14
capacityText.TextColor3 = Color3.fromRGB(230, 230, 230)
capacityText.TextXAlignment = Enum.TextXAlignment.Left

local barBG = Instance.new("Frame")
barBG.Name = "BarBG"
barBG.Parent = container
barBG.Position = UDim2.fromOffset(10, 64)
barBG.Size = UDim2.new(1, -20, 0, 10)
barBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
barBG.BorderSizePixel = 0

local barBGCorner = Instance.new("UICorner")
barBGCorner.CornerRadius = UDim.new(0, 6)
barBGCorner.Parent = barBG

local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Parent = barBG
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
barFill.BorderSizePixel = 0

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(0, 6)
barFillCorner.Parent = barFill

local function updateUI(stack: {string})
	local used = #stack
	local percent = math.clamp(used / CAPACITY, 0, 1)

	capacityText.Text = string.format("%d / %d", used, CAPACITY)
	barFill.Size = UDim2.new(percent, 0, 1, 0)

	if percent < 0.6 then
		barFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	elseif percent < 0.9 then
		barFill.BackgroundColor3 = Color3.fromRGB(230, 200, 80)
	else
		barFill.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
	end
end

local function isBackpackToolEquipped(): boolean
	local char = player.Character
	if not char then return false end
	local tool = char:FindFirstChild(BACKPACK_TOOL_NAME)
	return tool ~= nil and tool:IsA("Tool")
end

local lastVisible: boolean? = nil
RunService.RenderStepped:Connect(function()
	local visible = isBackpackToolEquipped()
	if visible ~= lastVisible then
		gui.Enabled = visible
		lastVisible = visible
	end
end)

invEvent.OnClientEvent:Connect(function(action, data)
	if action == "invUpdate" and typeof(data) == "table" then
		updateUI(data)
	end
end)

updateUI({})
