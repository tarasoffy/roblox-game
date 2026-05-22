-- AnimalDrops
-- Handles animal death drops.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local AnimalDrops = {}

local groundRayParams = RaycastParams.new()
groundRayParams.FilterType = Enum.RaycastFilterType.Blacklist
groundRayParams.IgnoreWater = true
groundRayParams.FilterDescendantsInstances = {}

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

local function prepareDrop(drop: Instance)
	for _, descendant in ipairs(drop:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
			descendant.Massless = true
			descendant.CanQuery = true
			descendant.CanTouch = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

function AnimalDrops.ResolveDropCount(animal: Model, config): number
	local key = string.lower(animal.Name)

	return config.MeatDropByAnimal[key] or config.DefaultMeatDrop
end

local function getGroundSpawnCFrame(fromPosition: Vector3, ignore: {Instance}?, config): CFrame
	groundRayParams.FilterDescendantsInstances = ignore or {}

	local origin = fromPosition + Vector3.new(0, config.GroundRayHeight, 0)
	local direction = Vector3.new(0, -config.GroundRayDepth, 0)

	local result = workspace:Raycast(origin, direction, groundRayParams)

	if result then
		return CFrame.new(result.Position + Vector3.new(0, config.GroundDropYOffset, 0))
	end

	return CFrame.new(fromPosition + Vector3.new(0, config.FallbackDropHeight, 0))
end

local function placeModelDrop(drop: Model, cframe: CFrame)
	if not drop.PrimaryPart then
		local primaryPart = drop:FindFirstChildWhichIsA("BasePart", true)

		if primaryPart then
			drop.PrimaryPart = primaryPart
		end
	end

	if drop.PrimaryPart then
		drop:PivotTo(cframe)
	end
end

local function placePartDrop(drop: BasePart, cframe: CFrame)
	drop.CFrame = cframe
end

function AnimalDrops.CreateMeatDrops(position: Vector3, count: number, config)
	local meatPrefab = getFolder(ReplicatedStorage, config.MeatPrefabPath)

	if not meatPrefab then
		warn("[AnimalDrops] Meat prefab not found: ReplicatedStorage/" .. table.concat(config.MeatPrefabPath, "/"))
		return
	end

	for _ = 1, count do
		local drop = meatPrefab:Clone()
		drop.Name = "MeatDrop"
		drop:SetAttribute("PickupId", config.MeatPickupId)
		drop.Parent = workspace

		local offset = Vector3.new(
			math.random(config.MeatDropOffsetMin, config.MeatDropOffsetMax) * config.MeatDropOffsetMultiplier,
			0,
			math.random(config.MeatDropOffsetMin, config.MeatDropOffsetMax) * config.MeatDropOffsetMultiplier
		)

		local cframe = getGroundSpawnCFrame(position + offset, {drop}, config)

		if drop:IsA("Model") then
			placeModelDrop(drop, cframe)
		elseif drop:IsA("BasePart") then
			placePartDrop(drop, cframe)
		else
			warn("[AnimalDrops] Meat prefab must be Model or BasePart:", drop:GetFullName())
			drop:Destroy()
			continue
		end

		task.defer(function()
			if drop.Parent then
				prepareDrop(drop)
			end
		end)

		Debris:AddItem(drop, config.DropLifetime)
	end
end

return AnimalDrops