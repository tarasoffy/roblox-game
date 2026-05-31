local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ANIMAL_NAME = "Wolf"
local WALK_SPEED = 18
local JUMP_POWER = 0
local SPAWN_HEIGHT_OFFSET = Vector3.new(0, 4, 0)

local spawningPlayers: {[Player]: boolean} = {}

local function log(message: string)
	print("[AnimalSpawn] " .. message)
end

local function warnSpawn(message: string)
	warn("[AnimalSpawn] " .. message)
end

local function getBeastSpawnCFrame(): CFrame
	local spawnsFolder = workspace:FindFirstChild("Spawns")
	if not spawnsFolder then
		warnSpawn("Workspace.Spawns not found; using fallback spawn.")
		return CFrame.new(0, 5, 0)
	end

	local beastSpawns = spawnsFolder:FindFirstChild("BeastSpawns")
	if not beastSpawns then
		warnSpawn("Workspace.Spawns.BeastSpawns not found; using fallback spawn.")
		return CFrame.new(0, 5, 0)
	end

	local spawnPart = beastSpawns:FindFirstChild("Spawn1")
	if not spawnPart or not spawnPart:IsA("BasePart") then
		warnSpawn("Workspace.Spawns.BeastSpawns.Spawn1 BasePart not found; using fallback spawn.")
		return CFrame.new(0, 5, 0)
	end

	return spawnPart.CFrame + SPAWN_HEIGHT_OFFSET
end

local function getAnimalTemplate(): Model?
	local animalCharacters = ServerStorage:FindFirstChild("AnimalCharacters")
	if not animalCharacters then
		warnSpawn("ServerStorage.AnimalCharacters folder is missing.")
		return nil
	end

	local animalTemplate = animalCharacters:FindFirstChild(ANIMAL_NAME)
	if not animalTemplate then
		warnSpawn(("ServerStorage.AnimalCharacters.%s model is missing."):format(ANIMAL_NAME))
		return nil
	end

	if not animalTemplate:IsA("Model") then
		warnSpawn(("ServerStorage.AnimalCharacters.%s must be a Model."):format(ANIMAL_NAME))
		return nil
	end

	return animalTemplate
end

local function findWeldBetween(model: Model, partA: BasePart, partB: BasePart): boolean
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("WeldConstraint") then
			local part0 = descendant.Part0
			local part1 = descendant.Part1

			if (part0 == partA and part1 == partB) or (part0 == partB and part1 == partA) then
				return true
			end
		end
	end

	return false
end

local function validateAnimalCharacter(animalCharacter: Model): (Humanoid?, BasePart?, BasePart?, BasePart?)
	local humanoid = animalCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warnSpawn(("%s clone is missing a Humanoid."):format(ANIMAL_NAME))
		return nil, nil, nil, nil
	end

	local rootPart = animalCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		warnSpawn(("%s clone is missing a HumanoidRootPart BasePart."):format(ANIMAL_NAME))
		return nil, nil, nil, nil
	end

	local collisionBox = animalCharacter:FindFirstChild("CollisionBox")
	if not collisionBox or not collisionBox:IsA("BasePart") then
		warnSpawn(("%s clone is missing a CollisionBox BasePart."):format(ANIMAL_NAME))
		return nil, nil, nil, nil
	end

	local visual = animalCharacter:FindFirstChild("temp")
	if not visual or not visual:IsA("BasePart") then
		warnSpawn(("%s clone is missing visual MeshPart/BasePart named temp."):format(ANIMAL_NAME))
		return nil, nil, nil, nil
	end

	if animalCharacter.PrimaryPart ~= rootPart then
		warnSpawn(("%s.PrimaryPart should be HumanoidRootPart. Setting clone PrimaryPart for this spawn."):format(ANIMAL_NAME))
		animalCharacter.PrimaryPart = rootPart
	end

	if not findWeldBetween(animalCharacter, rootPart, collisionBox) then
		warnSpawn(("%s template should have a WeldConstraint between HumanoidRootPart and CollisionBox."):format(ANIMAL_NAME))
	end

	if not findWeldBetween(animalCharacter, rootPart, visual) then
		warnSpawn(("%s template should have a WeldConstraint between HumanoidRootPart and temp."):format(ANIMAL_NAME))
	end

	return humanoid, rootPart, collisionBox, visual
end

local function configureParts(rootPart: BasePart, collisionBox: BasePart, visual: BasePart)
	rootPart.Anchored = false
	rootPart.CanCollide = false
	rootPart.Transparency = 1
	rootPart.Massless = false

	collisionBox.Anchored = false
	collisionBox.CanCollide = true
	collisionBox.Transparency = 1
	collisionBox.Massless = false

	visual.Anchored = false
	visual.CanCollide = false
	visual.Massless = true
end

local function configureHumanoid(humanoid: Humanoid)
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.JumpPower = JUMP_POWER
	humanoid.AutoRotate = true
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.CameraOffset = Vector3.new(0, 2, 0)
end

local function setNetworkOwner(player: Player, part: BasePart)
	local ok, err = pcall(function()
		part:SetNetworkOwner(player)
	end)

	if not ok then
		warnSpawn(("Could not set network owner for %s: %s"):format(part.Name, tostring(err)))
	end
end

local function spawnAsAnimal(player: Player, oldCharacter: Model?)
	if spawningPlayers[player] then
		return
	end

	spawningPlayers[player] = true

	local animalTemplate = getAnimalTemplate()
	if not animalTemplate then
		spawningPlayers[player] = nil
		return
	end

	local animalCharacter = animalTemplate:Clone()
	animalCharacter.Name = player.Name
	animalCharacter:SetAttribute("IsAnimalCharacter", true)

	local humanoid, rootPart, collisionBox, visual = validateAnimalCharacter(animalCharacter)
	if not humanoid or not rootPart or not collisionBox or not visual then
		animalCharacter:Destroy()
		spawningPlayers[player] = nil
		return
	end

	configureParts(rootPart, collisionBox, visual)
	configureHumanoid(humanoid)

	animalCharacter.Parent = workspace
	animalCharacter:PivotTo(getBeastSpawnCFrame())
	player.Character = animalCharacter

	setNetworkOwner(player, rootPart)
	setNetworkOwner(player, collisionBox)

	if oldCharacter and oldCharacter ~= animalCharacter and oldCharacter.Parent then
		oldCharacter:Destroy()
	end

	log(("Spawn complete for %s as %s."):format(player.Name, ANIMAL_NAME))
	spawningPlayers[player] = nil
end

local function onCharacterAdded(player: Player, character: Model)
	if character:GetAttribute("IsAnimalCharacter") then
		return
	end

	task.wait(0.2)

	if player.Parent then
		spawnAsAnimal(player, character)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	spawningPlayers[player] = nil
end)
