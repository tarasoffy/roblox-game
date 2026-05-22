-- HUDView
-- Creates and updates the survival HUD UI.

local StarterGui = game:GetService("StarterGui")

local HUDView = {}

local function styleCard(frame: Frame, config)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, config.CARD_RADIUS)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.75
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = frame
end

local function makeLabel(parent: Instance, text: string, yOffset: number, config)
	local label = Instance.new("TextLabel")
	label.Name = text .. "_Label"
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 0, 0, yOffset + config.BAR_HEIGHT / 2)
	label.Size = UDim2.new(0, config.LABEL_WIDTH, 0, config.BAR_HEIGHT)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = config.LABEL_TEXT_SIZE
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 12
	label.Parent = parent

	return label
end

local function makeBar(parent: Instance, name: string, yOffset: number, fillColor: Color3, config)
	makeLabel(parent, name, yOffset, config)

	local bg = Instance.new("Frame")
	bg.Name = name .. "_Bg"
	bg.AnchorPoint = Vector2.new(0, 0)
	bg.Position = UDim2.new(0, config.LABEL_WIDTH + 8, 0, yOffset)
	bg.Size = UDim2.new(0, config.BAR_WIDTH, 0, config.BAR_HEIGHT)
	bg.BackgroundTransparency = 0.35
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bg.BorderSizePixel = 0
	bg.ZIndex = 10
	bg.Parent = parent

	local fill = Instance.new("Frame")
	fill.Name = name .. "_Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.ZIndex = 11
	fill.Parent = bg

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = bg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	return bg, fill
end

function HUDView.Create(player: Player, config)
	local gui = Instance.new("ScreenGui")
	gui.Name = "PlayerHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)

	local damage = Instance.new("Frame")
	damage.Name = "DamageVignette"
	damage.Size = UDim2.fromScale(1, 1)
	damage.Position = UDim2.fromScale(0, 0)
	damage.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	damage.BackgroundTransparency = 1
	damage.BorderSizePixel = 0
	damage.ZIndex = 999
	damage.Parent = gui

	local card = Instance.new("Frame")
	card.Name = "StatsCard"
	card.AnchorPoint = Vector2.new(0, 1)
	card.Position = UDim2.new(0, config.CARD_SIDE_PAD, 1, -config.CARD_BOTTOM_PAD)
	card.Size = UDim2.fromOffset(config.CARD_WIDTH, config.CARD_HEIGHT)
	card.Parent = gui

	styleCard(card, config)

	local row0 = 0
	local row1 = (config.BAR_HEIGHT + config.BAR_GAP) * 1
	local row2 = (config.BAR_HEIGHT + config.BAR_GAP) * 2

	local healthBg, healthFill = makeBar(card, "HEALTH", row0, Color3.fromRGB(220, 80, 80), config)
	local hungerBg, hungerFill = makeBar(card, "HUNGER", row1, Color3.fromRGB(230, 180, 60), config)
	local staminaBg, staminaFill = makeBar(card, "STAMINA", row2, Color3.fromRGB(80, 200, 80), config)

	return {
		gui = gui,
		card = card,
		damage = damage,

		healthFill = healthFill,
		healthBg = healthBg,

		hungerFill = hungerFill,
		hungerBg = hungerBg,

		staminaFill = staminaFill,
		staminaBg = staminaBg,
	}
end

function HUDView.SetBar(fill: Frame, bg: Frame, ratio: number)
	ratio = math.clamp(ratio, 0, 1)
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	bg.Visible = true
end

return HUDView