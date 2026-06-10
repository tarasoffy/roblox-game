local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local showTargetHealthBar = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShowTargetHealthBar")

local HEALTH_BAR_NAME = "LocalTargetHealthBar"
local VISIBLE_SECONDS = 5
local DEFAULT_HEALTH_BAR_OFFSET = Vector3.new(0, 3, 0)
local ANIMAL_HEALTH_BAR_OFFSET = Vector3.new(0, 4.2, 0)

type TargetBar = {
	gui: BillboardGui,
	bar: Frame,
	hideToken: number,
	connections: {RBXScriptConnection},
}

local barsByTarget: {[Model]: TargetBar} = {}

local function lerpColor(firstColor: Color3, secondColor: Color3, alpha: number): Color3
	return Color3.new(
		firstColor.R + (secondColor.R - firstColor.R) * alpha,
		firstColor.G + (secondColor.G - firstColor.G) * alpha,
		firstColor.B + (secondColor.B - firstColor.B) * alpha
	)
end

local function getSmoothHealthColor(percent: number): Color3
	percent = math.clamp(percent, 0, 1)

	local red = Color3.fromRGB(220, 40, 40)
	local yellow = Color3.fromRGB(230, 200, 40)
	local green = Color3.fromRGB(60, 200, 60)

	if percent <= 0.5 then
		return lerpColor(red, yellow, percent / 0.5)
	end

	return lerpColor(yellow, green, (percent - 0.5) / 0.5)
end

local function getHealthBarRoot(target: Model): BasePart?
	local head = target:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end

	local primaryPart = target.PrimaryPart
	if primaryPart and primaryPart:IsA("BasePart") then
		return primaryPart
	end

	local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	return target:FindFirstChildWhichIsA("BasePart", true)
end

local function getHealthBarOffset(target: Model): Vector3
	if target:GetAttribute("IsAnimalCharacter") == true then
		return ANIMAL_HEALTH_BAR_OFFSET
	end

	return DEFAULT_HEALTH_BAR_OFFSET
end

local function removeBar(target: Model)
	local targetBar = barsByTarget[target]
	if not targetBar then
		return
	end

	for _, connection in ipairs(targetBar.connections) do
		connection:Disconnect()
	end

	if targetBar.gui.Parent then
		targetBar.gui:Destroy()
	end

	barsByTarget[target] = nil
end

local function createBar(target: Model, adornee: BasePart): TargetBar
	local gui = Instance.new("BillboardGui")
	gui.Name = HEALTH_BAR_NAME
	gui.Adornee = adornee
	gui.Size = UDim2.new(4, 0, 0.4, 0)
	gui.StudsOffset = getHealthBarOffset(target)
	gui.AlwaysOnTop = true
	gui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	background.BorderSizePixel = 0
	background.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = background

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
	bar.BorderSizePixel = 0
	bar.Parent = background

	Instance.new("UICorner", background).CornerRadius = UDim.new(0, 6)
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)

	local targetBar: TargetBar = {
		gui = gui,
		bar = bar,
		hideToken = 0,
		connections = {},
	}

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if humanoid then
		table.insert(targetBar.connections, humanoid.Died:Connect(function()
			removeBar(target)
		end))
	end

	table.insert(targetBar.connections, target.AncestryChanged:Connect(function(_, parent)
		if not parent then
			removeBar(target)
		end
	end))

	barsByTarget[target] = targetBar
	return targetBar
end

local function getOrCreateBar(target: Model): TargetBar?
	local existing = barsByTarget[target]
	if existing and existing.gui.Parent then
		local adornee = getHealthBarRoot(target)
		if adornee then
			existing.gui.Adornee = adornee
		end

		return existing
	end

	if existing then
		removeBar(target)
	end

	local adornee = getHealthBarRoot(target)
	if not adornee then
		return nil
	end

	return createBar(target, adornee)
end

local function updateBar(target: Model, health: number, maxHealth: number)
	if target == player.Character then
		removeBar(target)
		return
	end

	if health <= 0 or maxHealth <= 0 then
		removeBar(target)
		return
	end

	local targetBar = getOrCreateBar(target)
	if not targetBar then
		return
	end

	local percent = math.clamp(health / maxHealth, 0, 1)
	targetBar.bar.Size = UDim2.new(percent, 0, 1, 0)
	targetBar.bar.BackgroundColor3 = getSmoothHealthColor(percent)

	targetBar.hideToken += 1
	local hideToken = targetBar.hideToken

	task.delay(VISIBLE_SECONDS, function()
		local latest = barsByTarget[target]
		if latest and latest.hideToken == hideToken then
			removeBar(target)
		end
	end)
end

showTargetHealthBar.OnClientEvent:Connect(function(target: any, health: any, maxHealth: any)
	if typeof(target) ~= "Instance" or not target:IsA("Model") then
		return
	end

	if typeof(health) ~= "number" or typeof(maxHealth) ~= "number" then
		return
	end

	updateBar(target, health, maxHealth)
end)

player.CharacterAdded:Connect(function(character)
	removeBar(character)
end)
