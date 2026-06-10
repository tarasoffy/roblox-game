local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

Players.CharacterAutoLoads = false

local JUMP_POWER = 0
local SPAWN_HEIGHT_OFFSET = Vector3.new(0, 4, 0)
local SELECTED_CHARACTER_ATTRIBUTE = "SelectedCharacterType"
local AnimalConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalConfig"))
local HumanToolService = require(script.Parent:WaitForChild("HumanToolService"))

local ALLOWED_CHARACTERS: {[string]: boolean} = {
	Human = true,
	Fox = true,
	Wolf = true,
	Bear = true,
	Boar = true,
}

local ANIMAL_CHARACTERS: {[string]: boolean} = {
	Fox = true,
	Wolf = true,
	Bear = true,
	Boar = true,
}

local spawningPlayers: {[Player]: boolean} = {}
local selectedCharacters: {[Player]: string} = {}
local respawnTokens: {[Player]: number} = {}
local random = Random.new()

local function log(message: string)
	print("[CharacterSpawn] " .. message)
end

local function warnSpawn(message: string)
	warn("[CharacterSpawn] " .. message)
end

local function setSelectedCharacter(player: Player, characterName: string)
	selectedCharacters[player] = characterName
	player:SetAttribute(SELECTED_CHARACTER_ATTRIBUTE, characterName)
end

local function getSelectedCharacter(player: Player): string?
	local selectedCharacter = selectedCharacters[player]
	if selectedCharacter then
		return selectedCharacter
	end

	local attributeValue = player:GetAttribute(SELECTED_CHARACTER_ATTRIBUTE)
	if typeof(attributeValue) == "string" and ALLOWED_CHARACTERS[attributeValue] then
		selectedCharacters[player] = attributeValue
		return attributeValue
	end

	return nil
end

local function ensureFolder(parent: Instance, folderName: string): Folder
	local existing = parent:FindFirstChild(folderName)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = parent
	return folder
end

local function ensureRemoteEvent(parent: Instance, eventName: string): RemoteEvent
	local existing = parent:FindFirstChild(eventName)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = eventName
	remoteEvent.Parent = parent
	return remoteEvent
end

local remotesFolder = ensureFolder(ReplicatedStorage, "Remotes")
local selectCharacterEvent = ensureRemoteEvent(remotesFolder, "SelectCharacter")

local function getRandomSpawnCFrame(spawnFolderName: string): CFrame
	local spawnsFolder = workspace:FindFirstChild("Spawns")
	if not spawnsFolder or not spawnsFolder:IsA("Folder") then
		warnSpawn(
			("Workspace.Spawns.%s is missing because Workspace.Spawns is missing or not a Folder; using fallback spawn."):format(
				spawnFolderName
			)
		)
		return CFrame.new(0, 5, 0)
	end

	local spawnFolder = spawnsFolder:FindFirstChild(spawnFolderName)
	if not spawnFolder or not spawnFolder:IsA("Folder") then
		warnSpawn(
			("Workspace.Spawns.%s folder is missing or not a Folder; using fallback spawn."):format(
				spawnFolderName
			)
		)
		return CFrame.new(0, 5, 0)
	end

	local validSpawns: {BasePart} = {}
	for _, child in ipairs(spawnFolder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(validSpawns, child)
		end
	end

	if #validSpawns == 0 then
		warnSpawn(
			("Workspace.Spawns.%s has no valid BasePart/SpawnLocation children; using fallback spawn."):format(
				spawnFolderName
			)
		)
		return CFrame.new(0, 5, 0)
	end

	local spawnPoint = validSpawns[random:NextInteger(1, #validSpawns)]
	return spawnPoint.CFrame + SPAWN_HEIGHT_OFFSET
end

local function getHumanSpawnCFrame(): CFrame
	return getRandomSpawnCFrame("HumanSpawns")
end

local function getAnimalSpawnCFrame(): CFrame
	return getRandomSpawnCFrame("AnimalSpawns")
end

local function getAnimalTemplate(animalName: string): Model?
	local animalCharacters = ServerStorage:FindFirstChild("AnimalCharacters")
	if not animalCharacters then
		warnSpawn("ServerStorage.AnimalCharacters folder is missing.")
		return nil
	end

	local animalTemplate = animalCharacters:FindFirstChild(animalName)
	if not animalTemplate then
		warnSpawn(("ServerStorage.AnimalCharacters.%s model is missing."):format(animalName))
		return nil
	end

	if not animalTemplate:IsA("Model") then
		warnSpawn(("ServerStorage.AnimalCharacters.%s must be a Model."):format(animalName))
		return nil
	end

	return animalTemplate
end

local function findBasePart(model: Model, partName: string): BasePart?
	local part = model:FindFirstChild(partName)
	if part and part:IsA("BasePart") then
		return part
	end

	return nil
end

local function resolveVisualPart(animalCharacter: Model, animalName: string): BasePart?
	local namedVisual = findBasePart(animalCharacter, animalName)
	if namedVisual then
		return namedVisual
	end

	local tempVisual = findBasePart(animalCharacter, "temp")
	if tempVisual then
		return tempVisual
	end

	warnSpawn(
		("%s clone is missing a visual MeshPart/BasePart named %s or temp. Spawn stopped."):format(
			animalName,
			animalName
		)
	)
	return nil
end

local function findWeldBetween(model: Model, partA: BasePart, partB: BasePart): boolean
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("WeldConstraint") or descendant:IsA("JointInstance") then
			local weld = descendant :: any
			local part0 = weld.Part0
			local part1 = weld.Part1

			if (part0 == partA and part1 == partB) or (part0 == partB and part1 == partA) then
				return true
			end
		end
	end

	return false
end

local function validateAnimalCharacter(animalCharacter: Model, animalName: string): (Humanoid?, BasePart?, BasePart?, BasePart?)
	local humanoid = animalCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warnSpawn(("%s clone is missing a Humanoid. Spawn stopped."):format(animalName))
		return nil, nil, nil, nil
	end

	local rootPart = animalCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		warnSpawn(("%s clone is missing a HumanoidRootPart BasePart. Spawn stopped."):format(animalName))
		return nil, nil, nil, nil
	end

	local collisionBox = animalCharacter:FindFirstChild("CollisionBox")
	if not collisionBox or not collisionBox:IsA("BasePart") then
		warnSpawn(("%s clone is missing a CollisionBox BasePart. Spawn stopped."):format(animalName))
		return nil, nil, nil, nil
	end

	local visual = resolveVisualPart(animalCharacter, animalName)
	if not visual then
		return nil, nil, nil, nil
	end

	if animalCharacter.PrimaryPart ~= rootPart then
		warnSpawn(("%s.PrimaryPart should be HumanoidRootPart. Setting clone PrimaryPart for this spawn."):format(animalName))
		animalCharacter.PrimaryPart = rootPart
	end

	if not findWeldBetween(animalCharacter, rootPart, collisionBox) then
		warnSpawn(
			("%s template is missing a weld between HumanoidRootPart and CollisionBox. Spawn stopped."):format(
				animalName
			)
		)
		return nil, nil, nil, nil
	end

	if not findWeldBetween(animalCharacter, rootPart, visual) then
		warnSpawn(
			("%s template is missing a weld between HumanoidRootPart and %s. Spawn stopped."):format(
				animalName,
				visual.Name
			)
		)
		return nil, nil, nil, nil
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

local function configureHumanoid(humanoid: Humanoid, stats)
	local maxHealth = stats and stats.MaxHealth
	local walkSpeed = stats and stats.WalkSpeed

	if typeof(maxHealth) == "number" then
		humanoid.MaxHealth = maxHealth
		humanoid.Health = maxHealth
	end

	if typeof(walkSpeed) == "number" then
		humanoid.WalkSpeed = walkSpeed
	end

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

local function configureHumanCharacter(character: Model)
	character:SetAttribute("IsAnimalCharacter", nil)
	character:SetAttribute("AnimalType", nil)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanStats = AnimalConfig.Human
	if humanoid and humanStats and typeof(humanStats.MaxHealth) == "number" then
		humanoid.MaxHealth = humanStats.MaxHealth
		humanoid.Health = humanStats.MaxHealth
	end

	character:PivotTo(getHumanSpawnCFrame())
end

local function spawnAsHuman(player: Player)
	HumanToolService.ClearHumanTools(player)
	player:LoadCharacter()
	local character = player.Character
	if character then
		configureHumanCharacter(character)
	end

	HumanToolService.GiveHumanStarterTools(player)
	log(("Spawn complete for %s as Human."):format(player.Name))
end

local function spawnAsAnimal(player: Player, animalName: string, oldCharacter: Model?)
	HumanToolService.ClearHumanTools(player)

	local animalTemplate = getAnimalTemplate(animalName)
	if not animalTemplate then
		return false
	end

	local animalCharacter = animalTemplate:Clone()
	animalCharacter.Name = player.Name
	animalCharacter:SetAttribute("IsAnimalCharacter", true)
	animalCharacter:SetAttribute("AnimalType", animalName)

	local humanoid, rootPart, collisionBox, visual = validateAnimalCharacter(animalCharacter, animalName)
	if not humanoid or not rootPart or not collisionBox or not visual then
		animalCharacter:Destroy()
		return false
	end

	configureParts(rootPart, collisionBox, visual)
	configureHumanoid(humanoid, AnimalConfig[animalName])

	animalCharacter.Parent = workspace
	animalCharacter:PivotTo(getAnimalSpawnCFrame())
	player.Character = animalCharacter
	HumanToolService.ClearHumanTools(player)

	setNetworkOwner(player, rootPart)
	setNetworkOwner(player, collisionBox)

	if oldCharacter and oldCharacter ~= animalCharacter and oldCharacter.Parent then
		oldCharacter:Destroy()
	end

	log(("Spawn complete for %s as %s."):format(player.Name, animalName))
	return true
end

local function respawnSelectedCharacter(player: Player, oldCharacter: Model?)
	if spawningPlayers[player] then
		return false
	end

	local selectedCharacter = getSelectedCharacter(player)
	if not selectedCharacter then
		return false
	end

	spawningPlayers[player] = true
	local spawned = false

	if selectedCharacter == "Human" then
		spawnAsHuman(player)
		spawned = true
	elseif ANIMAL_CHARACTERS[selectedCharacter] then
		spawned = spawnAsAnimal(player, selectedCharacter, oldCharacter)
	end

	spawningPlayers[player] = nil
	return spawned
end

local function scheduleRespawn(player: Player, character: Model)
	local selectedCharacter = getSelectedCharacter(player)
	if not selectedCharacter then
		return
	end

	local nextToken = (respawnTokens[player] or 0) + 1
	respawnTokens[player] = nextToken

	task.delay(Players.RespawnTime, function()
		if respawnTokens[player] ~= nextToken then
			return
		end

		if not player.Parent then
			return
		end

		if player.Character ~= character then
			return
		end

		respawnSelectedCharacter(player, character)
	end)
end

local function handleCharacterSelection(player: Player, requestedCharacter: any)
	if typeof(requestedCharacter) ~= "string" or not ALLOWED_CHARACTERS[requestedCharacter] then
		warnSpawn(("%s requested invalid character selection: %s"):format(player.Name, tostring(requestedCharacter)))
		selectCharacterEvent:FireClient(player, false, requestedCharacter)
		return
	end

	if spawningPlayers[player] then
		selectCharacterEvent:FireClient(player, false, requestedCharacter)
		return
	end

	if getSelectedCharacter(player) == requestedCharacter then
		log(("%s already selected %s; duplicate request ignored."):format(player.Name, requestedCharacter))
		if requestedCharacter == "Human" then
			HumanToolService.GiveHumanStarterTools(player)
		elseif ANIMAL_CHARACTERS[requestedCharacter] then
			HumanToolService.ClearHumanTools(player)
		end
		selectCharacterEvent:FireClient(player, true, requestedCharacter)
		return
	end

	spawningPlayers[player] = true
	local selectionAccepted = false

	if requestedCharacter == "Human" then
		setSelectedCharacter(player, requestedCharacter)
		spawnAsHuman(player)
		selectionAccepted = true
	elseif ANIMAL_CHARACTERS[requestedCharacter] then
		local oldCharacter = player.Character
		local spawned = spawnAsAnimal(player, requestedCharacter, oldCharacter)
		if spawned then
			setSelectedCharacter(player, requestedCharacter)
			selectionAccepted = true
		end
	end

	spawningPlayers[player] = nil
	selectCharacterEvent:FireClient(player, selectionAccepted, requestedCharacter)
end

local function initPlayer(player: Player)
	if not getSelectedCharacter(player) and player.Character then
		player.Character:Destroy()
		player.Character = nil
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Once(function()
				scheduleRespawn(player, character)
			end)
		end

		task.defer(function()
			if player.Character ~= character then
				return
			end

			local selectedCharacter = getSelectedCharacter(player)
			if ANIMAL_CHARACTERS[selectedCharacter or ""] then
				local animalName = selectedCharacter
				if not animalName then
					return
				end

				if character:GetAttribute("IsAnimalCharacter") == true and character:GetAttribute("AnimalType") == selectedCharacter then
					HumanToolService.ClearHumanTools(player)
					return
				end

				if spawningPlayers[player] then
					HumanToolService.ClearHumanTools(player)
					return
				end

				spawningPlayers[player] = true
				local spawned = spawnAsAnimal(player, animalName, character)
				spawningPlayers[player] = nil

				if not spawned then
					HumanToolService.ClearHumanTools(player)
				end
			elseif character:GetAttribute("IsAnimalCharacter") == true then
				HumanToolService.ClearHumanTools(player)
			elseif selectedCharacter == "Human" then
				configureHumanCharacter(character)
				HumanToolService.GiveHumanStarterTools(player)
			end
		end)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end

Players.PlayerAdded:Connect(initPlayer)
selectCharacterEvent.OnServerEvent:Connect(handleCharacterSelection)

Players.PlayerRemoving:Connect(function(player)
	spawningPlayers[player] = nil
	selectedCharacters[player] = nil
	respawnTokens[player] = nil
end)
