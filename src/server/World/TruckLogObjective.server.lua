local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TreeConfig = require(script.Parent:WaitForChild("Tree"):WaitForChild("TreeConfig"))

local REQUIRED_LOGS = 100
local DELIVERED_LOGS_START = 0
local LOG_PICKUP_ID = TreeConfig.LogPickupId
local LOG_INSTANCE_NAME = "Log"
local OBJECTIVE_ZONES_NAME = "ObjectiveZones"
local DROP_ZONE_NAME = "TruckLogDropZone"
local OBJECTIVE_STATE_NAME = "ObjectiveState"
local DELIVERED_VALUE_NAME = "TruckLogsDelivered"
local REQUIRED_VALUE_NAME = "TruckLogsRequired"
local SCAN_INTERVAL = 0.15
local MAX_DELIVER_VELOCITY = 2

local deliveredLogs = DELIVERED_LOGS_START
local processedLogs: {[Instance]: boolean} = {}

local deliveredValue: IntValue
local requiredValue: IntValue

local function log(message: string)
	print("[TruckLogObjective] " .. message)
end

local function warnObjective(message: string)
	warn("[TruckLogObjective] " .. message)
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

local function ensureIntValue(parent: Instance, valueName: string, value: number): IntValue
	local existing = parent:FindFirstChild(valueName)
	if existing and existing:IsA("IntValue") then
		existing.Value = value
		return existing
	end

	local intValue = Instance.new("IntValue")
	intValue.Name = valueName
	intValue.Value = value
	intValue.Parent = parent
	return intValue
end

local function initObjectiveState()
	local objectiveState = ensureFolder(ReplicatedStorage, OBJECTIVE_STATE_NAME)
	deliveredValue = ensureIntValue(objectiveState, DELIVERED_VALUE_NAME, deliveredLogs)
	requiredValue = ensureIntValue(objectiveState, REQUIRED_VALUE_NAME, REQUIRED_LOGS)
end

local function updateObjectiveState()
	deliveredValue.Value = deliveredLogs
	requiredValue.Value = REQUIRED_LOGS
end

local function getObjectiveZone(): BasePart?
	local objectiveZones = workspace:FindFirstChild(OBJECTIVE_ZONES_NAME)
	if not objectiveZones then
		warnObjective("Workspace.ObjectiveZones missing; truck log objective stopped.")
		return nil
	end

	local dropZone = objectiveZones:FindFirstChild(DROP_ZONE_NAME)
	if not dropZone then
		warnObjective("Workspace.ObjectiveZones.TruckLogDropZone missing; truck log objective stopped.")
		return nil
	end

	if not dropZone:IsA("BasePart") then
		warnObjective("Workspace.ObjectiveZones.TruckLogDropZone must be a BasePart; truck log objective stopped.")
		return nil
	end

	return dropZone
end

local function getModelFromHit(instance: Instance): Model?
	if instance:IsA("Model") then
		return instance
	end

	return instance:FindFirstAncestorOfClass("Model")
end

local function getPickupId(instance: Instance): string?
	local current: Instance? = instance

	while current and current ~= workspace do
		local pickupId = current:GetAttribute("PickupId")
		if typeof(pickupId) == "string" and pickupId ~= "" then
			return pickupId
		end

		current = current.Parent
	end

	return nil
end

local function resolveLogRoot(instance: Instance): Instance?
	local character = getModelFromHit(instance)
	if character and Players:GetPlayerFromCharacter(character) then
		return nil
	end

	local current: Instance? = instance
	local namedLogRoot: Instance? = nil

	while current and current ~= workspace do
		if current:GetAttribute("PickupId") == LOG_PICKUP_ID then
			return current
		end

		if not namedLogRoot and (current:IsA("Model") or current:IsA("BasePart")) and current.Name == LOG_INSTANCE_NAME then
			namedLogRoot = current
		end

		current = current.Parent
	end

	return namedLogRoot
end

local function getRootPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function getWorldPosition(instance: Instance): Vector3?
	local rootPart = getRootPart(instance)
	return rootPart and rootPart.Position or nil
end

local function getAssemblyVelocity(instance: Instance): number
	local rootPart = getRootPart(instance)
	if not rootPart then
		return math.huge
	end

	return rootPart.AssemblyLinearVelocity.Magnitude
end

local function isPositionInsideZone(position: Vector3, zonePart: BasePart): boolean
	local localPosition = zonePart.CFrame:PointToObjectSpace(position)
	local halfSize = zonePart.Size * 0.5

	return math.abs(localPosition.X) <= halfSize.X
		and math.abs(localPosition.Y) <= halfSize.Y
		and math.abs(localPosition.Z) <= halfSize.Z
end

local function isValidLog(logInstance: Instance): boolean
	local pickupId = getPickupId(logInstance)
	return pickupId == LOG_PICKUP_ID or logInstance.Name == LOG_INSTANCE_NAME
end

local function consumeLog(logInstance: Instance): boolean
	if processedLogs[logInstance] then
		return false
	end

	processedLogs[logInstance] = true

	if deliveredLogs < REQUIRED_LOGS then
		deliveredLogs = math.clamp(deliveredLogs + 1, 0, REQUIRED_LOGS)
		updateObjectiveState()
		log(("Delivered log. Total: %d / %d"):format(deliveredLogs, REQUIRED_LOGS))
	end

	if logInstance.Parent then
		logInstance:Destroy()
	end

	return true
end

local function tryDeliverLog(logInstance: Instance, dropZone: BasePart): boolean
	if processedLogs[logInstance] or not isValidLog(logInstance) then
		return false
	end

	local position = getWorldPosition(logInstance)
	if not position or not isPositionInsideZone(position, dropZone) then
		return false
	end

	if getAssemblyVelocity(logInstance) > MAX_DELIVER_VELOCITY then
		return false
	end

	return consumeLog(logInstance)
end

local function scanDropZone(dropZone: BasePart)
	local parts = workspace:GetPartBoundsInBox(dropZone.CFrame, dropZone.Size)
	local scannedLogs: {[Instance]: boolean} = {}

	for _, part in ipairs(parts) do
		local logInstance = resolveLogRoot(part)
		if not logInstance or scannedLogs[logInstance] or processedLogs[logInstance] then
			continue
		end

		scannedLogs[logInstance] = true
		tryDeliverLog(logInstance, dropZone)
	end
end

initObjectiveState()

local dropZone = getObjectiveZone()
if not dropZone then
	return
end

task.spawn(function()
	while dropZone.Parent do
		scanDropZone(dropZone)
		task.wait(SCAN_INTERVAL)
	end

	warnObjective("TruckLogDropZone was removed; truck log objective scan stopped.")
end)

log(("Truck log objective ready: %d / %d"):format(deliveredLogs, REQUIRED_LOGS))
