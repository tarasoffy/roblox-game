-- StarterPlayerScripts/CooldownDial.client.lua
-- Нативный индикатор КД вокруг курсора: мини-циферблат из 8 линий.
-- 4 большие (N/E/S/W) + 4 маленькие (диагонали).
-- Во время КД метки "исчезают" ПРОТИВ часовой (гаснут по порядку CCW).
-- Без картинок. Видно только во время КД.
--
-- Сервер должен слать:
-- weaponAction:FireClient(player, "Cooldown", { seconds = cfg.cooldown })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local weaponAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WeaponAction")

-- ====== НАСТРОЙКИ ВНЕШНЕГО ВИДА ======
local RADIUS = 18           -- расстояние от курсора до меток
local THICKNESS = 3         -- толщина меток
local BIG_LEN = 12          -- длина больших меток (верх/низ/лево/право)
local SMALL_LEN = 8         -- длина маленьких (диагонали)
local COLOR = Color3.new(1, 1, 1)
local ALPHA_ON = 0          -- прозрачность метки когда "горит" (0 = видно)
local ALPHA_OFF = 0.85      -- прозрачность метки когда "погашена" (0.85 почти не видно)

-- ====== GUI ROOT ======
local gui = Instance.new("ScreenGui")
gui.Name = "CooldownDialGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false -- мы сами вычитаем inset при позиционировании
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromOffset(1, 1)
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Visible = false
root.Parent = gui

-- ====== HELPERS ======
local function makeTick(name: string, length: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Size = UDim2.fromOffset(THICKNESS, length)
	f.BackgroundColor3 = COLOR
	f.BackgroundTransparency = ALPHA_ON
	f.BorderSizePixel = 0
	f.Parent = root

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = f

	return f
end

-- 8 меток (порядок CCW исчезания):
-- стартуем сверху (12 часов) и идём ПРОТИВ часовой:
-- N -> NW -> W -> SW -> S -> SE -> E -> NE
local ticks = {}

ticks[1] = makeTick("N",  BIG_LEN)
ticks[2] = makeTick("NW", SMALL_LEN)
ticks[3] = makeTick("W",  BIG_LEN)
ticks[4] = makeTick("SW", SMALL_LEN)
ticks[5] = makeTick("S",  BIG_LEN)
ticks[6] = makeTick("SE", SMALL_LEN)
ticks[7] = makeTick("E",  BIG_LEN)
ticks[8] = makeTick("NE", SMALL_LEN)

-- позиции вокруг курсора
local sqrt2 = math.sqrt(2)
local function layoutTicks()
	ticks[1].Position = UDim2.fromOffset(0, -RADIUS)
	ticks[1].Rotation = 0

	ticks[2].Position = UDim2.fromOffset(-RADIUS / sqrt2, -RADIUS / sqrt2)
	ticks[2].Rotation = -45

	ticks[3].Position = UDim2.fromOffset(-RADIUS, 0)
	ticks[3].Rotation = -90

	ticks[4].Position = UDim2.fromOffset(-RADIUS / sqrt2, RADIUS / sqrt2)
	ticks[4].Rotation = -135

	ticks[5].Position = UDim2.fromOffset(0, RADIUS)
	ticks[5].Rotation = 180

	ticks[6].Position = UDim2.fromOffset(RADIUS / sqrt2, RADIUS / sqrt2)
	ticks[6].Rotation = 135

	ticks[7].Position = UDim2.fromOffset(RADIUS, 0)
	ticks[7].Rotation = 90

	ticks[8].Position = UDim2.fromOffset(RADIUS / sqrt2, -RADIUS / sqrt2)
	ticks[8].Rotation = 45
end
layoutTicks()

local function setAllOn()
	for i = 1, #ticks do
		ticks[i].BackgroundTransparency = ALPHA_ON
	end
end

local function getEquippedToolName(): string?
	local char = player.Character
	if not char then return nil end
	local tool = char:FindFirstChildOfClass("Tool")
	return tool and tool.Name or nil
end

-- ====== STATE ======
local active = false

local cooldowns = {}

local FIREARM_TOOLS = {
	Rifle = true,
	Deagle = true,
	Shotgun = true,
}

local function getCooldownKey(toolName: string?): string?
	if not toolName then return nil end

	if FIREARM_TOOLS[toolName] then
		return "Firearm"
	end

	return toolName
end

local function startCooldown(seconds: number)
	if seconds <= 0 then return end

	local toolName = getEquippedToolName()
	local key = getCooldownKey(toolName)

	if not key then return end

	local existingCooldown = cooldowns[key]

	if existingCooldown then
		local elapsed = os.clock() - existingCooldown.startT
		local remaining = existingCooldown.duration - elapsed

		if remaining > 0 then
			return
		end
	end

	active = true

	cooldowns[key] = {
		startT = os.clock(),
		duration = seconds,
	}

	-- Прячем обычный курсор на время КД, а наш циферблат становится "курсором"
	UserInputService.MouseIconEnabled = false

	root.Visible = true
	setAllOn()
end

local function stopCooldown()
	active = false
	root.Visible = false

	-- Возвращаем обычный курсор
	UserInputService.MouseIconEnabled = true
end

-- ====== UPDATE LOOP ======
RunService.RenderStepped:Connect(function()
	-- позиция "как у курсора" на разных экранах: вычитаем GuiInset (верхняя панель)
	local inset = GuiService:GetGuiInset()
	local m = UserInputService:GetMouseLocation() - inset

	-- привязка циферблата к мыши
	root.Position = UDim2.fromOffset(m.X, m.Y)

	local toolName = getEquippedToolName()
	local key = getCooldownKey(toolName)

	if not key then
		stopCooldown()
		return
	end

	local cooldown = cooldowns[key]

	if not cooldown then
		stopCooldown()
		return
	end

	local t = os.clock() - cooldown.startT
	local p = math.clamp(t / cooldown.duration, 0, 1)

	if p >= 1 then
		cooldowns[key] = nil
		stopCooldown()
		return
	end

	active = true
	root.Visible = true
	UserInputService.MouseIconEnabled = false

	local total = #ticks
	local offCount = math.floor(p * total + 1e-6)

	for i = 1, total do
		if i <= offCount then
			ticks[i].BackgroundTransparency = ALPHA_OFF
		else
			ticks[i].BackgroundTransparency = ALPHA_ON
		end
	end
end)

-- ====== EVENTS ======
weaponAction.OnClientEvent:Connect(function(kind: string, payload: any)
	if kind == "Cooldown" and typeof(payload) == "table" and typeof(payload.seconds) == "number" then
		startCooldown(payload.seconds)
	end
end)

-- ====== TOOL WATCHER: если игрок сменил/убрал оружие во время КД — скрываем индикатор ======
local function bindCharacter(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			local toolName = getEquippedToolName()
			local key = getCooldownKey(toolName)

			if key and cooldowns[key] then
				active = true
				root.Visible = true
				UserInputService.MouseIconEnabled = false
			end
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			local toolName = getEquippedToolName()
			local key = getCooldownKey(toolName)

			if not key or not cooldowns[key] then
				stopCooldown()
			end
		end
	end)
end

if player.Character then
	bindCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
	bindCharacter(char)

	-- на всякий случай: если персона пересоздалась, не оставляем курсор скрытым
	if not active then
		UserInputService.MouseIconEnabled = true
	end
end)