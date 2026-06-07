local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local REMOTES_FOLDER_NAME = "Remotes"
local REQUEST_REMOTE_NAME = "RequestWeaponUnlock"
local OBJECTIVE_STATE_NAME = "ObjectiveState"
local DELIVERED_VALUE_NAME = "TruckLogsDelivered"
local OBJECTIVE_ZONES_NAME = "ObjectiveZones"
local WEAPON_UNLOCK_ZONE_NAME = "WeaponUnlockZone"
local UNLOCKABLE_TOOLS_NAME = "UnlockableTools"
local UNLOCK_DISTANCE_FALLBACK = 10

local UNLOCK_ORDER = {
	"Bow",
	"Revolver",
	"Shotgun",
	"Rifle",
}

local UNLOCK_THRESHOLDS: {[string]: number} = {
	Bow = 30,
	Revolver = 70,
	Shotgun = 120,
	Rifle = 200,
}

local unlockedWeapons: {[Player]: {[string]: boolean}} = {}

local function log(message: string)
	print("[WeaponUnlocks] " .. message)
end

local function warnUnlocks(message: string)
	warn("[WeaponUnlocks] " .. message)
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
local requestWeaponUnlock = ensureRemoteEvent(remotesFolder, REQUEST_REMOTE_NAME)

local function getDeliveredLogs(): number
	local objectiveState = ReplicatedStorage:FindFirstChild(OBJECTIVE_STATE_NAME)
	if not objectiveState then
		warnUnlocks("ReplicatedStorage.ObjectiveState missing; unlock request rejected.")
		return 0
	end

	local deliveredValue = objectiveState:FindFirstChild(DELIVERED_VALUE_NAME)
	if not deliveredValue or not deliveredValue:IsA("IntValue") then
		warnUnlocks("ReplicatedStorage.ObjectiveState.TruckLogsDelivered missing or not an IntValue; unlock request rejected.")
		return 0
	end

	return deliveredValue.Value
end

local function getUnlockZone(): BasePart?
	local objectiveZones = workspace:FindFirstChild(OBJECTIVE_ZONES_NAME)
	if not objectiveZones then
		warnUnlocks("Workspace.ObjectiveZones missing; unlock request rejected.")
		return nil
	end

	local zone = objectiveZones:FindFirstChild(WEAPON_UNLOCK_ZONE_NAME)
	if not zone or not zone:IsA("BasePart") then
		warnUnlocks("Workspace.ObjectiveZones.WeaponUnlockZone missing or not a BasePart; unlock request rejected.")
		return nil
	end

	return zone
end

local function getCharacterRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function isPositionInsideZone(position: Vector3, zone: BasePart): boolean
	local localPosition = zone.CFrame:PointToObjectSpace(position)
	local halfSize = zone.Size * 0.5

	return math.abs(localPosition.X) <= halfSize.X
		and math.abs(localPosition.Y) <= halfSize.Y
		and math.abs(localPosition.Z) <= halfSize.Z
end

local function isPlayerInUnlockZone(player: Player): boolean
	local zone = getUnlockZone()
	local root = getCharacterRoot(player)

	if not zone or not root then
		return false
	end

	if isPositionInsideZone(root.Position, zone) then
		return true
	end

	return (root.Position - zone.Position).Magnitude <= UNLOCK_DISTANCE_FALLBACK
end

local function getPlayerUnlocks(player: Player): {[string]: boolean}
	local playerUnlocks = unlockedWeapons[player]
	if not playerUnlocks then
		playerUnlocks = {}
		unlockedWeapons[player] = playerUnlocks
	end

	return playerUnlocks
end

local function playerHasTool(player: Player, toolName: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then
		return true
	end

	local character = player.Character
	if character and character:FindFirstChild(toolName) then
		return true
	end

	return false
end

local function giveTool(player: Player, toolName: string): boolean
	if playerHasTool(player, toolName) then
		return true
	end

	local unlockableTools = ServerStorage:FindFirstChild(UNLOCKABLE_TOOLS_NAME)
	if not unlockableTools then
		warnUnlocks("ServerStorage.UnlockableTools missing; cannot give " .. toolName .. ".")
		return false
	end

	local template = unlockableTools:FindFirstChild(toolName)
	if not template or not template:IsA("Tool") then
		warnUnlocks(("ServerStorage.UnlockableTools.%s missing or not a Tool."):format(toolName))
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		warnUnlocks(("Backpack missing for %s; cannot give %s."):format(player.Name, toolName))
		return false
	end

	local tool = template:Clone()
	tool.Parent = backpack
	return true
end

local function getNextLockedWeapon(player: Player): string?
	local playerUnlocks = getPlayerUnlocks(player)

	for _, weaponName in ipairs(UNLOCK_ORDER) do
		if not playerUnlocks[weaponName] then
			return weaponName
		end
	end

	return nil
end

local function regrantUnlockedTools(player: Player)
	local playerUnlocks = getPlayerUnlocks(player)

	for _, weaponName in ipairs(UNLOCK_ORDER) do
		if playerUnlocks[weaponName] then
			giveTool(player, weaponName)
		end
	end
end

local function handleUnlockRequest(player: Player)
	if not isPlayerInUnlockZone(player) then
		requestWeaponUnlock:FireClient(player, "Rejected", nil, "Move closer to the unlock zone.")
		return
	end

	local weaponName = getNextLockedWeapon(player)
	if not weaponName then
		requestWeaponUnlock:FireClient(player, "AllUnlocked")
		return
	end

	local deliveredLogs = getDeliveredLogs()
	local threshold = UNLOCK_THRESHOLDS[weaponName]

	if deliveredLogs < threshold then
		requestWeaponUnlock:FireClient(player, "NotEnoughLogs", weaponName, threshold, deliveredLogs)
		return
	end

	if not giveTool(player, weaponName) then
		requestWeaponUnlock:FireClient(player, "Rejected", weaponName, "Tool template missing.")
		return
	end

	local playerUnlocks = getPlayerUnlocks(player)
	playerUnlocks[weaponName] = true

	log(("%s unlocked %s at %d delivered logs."):format(player.Name, weaponName, deliveredLogs))
	requestWeaponUnlock:FireClient(player, "Unlocked", weaponName)
end

local function initPlayer(player: Player)
	unlockedWeapons[player] = {}

	player.CharacterAdded:Connect(function()
		task.defer(function()
			regrantUnlockedTools(player)
		end)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end

Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
	unlockedWeapons[player] = nil
end)

requestWeaponUnlock.OnServerEvent:Connect(handleUnlockRequest)

log("Weapon unlock service ready.")
