-- AnimalPool
-- Handles dead animal pooling.

local ServerStorage = game:GetService("ServerStorage")

local AnimalPool = {}

local animalPoolFolder: Folder? = nil

local function ensurePoolFolder(config): Folder
	if animalPoolFolder and animalPoolFolder.Parent then
		return animalPoolFolder
	end

	local existing = ServerStorage:FindFirstChild(config.PoolFolderName)

	if existing then
		if existing:IsA("Folder") then
			animalPoolFolder = existing
			return existing
		end

		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = config.PoolFolderName
	folder.Parent = ServerStorage

	animalPoolFolder = folder

	return folder
end

local function freezeAndHideAnimal(animal: Model)
	for _, descendant in ipairs(animal:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Transparency = 1
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

function AnimalPool.ReturnAnimal(animal: Model, config)
	local poolFolder = ensurePoolFolder(config)

	freezeAndHideAnimal(animal)

	animal.Parent = poolFolder
	animal:SetAttribute("Dead", false)

	local pooledAnimals = poolFolder:GetChildren()

	if #pooledAnimals > config.MaxPool then
		pooledAnimals[1]:Destroy()
	end
end

function AnimalPool.GetPoolFolder(config): Folder
	return ensurePoolFolder(config)
end

return AnimalPool