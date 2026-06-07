local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local fallbackColors = {
	BackgroundDark = Color3.fromRGB(20, 20, 20),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	BorderLight = Color3.fromRGB(255, 255, 255),
	TextStrokeDark = Color3.fromRGB(0, 0, 0),
	SuccessGreen = Color3.fromRGB(80, 200, 120),
}

local function loadColors()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local theme = shared and shared:FindFirstChild("Theme")
	local colorsModule = theme and theme:FindFirstChild("Colors")

	if colorsModule and colorsModule:IsA("ModuleScript") then
		local ok, colors = pcall(require, colorsModule)
		if ok and typeof(colors) == "table" then
			return colors
		end
	end

	warn("[WeaponUnlocks] ReplicatedStorage.Shared.Theme.Colors missing or failed to load; using fallback UI colors.")
	return fallbackColors
end

local Colors = loadColors()

local REMOTES_FOLDER_NAME = "Remotes"
local REQUEST_REMOTE_NAME = "RequestWeaponUnlock"
local OBJECTIVE_STATE_NAME = "ObjectiveState"
local DELIVERED_VALUE_NAME = "TruckLogsDelivered"
local OBJECTIVE_ZONES_NAME = "ObjectiveZones"
local WEAPON_UNLOCK_ZONE_NAME = "WeaponUnlockZone"

local INTERACT_KEY = Enum.KeyCode.E
local UNLOCK_DISTANCE_FALLBACK = 10
local MESSAGE_TIME = 2.2

local CARD_BACKGROUND_COLOR = Colors.BackgroundDark
local CARD_TEXT_COLOR = Colors.TextPrimary
local CARD_BORDER_COLOR = Colors.BorderLight

local SUCCESS_BACKGROUND_COLOR = Colors.SuccessGreen
local SUCCESS_BORDER_COLOR = Colors.SuccessGreen

local CARD_BACKGROUND_TRANSPARENCY = 0.35
local CARD_BORDER_TRANSPARENCY = 0.55
local SUCCESS_BACKGROUND_TRANSPARENCY = 0.25
local SUCCESS_BORDER_TRANSPARENCY = 0.15
local CARD_CORNER_RADIUS = 8

local UNLOCK_ORDER = {
	"Bow",
	"Revolver",
	"Shotgun",
	"Rifle",
}

local UNLOCK_THRESHOLDS: {[string]: number} = {
	Bow = 1,
	Revolver = 2,
	Shotgun = 3,
	Rifle = 4,
}

local localUnlocked: {[string]: boolean} = {}
local promptLabel: TextLabel
local messageUntil = 0
local activeMessageText: string? = nil
local activeMessageIsSuccess = false
local fadeTween: Tween? = nil

local requestWeaponUnlock = ReplicatedStorage
	:WaitForChild(REMOTES_FOLDER_NAME)
	:WaitForChild(REQUEST_REMOTE_NAME) :: RemoteEvent

local objectiveState = ReplicatedStorage:WaitForChild(OBJECTIVE_STATE_NAME)
local deliveredValue = objectiveState:WaitForChild(DELIVERED_VALUE_NAME) :: IntValue

local function getCharacterRoot(): BasePart?
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

local function getUnlockZone(): BasePart?
	local objectiveZones = Workspace:FindFirstChild(OBJECTIVE_ZONES_NAME)
	if not objectiveZones then
		return nil
	end

	local zone = objectiveZones:FindFirstChild(WEAPON_UNLOCK_ZONE_NAME)
	if zone and zone:IsA("BasePart") then
		return zone
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

local function isNearUnlockZone(): boolean
	local root = getCharacterRoot()
	local zone = getUnlockZone()

	if not root or not zone then
		return false
	end

	if isPositionInsideZone(root.Position, zone) then
		return true
	end

	return (root.Position - zone.Position).Magnitude <= UNLOCK_DISTANCE_FALLBACK
end

local function getNextLockedWeapon(): string?
	for _, weaponName in ipairs(UNLOCK_ORDER) do
		if not localUnlocked[weaponName] then
			return weaponName
		end
	end

	return nil
end

local function getPromptText(): string
	local weaponName = getNextLockedWeapon()
	if not weaponName then
		return "ALL WEAPONS\nUNLOCKED"
	end

	local threshold = UNLOCK_THRESHOLDS[weaponName]
	if deliveredValue.Value >= threshold then
		return ("PRESS E TO UNLOCK\n%s"):format(string.upper(weaponName))
	end

	return "PRESS E TO\nUNLOCK"
end

local function getBorderStroke(label: TextLabel): UIStroke?
	local stroke = label:FindFirstChild("BorderStroke")
	if stroke and stroke:IsA("UIStroke") then
		return stroke
	end

	return nil
end

local function getTextStroke(label: TextLabel): UIStroke?
	local stroke = label:FindFirstChild("TextStroke")
	if stroke and stroke:IsA("UIStroke") then
		return stroke
	end

	return nil
end

local function applyDefaultCardStyle()
	promptLabel.BackgroundColor3 = CARD_BACKGROUND_COLOR
	promptLabel.BackgroundTransparency = CARD_BACKGROUND_TRANSPARENCY
	promptLabel.TextColor3 = CARD_TEXT_COLOR
	promptLabel.TextTransparency = 0

	local border = getBorderStroke(promptLabel)
	if border then
		border.Color = CARD_BORDER_COLOR
		border.Transparency = CARD_BORDER_TRANSPARENCY
	end

	local textStroke = getTextStroke(promptLabel)
	if textStroke then
		textStroke.Transparency = 0.45
	end
end

local function applySuccessCardStyle()
	promptLabel.BackgroundColor3 = SUCCESS_BACKGROUND_COLOR
	promptLabel.BackgroundTransparency = SUCCESS_BACKGROUND_TRANSPARENCY
	promptLabel.TextColor3 = CARD_TEXT_COLOR
	promptLabel.TextTransparency = 0

	local border = getBorderStroke(promptLabel)
	if border then
		border.Color = SUCCESS_BORDER_COLOR
		border.Transparency = SUCCESS_BORDER_TRANSPARENCY
	end

	local textStroke = getTextStroke(promptLabel)
	if textStroke then
		textStroke.Transparency = 0.35
	end
end

local function createTextCard(parent: Instance, name: string, size: UDim2, position: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = position
	label.Size = size
	label.BackgroundColor3 = CARD_BACKGROUND_COLOR
	label.BackgroundTransparency = CARD_BACKGROUND_TRANSPARENCY
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = CARD_TEXT_COLOR
	label.TextSize = 16
	label.TextScaled = false
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Visible = false
	label.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = label

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CARD_CORNER_RADIUS)
	corner.Parent = label

	local border = Instance.new("UIStroke")
	border.Name = "BorderStroke"
	border.Color = CARD_BORDER_COLOR
	border.Thickness = 1.25
	border.Transparency = CARD_BORDER_TRANSPARENCY
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = label

	local textStroke = Instance.new("UIStroke")
	textStroke.Name = "TextStroke"
	textStroke.Color = Colors.TextStrokeDark
	textStroke.Thickness = 1
	textStroke.Transparency = 0.45
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	textStroke.Parent = label

	return label
end

local function createUi()
	local gui = Instance.new("ScreenGui")
	gui.Name = "WeaponUnlockUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	promptLabel = createTextCard(
		gui,
		"UnlockPrompt",
		UDim2.fromOffset(260, 58),
		UDim2.new(0.5, 0, 0.76, 0)
	)
end

local function showTemporaryMessage(text: string, isSuccess: boolean)
	if fadeTween then
		fadeTween:Cancel()
		fadeTween = nil
	end

	activeMessageText = string.upper(text)
	activeMessageIsSuccess = isSuccess
	messageUntil = os.clock() + MESSAGE_TIME

	promptLabel.Text = activeMessageText
	promptLabel.Visible = true

	if isSuccess then
		applySuccessCardStyle()
	else
		applyDefaultCardStyle()
	end
end

local function updatePrompt()
	local nearZone = isNearUnlockZone()
	local hasActiveMessage = activeMessageText ~= nil and os.clock() < messageUntil

	promptLabel.Visible = nearZone or hasActiveMessage

	if hasActiveMessage then
		promptLabel.Text = activeMessageText or ""

		if activeMessageIsSuccess then
			applySuccessCardStyle()
		else
			applyDefaultCardStyle()
		end

		return
	end

	if activeMessageText ~= nil then
		activeMessageText = nil
		activeMessageIsSuccess = false
	end

	if nearZone then
		promptLabel.Text = getPromptText()
		applyDefaultCardStyle()
	end
end

createUi()

RunService.RenderStepped:Connect(updatePrompt)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent or input.KeyCode ~= INTERACT_KEY then
		return
	end

	if isNearUnlockZone() then
		requestWeaponUnlock:FireServer()
	end
end)

requestWeaponUnlock.OnClientEvent:Connect(function(status: string, weaponName: string?, threshold: number?, deliveredLogs: number?)
	if status == "Unlocked" and weaponName then
		localUnlocked[weaponName] = true
		showTemporaryMessage(string.upper(weaponName) .. " UNLOCKED", true)
		return
	end

	if status == "NotEnoughLogs" and weaponName and threshold and deliveredLogs then
		local remainingLogs = math.max(threshold - deliveredLogs, 0)

		showTemporaryMessage(
			("NEED %d MORE LOGS FOR %s"):format(remainingLogs, string.upper(weaponName)),
			false
		)

		return
	end

	if status == "AllUnlocked" then
		showTemporaryMessage("ALL WEAPONS UNLOCKED", true)
		return
	end

	if status == "Rejected" then
		showTemporaryMessage("UNLOCK UNAVAILABLE", false)
	end
end)
