local Config = require(script.Parent:WaitForChild("CooldownDialConfig"))

local CooldownDialView = {}

local CLOCKWISE_ORDER = { 1, 8, 7, 6, 5, 4, 3, 2 }

local root: Frame
local rootScale: UIScale
local ticks = {}

local function makeTick(name: string, length: number): Frame
	local tick = Instance.new("Frame")
	tick.Name = name
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Size = UDim2.fromOffset(Config.THICKNESS, length)
	tick.BackgroundColor3 = Config.COLOR
	tick.BackgroundTransparency = Config.ALPHA_ON
	tick.BorderSizePixel = 0
	tick.Parent = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = tick

	return tick
end

local function layoutTicks()
	local radius = Config.RADIUS
	local sqrt2 = math.sqrt(2)

	ticks[1].Position = UDim2.fromOffset(0, -radius)
	ticks[1].Rotation = 0

	ticks[2].Position = UDim2.fromOffset(-radius / sqrt2, -radius / sqrt2)
	ticks[2].Rotation = -45

	ticks[3].Position = UDim2.fromOffset(-radius, 0)
	ticks[3].Rotation = -90

	ticks[4].Position = UDim2.fromOffset(-radius / sqrt2, radius / sqrt2)
	ticks[4].Rotation = -135

	ticks[5].Position = UDim2.fromOffset(0, radius)
	ticks[5].Rotation = 180

	ticks[6].Position = UDim2.fromOffset(radius / sqrt2, radius / sqrt2)
	ticks[6].Rotation = 135

	ticks[7].Position = UDim2.fromOffset(radius, 0)
	ticks[7].Rotation = 90

	ticks[8].Position = UDim2.fromOffset(radius / sqrt2, -radius / sqrt2)
	ticks[8].Rotation = 45
end

function CooldownDialView.create(parent: Instance)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CooldownDialGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = parent

	root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromOffset(1, 1)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Visible = false
	root.Parent = gui

	rootScale = Instance.new("UIScale")
	rootScale.Scale = 1
	rootScale.Parent = root

	ticks[1] = makeTick("N", Config.BIG_LEN)
	ticks[2] = makeTick("NW", Config.SMALL_LEN)
	ticks[3] = makeTick("W", Config.BIG_LEN)
	ticks[4] = makeTick("SW", Config.SMALL_LEN)
	ticks[5] = makeTick("S", Config.BIG_LEN)
	ticks[6] = makeTick("SE", Config.SMALL_LEN)
	ticks[7] = makeTick("E", Config.BIG_LEN)
	ticks[8] = makeTick("NE", Config.SMALL_LEN)

	layoutTicks()

	return CooldownDialView
end

function CooldownDialView.setAllOn(color: Color3?)
	local tickColor = color or Config.COLOR

	for i = 1, #ticks do
		ticks[i].BackgroundTransparency = Config.ALPHA_ON
		ticks[i].BackgroundColor3 = tickColor
	end

	rootScale.Scale = 1
end

function CooldownDialView.reset()
	CooldownDialView.setAllOn()
	CooldownDialView.setVisible(false)
	CooldownDialView.setScale(1)
end

function CooldownDialView.setVisible(visible: boolean)
	root.Visible = visible
end

function CooldownDialView.setPosition(position: Vector2)
	root.Position = UDim2.fromOffset(position.X, position.Y)
end

function CooldownDialView.setScale(scale: number)
	rootScale.Scale = scale
end

function CooldownDialView.setChargeInitial()
	CooldownDialView.setAllOn()

	for i = 1, #ticks do
		ticks[i].BackgroundTransparency = Config.ALPHA_OFF
		ticks[i].BackgroundColor3 = Config.CHARGE_COLOR
	end
end

function CooldownDialView.setChargeProgress(progress: number)
	local onCount = math.floor(progress * #ticks + 1e-6)

	for orderIndex, tickIndex in ipairs(CLOCKWISE_ORDER) do
		ticks[tickIndex].BackgroundTransparency = orderIndex <= onCount and Config.ALPHA_ON or Config.ALPHA_OFF
		ticks[tickIndex].BackgroundColor3 = Config.CHARGE_COLOR
	end
end

function CooldownDialView.setChargeReady()
	CooldownDialView.setAllOn(Config.CHARGE_COLOR)
end

function CooldownDialView.setCooldownProgress(progress: number)
	local offCount = math.floor(progress * #ticks + 1e-6)

	for i = 1, #ticks do
		if i <= offCount then
			ticks[i].BackgroundTransparency = Config.ALPHA_OFF
		else
			ticks[i].BackgroundTransparency = Config.ALPHA_ON
		end

		ticks[i].BackgroundColor3 = Config.COLOR
	end
end

return CooldownDialView
