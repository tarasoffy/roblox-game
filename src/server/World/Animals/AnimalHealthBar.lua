-- AnimalHealthBar
-- Handles animal health bar UI and hides default Humanoid health displays.

local AnimalHealthBar = {}

local function hideDefaultAndOtherBars(animal: Model, humanoid: Humanoid, config)
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	for _, descendant in ipairs(animal:GetDescendants()) do
		if (descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui")) and descendant.Name ~= config.HealthBarName then
			local name = string.lower(descendant.Name)

			if name:find("health") or name:find("hp") then
				descendant:Destroy()
			end
		end
	end
end

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

local function getHealthBarRoot(animal: Model): BasePart?
	local head = animal:FindFirstChild("Head")

	if head and head:IsA("BasePart") then
		return head
	end

	local root = animal.PrimaryPart

	if root and root:IsA("BasePart") then
		return root
	end

	local humanoidRootPart = animal:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	return animal:FindFirstChildWhichIsA("BasePart", true)
end

function AnimalHealthBar.Attach(animal: Model, config)
	local humanoid = animal:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	local root = getHealthBarRoot(animal)

	if not root then
		warn("[AnimalHealthBar] Animal has no BasePart to attach HealthBar:", animal.Name)
		return
	end

	hideDefaultAndOtherBars(animal, humanoid, config)

	if animal:FindFirstChild(config.HealthBarName) then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = config.HealthBarName
	gui.Adornee = root
	gui.Size = UDim2.new(4, 0, 0.4, 0)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = animal

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

	local function update()
		local maxHealth = humanoid.MaxHealth
		local percent = 0

		if maxHealth > 0 then
			percent = math.clamp(humanoid.Health / maxHealth, 0, 1)
		end

		bar.Size = UDim2.new(percent, 0, 1, 0)
		bar.BackgroundColor3 = getSmoothHealthColor(percent)
	end

	update()

	humanoid.HealthChanged:Connect(update)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	humanoid.Died:Once(function()
		AnimalHealthBar.Remove(animal, config)
	end)
end

function AnimalHealthBar.Remove(animal: Model, config)
	local healthBar = animal:FindFirstChild(config.HealthBarName)

	if healthBar then
		healthBar:Destroy()
	end
end

return AnimalHealthBar
