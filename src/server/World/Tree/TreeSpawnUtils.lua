-- TreeSpawnUtils
-- Shared helpers for tree spawning.

local TreeSpawnUtils = {}

function TreeSpawnUtils.GetFolder(root: Instance, path: {string}): Instance?
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

function TreeSpawnUtils.EnsureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)

	if existing then
		if existing:IsA("Folder") then
			return existing
		end

		error(("[TreeSpawner] %s already exists but is not a Folder"):format(existing:GetFullName()))
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	return folder
end

function TreeSpawnUtils.GetSpawnPoints(spawnFolder: Instance): {BasePart}
	local points = {}

	for _, instance in ipairs(spawnFolder:GetChildren()) do
		if instance:IsA("BasePart") then
			table.insert(points, instance)
		end
	end

	table.sort(points, function(a, b)
		return a.Name < b.Name
	end)

	return points
end

function TreeSpawnUtils.GetTemplates(templatesFolder: Instance): {Instance}
	local templates = {}

	for _, instance in ipairs(templatesFolder:GetChildren()) do
		if instance:IsA("Model") or instance:IsA("BasePart") then
			table.insert(templates, instance)
		end
	end

	return templates
end

function TreeSpawnUtils.ChooseRandom<T>(items: {T}): T?
	if #items == 0 then
		return nil
	end

	return items[math.random(1, #items)]
end

function TreeSpawnUtils.DistXZ(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z

	return math.sqrt(dx * dx + dz * dz)
end

function TreeSpawnUtils.SetAnchoredRecursive(instance: Instance, anchored: boolean, canCollide: boolean)
	if instance:IsA("BasePart") then
		instance.Anchored = anchored
		instance.CanCollide = canCollide
		return
	end

	if instance:IsA("Model") then
		for _, descendant in ipairs(instance:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = anchored
				descendant.CanCollide = canCollide
			end
		end
	end
end

function TreeSpawnUtils.GetChosenPoints(points: {BasePart}, config): {BasePart}
	local chosenPoints = {}

	if config.UseFixedCount then
		local shuffled = table.clone(points)

		for index = #shuffled, 2, -1 do
			local randomIndex = math.random(1, index)
			shuffled[index], shuffled[randomIndex] = shuffled[randomIndex], shuffled[index]
		end

		for index = 1, math.min(config.FixedCount, #shuffled) do
			table.insert(chosenPoints, shuffled[index])
		end

		return chosenPoints
	end

	for _, point in ipairs(points) do
		if math.random() < config.ChancePerPoint then
			table.insert(chosenPoints, point)
		end
	end

	return chosenPoints
end

function TreeSpawnUtils.IsFarEnough(position: Vector3, placedPositions: {Vector3}, minDistance: number): boolean
	for _, placedPosition in ipairs(placedPositions) do
		if TreeSpawnUtils.DistXZ(position, placedPosition) < minDistance then
			return false
		end
	end

	return true
end

return TreeSpawnUtils