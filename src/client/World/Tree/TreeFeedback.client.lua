-- TreeFeedback.client.lua
-- LocalScript (лучше положить в StarterPlayerScripts)
-- Получает событие удара по дереву и делает быстрый "джолт": просадка + микронаклон + возврат

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local feedbackEvent = remotes:WaitForChild("TreeHitFeedback")

-- анти-спам: чтобы одно дерево не твинилось 20 раз за 0.1с
local active: {[Instance]: boolean} = {}

local function ensurePrimaryPart(tree: Model): boolean
	if tree.PrimaryPart and tree.PrimaryPart:IsA("BasePart") then
		return true
	end

	local any = tree:FindFirstChildWhichIsA("BasePart", true)
	if any then
		tree.PrimaryPart = any
		return true
	end

	return false
end

local function punchTree(tree: Model)
	if active[tree] then return end
	if not tree.Parent then return end
	if not ensurePrimaryPart(tree) then return end

	active[tree] = true

	local base = tree:GetPivot()

	-- параметры эффекта (можешь подкрутить)
	local dropY = -0.25
	local tiltX = math.rad(1.5)
	local tiltZ = math.rad(-1.5)

	local down = base * CFrame.new(0, dropY, 0) * CFrame.Angles(tiltX, 0, tiltZ)
	local back = base

	-- твиним через CFrameValue, потому что PivotTo не твиним напрямую
	local cf = Instance.new("CFrameValue")
	cf.Value = base

	local conn
	conn = cf:GetPropertyChangedSignal("Value"):Connect(function()
		if tree and tree.Parent then
			tree:PivotTo(cf.Value)
		else
			if conn then conn:Disconnect() end
			cf:Destroy()
			active[tree] = nil
		end
	end)

	local t1 = TweenService:Create(
		cf,
		TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = down }
	)

	local t2 = TweenService:Create(
		cf,
		TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Value = back }
	)

	t1:Play()
	t1.Completed:Once(function()
		t2:Play()
	end)

	t2.Completed:Once(function()
		if conn then conn:Disconnect() end
		cf:Destroy()
		active[tree] = nil
	end)
end

feedbackEvent.OnClientEvent:Connect(function(tree)
	if typeof(tree) ~= "Instance" then return end
	if not tree:IsA("Model") then return end
	punchTree(tree)
end)
