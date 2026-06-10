local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimalConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalConfig"))

local player = Players.LocalPlayer
local animalAbilityFeedback = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AnimalAbilityFeedback")

local fallbackColors = {
	CardDark = Color3.fromRGB(30, 30, 30),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(230, 230, 230),
	BorderLight = Color3.fromRGB(255, 255, 255),
}

local function loadColors()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local theme = shared and shared:FindFirstChild("Theme")
	local colorsModule = theme and theme:FindFirstChild("Colors")

	if colorsModule and colorsModule:IsA("ModuleScript") then
		local ok, colors = pcall(require, colorsModule)
		if ok and typeof(colors) == "table" then
			return colors
		end
	end

	return fallbackColors
end

local Colors = loadColors()
local cooldownEndsBySlot: {[number]: number} = {}
local slotViews: {[number]: {button: Frame, key: TextLabel, name: TextLabel, cooldown: TextLabel}} = {}

local gui = Instance.new("ScreenGui")
gui.Name = "AnimalAbilityBar"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position = UDim2.new(0.5, 0, 1, -28)
container.Size = UDim2.fromOffset(86, 76)
container.BackgroundTransparency = 1
container.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = container

local function getAnimalType(): string?
	local character = player.Character
	if not character or character:GetAttribute("IsAnimalCharacter") ~= true then
		return nil
	end

	local animalType = character:GetAttribute("AnimalType")
	return typeof(animalType) == "string" and animalType or nil
end

local function getAbilitiesForCurrentAnimal()
	local animalType = getAnimalType()
	local stats = animalType and AnimalConfig[animalType]
	local abilities = stats and stats.Abilities

	if typeof(abilities) == "table" then
		return abilities
	end

	return nil
end

local function clearSlots()
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	table.clear(slotViews)
end

local function createSlot(slot: number, abilityName: string)
	local button = Instance.new("Frame")
	button.Name = "Slot" .. tostring(slot)
	button.LayoutOrder = slot
	button.Size = UDim2.fromOffset(76, 68)
	button.BackgroundColor3 = Colors.CardDark
	button.BackgroundTransparency = 0.15
	button.BorderSizePixel = 0
	button.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors.BorderLight
	stroke.Thickness = 1
	stroke.Transparency = 0.55
	stroke.Parent = button

	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.Position = UDim2.fromOffset(8, 5)
	key.Size = UDim2.fromOffset(18, 18)
	key.BackgroundTransparency = 1
	key.Font = Enum.Font.GothamBold
	key.Text = tostring(slot)
	key.TextColor3 = Colors.TextSecondary
	key.TextSize = 14
	key.Parent = button

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Position = UDim2.fromOffset(6, 24)
	name.Size = UDim2.new(1, -12, 0, 20)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.Text = string.upper(abilityName)
	name.TextColor3 = Colors.TextPrimary
	name.TextScaled = true
	name.TextWrapped = true
	name.Parent = button

	local nameSize = Instance.new("UITextSizeConstraint")
	nameSize.MinTextSize = 10
	nameSize.MaxTextSize = 16
	nameSize.Parent = name

	local cooldown = Instance.new("TextLabel")
	cooldown.Name = "Cooldown"
	cooldown.Position = UDim2.fromOffset(6, 45)
	cooldown.Size = UDim2.new(1, -12, 0, 16)
	cooldown.BackgroundTransparency = 1
	cooldown.Font = Enum.Font.GothamMedium
	cooldown.Text = ""
	cooldown.TextColor3 = Colors.TextSecondary
	cooldown.TextSize = 12
	cooldown.Parent = button

	slotViews[slot] = {
		button = button,
		key = key,
		name = name,
		cooldown = cooldown,
	}
end

local function refreshSlots()
	clearSlots()

	local abilities = getAbilitiesForCurrentAnimal()
	if not abilities then
		gui.Enabled = false
		return
	end

	for abilityName, abilityConfig in pairs(abilities) do
		if typeof(abilityConfig) == "table" and typeof(abilityConfig.Slot) == "number" then
			createSlot(abilityConfig.Slot, abilityName)
		end
	end

	gui.Enabled = next(slotViews) ~= nil
end

local function bindCharacter(character: Model)
	refreshSlots()

	character:GetAttributeChangedSignal("IsAnimalCharacter"):Connect(refreshSlots)
	character:GetAttributeChangedSignal("AnimalType"):Connect(refreshSlots)
end

if player.Character then
	bindCharacter(player.Character)
end

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function()
	gui.Enabled = false
	clearSlots()
	table.clear(cooldownEndsBySlot)
end)

animalAbilityFeedback.OnClientEvent:Connect(function(status: string, _abilityName: string?, slot: number?, value: number?)
	if typeof(slot) ~= "number" then
		return
	end

	if status == "Activated" and typeof(value) == "number" then
		cooldownEndsBySlot[slot] = os.clock() + value
	elseif status == "Cooldown" and typeof(value) == "number" then
		cooldownEndsBySlot[slot] = os.clock() + value
	elseif status == "NoAbility" then
		cooldownEndsBySlot[slot] = nil
	end
end)

RunService.RenderStepped:Connect(function()
	for slot, view in pairs(slotViews) do
		local cooldownEnd = cooldownEndsBySlot[slot]
		local remaining = cooldownEnd and math.max(0, cooldownEnd - os.clock()) or 0

		if remaining > 0 then
			view.cooldown.Text = tostring(math.ceil(remaining))
			view.button.BackgroundTransparency = 0.32
		else
			cooldownEndsBySlot[slot] = nil
			view.cooldown.Text = ""
			view.button.BackgroundTransparency = 0.15
		end
	end
end)
