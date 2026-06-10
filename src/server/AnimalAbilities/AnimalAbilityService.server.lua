local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimalConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalConfig"))

local REMOTES_FOLDER_NAME = "Remotes"
local ACTIVATE_REMOTE_NAME = "ActivateAnimalAbility"
local FEEDBACK_REMOTE_NAME = "AnimalAbilityFeedback"
local HOWL_ACTIVE_TIME = 0.5

local cooldownUntilByPlayer: {[Player]: {[string]: number}} = {}
local fearTokenByPlayer: {[Player]: number} = {}

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
local activateAnimalAbility = ensureRemoteEvent(remotesFolder, ACTIVATE_REMOTE_NAME)
local animalAbilityFeedback = ensureRemoteEvent(remotesFolder, FEEDBACK_REMOTE_NAME)

local function getCooldowns(player: Player): {[string]: number}
	local cooldowns = cooldownUntilByPlayer[player]
	if not cooldowns then
		cooldowns = {}
		cooldownUntilByPlayer[player] = cooldowns
	end

	return cooldowns
end

local function getAnimalType(character: Model): string?
	local animalType = character:GetAttribute("AnimalType")
	if typeof(animalType) == "string" then
		return animalType
	end

	return nil
end

local function getAbilityForSlot(animalType: string, slot: number)
	local stats = AnimalConfig[animalType]
	local abilities = stats and stats.Abilities

	if typeof(abilities) ~= "table" then
		return nil, nil
	end

	for abilityName, abilityConfig in pairs(abilities) do
		if typeof(abilityConfig) == "table" and abilityConfig.Slot == slot then
			return abilityName, abilityConfig
		end
	end

	return nil, nil
end

local function getCharacterRoot(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function isHumanCharacter(character: Model): boolean
	return character:GetAttribute("IsAnimalCharacter") ~= true
end

local function clearFear(player: Player, character: Model?, token: number)
	if fearTokenByPlayer[player] ~= token then
		return
	end

	fearTokenByPlayer[player] = nil
	player:SetAttribute("Feared", nil)
	player:SetAttribute("FearMoveSpeedMultiplier", nil)
	player:SetAttribute("FearChopCooldownMultiplier", nil)

	if character and character.Parent then
		character:SetAttribute("Feared", nil)
		character:SetAttribute("FearMoveSpeedMultiplier", nil)
		character:SetAttribute("FearChopCooldownMultiplier", nil)
	end

	print(("[WolfHowl] fear ended for %s"):format(player.Name))
end

local function applyFearToHuman(player: Player, character: Model, abilityConfig)
	local duration = abilityConfig.Duration
	local moveSpeedMultiplier = abilityConfig.MoveSpeedMultiplier
	local chopCooldownMultiplier = abilityConfig.ChopCooldownMultiplier

	if typeof(duration) ~= "number" then
		duration = 4
	end

	if typeof(moveSpeedMultiplier) ~= "number" then
		moveSpeedMultiplier = 0.7
	end

	if typeof(chopCooldownMultiplier) ~= "number" then
		chopCooldownMultiplier = 1.5
	end

	local token = (fearTokenByPlayer[player] or 0) + 1
	fearTokenByPlayer[player] = token

	player:SetAttribute("Feared", true)
	player:SetAttribute("FearMoveSpeedMultiplier", moveSpeedMultiplier)
	player:SetAttribute("FearChopCooldownMultiplier", chopCooldownMultiplier)

	character:SetAttribute("Feared", true)
	character:SetAttribute("FearMoveSpeedMultiplier", moveSpeedMultiplier)
	character:SetAttribute("FearChopCooldownMultiplier", chopCooldownMultiplier)

	print(("[WolfHowl] affected %s"):format(player.Name))

	task.delay(duration, function()
		clearFear(player, character, token)
	end)
end

local function applyWolfHowlFear(caster: Player, casterCharacter: Model, abilityConfig)
	local radius = abilityConfig.Radius
	if typeof(radius) ~= "number" then
		radius = 25
	end

	local casterRoot = getCharacterRoot(casterCharacter)
	if not casterRoot then
		return
	end

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer == caster then
			continue
		end

		local targetCharacter = targetPlayer.Character
		if not targetCharacter or not isHumanCharacter(targetCharacter) then
			continue
		end

		local targetRoot = getCharacterRoot(targetCharacter)
		if not targetRoot then
			continue
		end

		if (targetRoot.Position - casterRoot.Position).Magnitude <= radius then
			applyFearToHuman(targetPlayer, targetCharacter, abilityConfig)
		end
	end
end

local function activateWolfHowl(player: Player, character: Model, abilityConfig, slot: number)
	local cooldown = abilityConfig.Cooldown
	if typeof(cooldown) ~= "number" then
		cooldown = 10
	end

	local cooldowns = getCooldowns(player)
	local abilityKey = "Wolf.Howl"
	local now = os.clock()
	local cooldownUntil = cooldowns[abilityKey] or 0

	if now < cooldownUntil then
		local remaining = cooldownUntil - now
		print(("[WolfHowl] cooldown remaining: %.1f"):format(remaining))
		animalAbilityFeedback:FireClient(player, "Cooldown", "Howl", slot, remaining)
		return
	end

	cooldowns[abilityKey] = now + cooldown
	character:SetAttribute("HowlActive", true)

	print(("[WolfHowl] activated by %s"):format(player.Name))
	animalAbilityFeedback:FireClient(player, "Activated", "Howl", slot, cooldown)
	applyWolfHowlFear(player, character, abilityConfig)

	task.delay(HOWL_ACTIVE_TIME, function()
		if character.Parent then
			character:SetAttribute("HowlActive", nil)
		end
	end)
end

activateAnimalAbility.OnServerEvent:Connect(function(player: Player, slot: any)
	if typeof(slot) ~= "number" then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	if character:GetAttribute("IsAnimalCharacter") ~= true then
		return
	end

	local animalType = getAnimalType(character)
	if not animalType then
		return
	end

	local abilityName, abilityConfig = getAbilityForSlot(animalType, slot)
	if not abilityName or not abilityConfig then
		print(("[AnimalAbility] no ability for %s slot %d"):format(animalType, slot))
		animalAbilityFeedback:FireClient(player, "NoAbility", nil, slot)
		return
	end

	if animalType ~= "Wolf" or abilityName ~= "Howl" then
		print(("[AnimalAbility] no handler for %s.%s"):format(animalType, abilityName))
		animalAbilityFeedback:FireClient(player, "NoAbility", abilityName, slot)
		return
	end

	activateWolfHowl(player, character, abilityConfig, slot)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldownUntilByPlayer[player] = nil
	fearTokenByPlayer[player] = nil
end)
