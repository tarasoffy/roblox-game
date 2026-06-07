local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local OBJECTIVE_STATE_NAME = "ObjectiveState"
local DELIVERED_VALUE_NAME = "TruckLogsDelivered"
local REQUIRED_VALUE_NAME = "TruckLogsRequired"

local OBJECTIVE_ZONES_NAME = "ObjectiveZones"
local DROP_ZONE_NAME = "TruckLogDropZone"
local OBJECTIVE_TRUCK_NAME = "ObjectiveTruck"

local SIGN_NAME = "TruckLogObjectiveSign"
local WAIT_TIMEOUT = 10

local MAX_DISTANCE = 45
local SIGN_SIZE = Vector3.new(3.2, 0.65, 0.08)
local SIGN_OFFSET = Vector3.new(0, 3.4, 0)

local BACKGROUND_COLOR = Color3.fromRGB(20, 20, 20)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local BORDER_COLOR = Color3.fromRGB(255, 255, 255)

local localPlayer = Players.LocalPlayer

local progressLabel: TextLabel? = nil
local surfaceGui: SurfaceGui? = nil
local signPart: Part? = nil

local function warnUi(message: string)
	warn("[TruckLogObjectiveUI] " .. message)
end

local function waitForChild(parent: Instance, childName: string): Instance?
	local child = parent:WaitForChild(childName, WAIT_TIMEOUT)

	if not child then
		warnUi(("%s.%s missing; objective UI stopped."):format(parent:GetFullName(), childName))
	end

	return child
end

local function getObjectiveValues(): (IntValue?, IntValue?)
	local objectiveState = waitForChild(ReplicatedStorage, OBJECTIVE_STATE_NAME)
	if not objectiveState then
		warnUi("ObjectiveState missing; objective UI cannot read progress.")
		return nil, nil
	end

	print("[TruckLogObjectiveUI] ObjectiveState found")

	local deliveredValue = waitForChild(objectiveState, DELIVERED_VALUE_NAME)
	local requiredValue = waitForChild(objectiveState, REQUIRED_VALUE_NAME)

	if not deliveredValue or not deliveredValue:IsA("IntValue") then
		warnUi("ReplicatedStorage.ObjectiveState.TruckLogsDelivered missing or not an IntValue.")
		return nil, nil
	end

	if not requiredValue or not requiredValue:IsA("IntValue") then
		warnUi("ReplicatedStorage.ObjectiveState.TruckLogsRequired missing or not an IntValue.")
		return nil, nil
	end

	return deliveredValue, requiredValue
end

local function getDropZone(): BasePart?
	local objectiveZones = waitForChild(Workspace, OBJECTIVE_ZONES_NAME)
	if not objectiveZones then
		return nil
	end

	local dropZone = waitForChild(objectiveZones, DROP_ZONE_NAME)
	if not dropZone or not dropZone:IsA("BasePart") then
		warnUi("Workspace.ObjectiveZones.TruckLogDropZone missing or not a BasePart; objective UI cannot attach.")
		return nil
	end

	print("[TruckLogObjectiveUI] Drop zone found")
	return dropZone
end

local function getReferenceCFrame(dropZone: BasePart): CFrame
	local truck = Workspace:FindFirstChild(OBJECTIVE_TRUCK_NAME)

	if truck then
		if truck:IsA("BasePart") then
			return truck.CFrame
		end

		if truck:IsA("Model") then
			return truck:GetBoundingBox()
		end
	end

	return dropZone.CFrame
end

local function getSignPosition(dropZone: BasePart): Vector3
	return getReferenceCFrame(dropZone).Position + SIGN_OFFSET
end

local function getSignCFrame(dropZone: BasePart): CFrame
	local position = getSignPosition(dropZone)
	local camera = Workspace.CurrentCamera

	if camera then
		local flatLook = camera.CFrame.Position - position
		flatLook = Vector3.new(flatLook.X, 0, flatLook.Z)

		if flatLook.Magnitude > 0.01 then
			return CFrame.lookAt(position, position + flatLook.Unit)
		end
	end

	return CFrame.new(position)
end

local function getCharacterPosition(): Vector3?
	local character = localPlayer.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart.Position
	end

	return nil
end

local function updateVisibility(dropZone: BasePart)
	if not surfaceGui then
		return
	end

	local characterPosition = getCharacterPosition()
	if not characterPosition then
		surfaceGui.Enabled = false
		return
	end

	local distance = (characterPosition - getSignPosition(dropZone)).Magnitude
	surfaceGui.Enabled = distance <= MAX_DISTANCE
end

local function updateText(deliveredValue: IntValue, requiredValue: IntValue)
	if progressLabel then
		progressLabel.Text = ("LOGS: %d / %d"):format(deliveredValue.Value, requiredValue.Value)
	end
end

local function createSign(dropZone: BasePart, deliveredValue: IntValue, requiredValue: IntValue)
	local part = Instance.new("Part")
	part.Name = SIGN_NAME
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = SIGN_SIZE
	part.Transparency = 1
	part.CFrame = getSignCFrame(dropZone)
	part.Parent = Workspace

	local gui = Instance.new("SurfaceGui")
	gui.Name = "TruckLogObjectiveSurface"
	gui.Adornee = part
	gui.AlwaysOnTop = true
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE
	gui.PixelsPerStud = 90
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "ProgressLabel"
	label.BackgroundColor3 = BACKGROUND_COLOR
	label.BackgroundTransparency = 0.35
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = TEXT_COLOR
	label.TextSize = 26
	label.TextScaled = false
	label.TextWrapped = false
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = label

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local border = Instance.new("UIStroke")
	border.Color = BORDER_COLOR
	border.Thickness = 2
	border.Transparency = 0.15
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = label

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(0, 0, 0)
	textStroke.Thickness = 1
	textStroke.Transparency = 0.35
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	textStroke.Parent = label

	signPart = part
	surfaceGui = gui
	progressLabel = label

	updateText(deliveredValue, requiredValue)
	updateVisibility(dropZone)

	print("[TruckLogObjectiveUI] Sign created")
end

local deliveredValue, requiredValue = getObjectiveValues()
if not deliveredValue or not requiredValue then
	return
end

local dropZone = getDropZone()
if not dropZone then
	return
end

createSign(dropZone, deliveredValue, requiredValue)

deliveredValue.Changed:Connect(function()
	updateText(deliveredValue, requiredValue)
end)

requiredValue.Changed:Connect(function()
	updateText(deliveredValue, requiredValue)
end)

RunService.RenderStepped:Connect(function()
	if signPart and signPart.Parent and dropZone.Parent then
		signPart.CFrame = getSignCFrame(dropZone)
		updateVisibility(dropZone)
	end
end)