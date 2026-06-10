local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local characterConnections: {RBXScriptConnection} = {}

local fallbackColors = {
	CardDark = Color3.fromRGB(30, 30, 30),
	TextPrimary = Color3.fromRGB(255, 255, 255),
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

local gui = Instance.new("ScreenGui")
gui.Name = "FearStatus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "FearedLabel"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 96)
label.Size = UDim2.fromOffset(150, 38)
label.BackgroundColor3 = Colors.CardDark
label.BackgroundTransparency = 0.15
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBold
label.Text = "FEARED"
label.TextColor3 = Colors.TextPrimary
label.TextSize = 18
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

local stroke = Instance.new("UIStroke")
stroke.Color = Colors.BorderLight
stroke.Thickness = 1
stroke.Transparency = 0.55
stroke.Parent = label

local function isFeared(): boolean
	local character = player.Character
	return player:GetAttribute("Feared") == true
		or (character ~= nil and character:GetAttribute("Feared") == true)
end

local function refresh()
	gui.Enabled = isFeared()
end

local function clearCharacterConnections()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end

	table.clear(characterConnections)
end

local function bindCharacter(character: Model)
	clearCharacterConnections()
	table.insert(characterConnections, character:GetAttributeChangedSignal("Feared"):Connect(refresh))
	refresh()
end

player:GetAttributeChangedSignal("Feared"):Connect(refresh)

if player.Character then
	bindCharacter(player.Character)
end

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function()
	clearCharacterConnections()
	refresh()
end)
