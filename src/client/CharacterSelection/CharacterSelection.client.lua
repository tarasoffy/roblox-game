local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local selectCharacterEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SelectCharacter")
local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))

local CHARACTER_NAMES = {
	"Human",
	"Fox",
	"Wolf",
	"Bear",
	"Boar",
}

local DEFAULT_CHARACTER = "Wolf"
local ACCENT_BLUE = Color3.fromRGB(42, 115, 255)
local CARD_STROKE = Color3.fromRGB(105, 105, 105)

local selectedCharacter = DEFAULT_CHARACTER
local confirming = false
local menuOpen = true
local controls = nil
local cardViews: {[string]: {button: TextButton, stroke: UIStroke, check: Frame}} = {}

local function getControls()
	if controls then
		return controls
	end

	local ok, result = pcall(function()
		return playerModule:GetControls()
	end)

	if ok then
		controls = result
	end

	return controls
end

local function setCharacterMovementEnabled(character: Model?, enabled: boolean)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if enabled then
		return
	end

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.Sit = false
end

local function setControlsEnabled(enabled: boolean)
	local currentControls = getControls()
	if currentControls then
		if enabled then
			currentControls:Enable()
		else
			currentControls:Disable()
		end
	end

	setCharacterMovementEnabled(player.Character, enabled)
end

local existingGui = playerGui:FindFirstChild("CharacterSelectionGui")
if existingGui then
	existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CharacterSelectionGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.92, 0.72)
panel.BackgroundColor3 = Color3.fromRGB(18, 20, 22)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = overlay

local panelSizeConstraint = Instance.new("UISizeConstraint")
panelSizeConstraint.MinSize = Vector2.new(320, 360)
panelSizeConstraint.MaxSize = Vector2.new(1180, 720)
panelSizeConstraint.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(75, 78, 82)
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.15
panelStroke.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 36)
panelPadding.PaddingBottom = UDim.new(0, 34)
panelPadding.PaddingLeft = UDim.new(0, 24)
panelPadding.PaddingRight = UDim.new(0, 24)
panelPadding.Parent = panel

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Size = UDim2.fromScale(1, 1)
content.Parent = panel

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 18)
contentLayout.Parent = content

local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 1
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 48)
title.Font = Enum.Font.GothamBold
title.Text = "CHOOSE YOUR CHARACTER"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextScaled = true
title.TextWrapped = true
title.Parent = content

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MinTextSize = 24
titleConstraint.MaxTextSize = 42
titleConstraint.Parent = title

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.LayoutOrder = 2
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, 0, 0, 28)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Select who you want to play as before the match starts."
subtitle.TextColor3 = Color3.fromRGB(195, 198, 202)
subtitle.TextScaled = true
subtitle.TextWrapped = true
subtitle.Parent = content

local subtitleConstraint = Instance.new("UITextSizeConstraint")
subtitleConstraint.MinTextSize = 14
subtitleConstraint.MaxTextSize = 24
subtitleConstraint.Parent = subtitle

local cardsRow = Instance.new("Frame")
cardsRow.Name = "CardsRow"
cardsRow.LayoutOrder = 3
cardsRow.BackgroundTransparency = 1
cardsRow.Size = UDim2.new(1, 0, 0.56, 0)
cardsRow.Parent = content

local cardsLayout = Instance.new("UIListLayout")
cardsLayout.FillDirection = Enum.FillDirection.Horizontal
cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
cardsLayout.Padding = UDim.new(0.018, 0)
cardsLayout.Parent = cardsRow

local function setSelected(characterName: string)
	selectedCharacter = characterName

	for name, view in pairs(cardViews) do
		local selected = name == selectedCharacter
		view.stroke.Color = selected and ACCENT_BLUE or CARD_STROKE
		view.stroke.Thickness = selected and 2.5 or 1.5
		view.stroke.Transparency = selected and 0 or 0.35
		view.check.Visible = selected
	end
end

local function createCard(characterName: string, layoutOrder: number)
	local button = Instance.new("TextButton")
	button.Name = characterName .. "Card"
	button.LayoutOrder = layoutOrder
	button.AutoButtonColor = true
	button.BackgroundColor3 = Color3.fromRGB(42, 44, 47)
	button.BackgroundTransparency = 0.1
	button.BorderSizePixel = 0
	button.Size = UDim2.new(0.18, 0, 1, 0)
	button.Text = ""
	button.Parent = cardsRow

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 0.56
	aspect.DominantAxis = Enum.DominantAxis.Height
	aspect.Parent = button

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = CARD_STROKE
	stroke.Thickness = 1.5
	stroke.Transparency = 0.35
	stroke.Parent = button

	local placeholder = Instance.new("Frame")
	placeholder.Name = "ImagePlaceholder"
	placeholder.BackgroundColor3 = Color3.fromRGB(70, 72, 75)
	placeholder.BackgroundTransparency = 0.48
	placeholder.BorderSizePixel = 0
	placeholder.Size = UDim2.new(1, 0, 0.76, 0)
	placeholder.Parent = button

	local placeholderCorner = Instance.new("UICorner")
	placeholderCorner.CornerRadius = UDim.new(0, 18)
	placeholderCorner.Parent = placeholder

	local nameBand = Instance.new("Frame")
	nameBand.Name = "NameBand"
	nameBand.AnchorPoint = Vector2.new(0, 1)
	nameBand.Position = UDim2.fromScale(0, 1)
	nameBand.Size = UDim2.new(1, 0, 0.24, 0)
	nameBand.BackgroundColor3 = Color3.fromRGB(11, 12, 14)
	nameBand.BackgroundTransparency = 0.25
	nameBand.BorderSizePixel = 0
	nameBand.Parent = button

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = string.upper(characterName)
	nameLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = true
	nameLabel.Parent = nameBand

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MinTextSize = 14
	nameConstraint.MaxTextSize = 26
	nameConstraint.Parent = nameLabel

	local check = Instance.new("Frame")
	check.Name = "SelectedCheck"
	check.AnchorPoint = Vector2.new(1, 0)
	check.Position = UDim2.new(1, -10, 0, 10)
	check.Size = UDim2.fromOffset(42, 42)
	check.BackgroundColor3 = ACCENT_BLUE
	check.BorderSizePixel = 0
	check.Visible = false
	check.Parent = button

	local checkAspect = Instance.new("UIAspectRatioConstraint")
	checkAspect.AspectRatio = 1
	checkAspect.Parent = check

	local checkCorner = Instance.new("UICorner")
	checkCorner.CornerRadius = UDim.new(1, 0)
	checkCorner.Parent = check

	cardViews[characterName] = {
		button = button,
		stroke = stroke,
		check = check,
	}

	button.Activated:Connect(function()
		setSelected(characterName)
	end)
end

for index, characterName in ipairs(CHARACTER_NAMES) do
	createCard(characterName, index)
end

local confirmButton = Instance.new("TextButton")
confirmButton.Name = "ConfirmSelectionButton"
confirmButton.LayoutOrder = 4
confirmButton.AutoButtonColor = true
confirmButton.BackgroundColor3 = ACCENT_BLUE
confirmButton.BorderSizePixel = 0
confirmButton.Size = UDim2.new(0.46, 0, 0, 72)
confirmButton.Font = Enum.Font.GothamBold
confirmButton.Text = "CONFIRM SELECTION"
confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmButton.TextScaled = true
confirmButton.TextWrapped = true
confirmButton.Parent = content

local confirmSizeConstraint = Instance.new("UISizeConstraint")
confirmSizeConstraint.MinSize = Vector2.new(230, 52)
confirmSizeConstraint.MaxSize = Vector2.new(520, 72)
confirmSizeConstraint.Parent = confirmButton

local confirmTextConstraint = Instance.new("UITextSizeConstraint")
confirmTextConstraint.MinTextSize = 18
confirmTextConstraint.MaxTextSize = 30
confirmTextConstraint.Parent = confirmButton

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 12)
confirmCorner.Parent = confirmButton

confirmButton.Activated:Connect(function()
	if confirming then
		return
	end

	confirming = true
	menuOpen = false
	confirmButton.Active = false
	confirmButton.AutoButtonColor = false
	confirmButton.Text = "CONFIRMING..."
	print("[CharacterSelection] Selected character:", selectedCharacter)
	selectCharacterEvent:FireServer(selectedCharacter)
end)

setSelected(DEFAULT_CHARACTER)
setControlsEnabled(false)

player.CharacterAdded:Connect(function(character)
	if menuOpen then
		task.defer(function()
			setCharacterMovementEnabled(character, false)
		end)
	end
end)

selectCharacterEvent.OnClientEvent:Connect(function(selectionAccepted: boolean, confirmedCharacter: string)
	if not selectionAccepted then
		menuOpen = true
		confirming = false
		confirmButton.Active = true
		confirmButton.AutoButtonColor = true
		confirmButton.Text = "CONFIRM SELECTION"
		setControlsEnabled(false)
		warn("[CharacterSelection] Server rejected character selection:", confirmedCharacter)
		return
	end

	menuOpen = false
	gui.Enabled = false
	setControlsEnabled(true)
end)
