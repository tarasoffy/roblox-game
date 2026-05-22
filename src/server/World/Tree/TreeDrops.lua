-- TreeDrops
-- Handles tree drop spawning.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TreeDrops = {}

local function getFolder(root: Instance, path: {string}): Instance?
	local current = root

	for _, name in ipairs(path) do
		local nextInstance = current:FindFirstChild(name)

		if not nextInstance then
			return nil
		end

		current = nextInstance
	end

	return current
end

local function randomBetween(minValue: number, maxValue: number): number
	return math.random(minValue, maxValue)
end

local function unanchorAndKick(instance: Instance, config)
	if not instance:IsA("BasePart") then
		return
	end

	instance.Anchored = false
	instance.CanQuery = true
	instance.CanCollide = true

	instance.AssemblyLinearVelocity = Vector3.new(
		randomBetween(config.LogLinearVelocityMin, config.LogLinearVelocityMax),
		randomBetween(config.LogLinearVelocityYMin, config.LogLinearVelocityYMax),
		randomBetween(config.LogLinearVelocityMin, config.LogLinearVelocityMax)
	)

	instance.AssemblyAngularVelocity = Vector3.new(
		randomBetween(config.LogAngularVelocityMin, config.LogAngularVelocityMax),
		randomBetween(config.LogAngularVelocityMin, config.LogAngularVelocityMax),
		randomBetween(config.LogAngularVelocityMin, config.LogAngularVelocityMax)
	)
end

local function prepareModelDrop(model: Model, position: Vector3, config)
	if not model.PrimaryPart then
		local anyPart = model:FindFirstChildWhichIsA("BasePart", true)

		if anyPart then
			model.PrimaryPart = anyPart
		end
	end

	model:PivotTo(CFrame.new(position))

	for _, descendant in ipairs(model:GetDescendants()) do
		unanchorAndKick(descendant, config)
	end
end

local function preparePartDrop(part: BasePart, position: Vector3, config)
	part.CFrame = CFrame.new(position)
	unanchorAndKick(part, config)
end

function TreeDrops.SpawnLogs(position: Vector3, config)
	local logPrefab = getFolder(ReplicatedStorage, config.LogPrefabPath)

	if not logPrefab then
		warn("[TreeDrops] Log prefab not found: ReplicatedStorage/" .. table.concat(config.LogPrefabPath, "/"))
		return
	end

	for _ = 1, config.LogDropCount do
		local drop = logPrefab:Clone()
		drop:SetAttribute("PickupId", config.LogPickupId)
		drop.Parent = workspace

		local offset = Vector3.new(
			math.random(-config.LogSpawnRadius, config.LogSpawnRadius),
			config.LogSpawnHeight,
			math.random(-config.LogSpawnRadius, config.LogSpawnRadius)
		)

		local dropPosition = position + offset

		if drop:IsA("Model") then
			prepareModelDrop(drop, dropPosition, config)
		elseif drop:IsA("BasePart") then
			preparePartDrop(drop, dropPosition, config)
		else
			warn("[TreeDrops] Log prefab must be Model or BasePart:", drop:GetFullName())
			drop:Destroy()
			continue
		end

		Debris:AddItem(drop, config.LogDropLifetime)
	end
end

return TreeDrops