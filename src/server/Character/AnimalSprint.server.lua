local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimalConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalConfig"))

local REMOTES_FOLDER_NAME = "Remotes"
local SET_ANIMAL_SPRINT_NAME = "SetAnimalSprint"

local function warnSprint(message: string)
	warn("[AnimalSprint] " .. message)
end

local function ensureFolder(parent: Instance, folderName: string): Folder
	local existing = parent:FindFirstChild(folderName)
	if existing and existing:IsA("Folder") then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = parent
	return folder
end

local function ensureRemoteEvent(parent: Instance, remoteName: string): RemoteEvent
	local existing = parent:FindFirstChild(remoteName)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = remoteName
	remoteEvent.Parent = parent
	return remoteEvent
end

local remotesFolder = ensureFolder(ReplicatedStorage, REMOTES_FOLDER_NAME)
local setAnimalSprint = ensureRemoteEvent(remotesFolder, SET_ANIMAL_SPRINT_NAME)

local function getAnimalStats(character: Model)
	if character:GetAttribute("IsAnimalCharacter") ~= true then
		return nil
	end

	local animalType = character:GetAttribute("AnimalType")
	if typeof(animalType) ~= "string" then
		return nil
	end

	return AnimalConfig[animalType]
end

local function applyAnimalSpeed(player: Player, sprinting: boolean)
	local character = player.Character
	if not character then
		return
	end

	local stats = getAnimalStats(character)
	if not stats then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local walkSpeed = stats.WalkSpeed
	local sprintSpeed = stats.SprintSpeed
	if typeof(walkSpeed) ~= "number" or typeof(sprintSpeed) ~= "number" then
		warnSprint(("Invalid movement stats for %s."):format(player.Name))
		return
	end

	humanoid.WalkSpeed = sprinting and sprintSpeed or walkSpeed
end

setAnimalSprint.OnServerEvent:Connect(function(player: Player, sprinting: any)
	if typeof(sprinting) ~= "boolean" then
		return
	end

	applyAnimalSpeed(player, sprinting)
end)

Players.PlayerRemoving:Connect(function(player)
	applyAnimalSpeed(player, false)
end)
