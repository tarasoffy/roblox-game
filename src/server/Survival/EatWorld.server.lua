-- EatWorld.server.lua (ServerScriptService)
-- Eat food from ground by pressing E.
-- Poison food applies damage + slow + poison flag.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatusEffectsService = require(
	game.ServerScriptService
		:WaitForChild("Character")
		:WaitForChild("StatusEffects")
		:WaitForChild("StatusEffectsService")
)

-------------------------------------------------
-- Remote
-------------------------------------------------
local invEvent = ReplicatedStorage:FindFirstChild("InventoryEvent")
if not invEvent then
	invEvent = Instance.new("RemoteEvent")
	invEvent.Name = "InventoryEvent"
	invEvent.Parent = ReplicatedStorage
end

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local EAT_DISTANCE = 10

local FOOD_VALUES = {
	Meat = { raw = 5, cooked = 10 },
	Mushroom = { raw = 3, cooked = 7 },
	Blueberry = { raw = 2 },

	-- ЯДОВИТЫЙ ГРИБ
	Mushroom_Trampoline = {
		raw = -10,     -- <-- теперь будет работать
		damage = 15,
		slow = { speed = 8, duration = 6 },
	},
}

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function getHumanoid(plr: Player): Humanoid?
	local char = plr.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum:IsA("Humanoid") then return hum end
	return nil
end

local function getRoot(plr: Player): BasePart?
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end
	return nil
end

local function getWorldPos(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position
	end
	if inst:IsA("Model") then
		local p = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
		if p then return p.Position end
	end
	return nil
end

local function resolveTarget(inst: Instance): (Instance?, string?)
	local cur = inst
	while cur and cur ~= workspace do
		local id = cur:GetAttribute("PickupId")
		if typeof(id) == "string" and id ~= "" then
			return cur, id
		end
		cur = cur.Parent
	end
	return nil, nil
end

local function isFood(inst: Instance): boolean
	if inst:GetAttribute("Food") == true then return true end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:GetAttribute("Food") == true then
			return true
		end
	end
	return false
end

local function isCooked(inst: Instance): boolean
	if inst:GetAttribute("Cooked") == true then return true end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:GetAttribute("Cooked") == true then
			return true
		end
	end
	return false
end

local function addHunger(plr: Player, amount: number)
	local maxH = plr:GetAttribute("HungerMax") or 100
	local h = plr:GetAttribute("Hunger")
	if typeof(h) ~= "number" then h = maxH end
	plr:SetAttribute("Hunger", math.clamp(h + amount, 0, maxH))
end

-------------------------------------------------
-- SLOW + POISON
-------------------------------------------------
local function applyPoison(plr: Player, hum: Humanoid, slowCfg)
	StatusEffectsService.ApplySpeedEffect(
		plr,
		hum,
		"Poisoned",
		slowCfg.speed,
		slowCfg.duration
	)
end

-------------------------------------------------
-- MAIN
-------------------------------------------------
local function eatWorld(plr: Player, hit: Instance)
	local target, id = resolveTarget(hit)
	if not target or not id then return end
	if not isFood(target) then return end

	local cfg = FOOD_VALUES[id]
	if not cfg then return end

	local hrp = getRoot(plr)
	if not hrp then return end

	local pos = getWorldPos(target)
	if not pos or (hrp.Position - pos).Magnitude > EAT_DISTANCE then
		return
	end

	-- hunger (теперь работает и + и -)
	local add = cfg.raw
	if isCooked(target) and cfg.cooked then
		add = cfg.cooked
	end
	if typeof(add) == "number" and add ~= 0 then
		addHunger(plr, add)
	end

	-- damage
	local dmg = cfg.damage
	if typeof(dmg) == "number" and dmg > 0 then
		local hum = getHumanoid(plr)
		if hum and hum.Health > 0 then
			hum:TakeDamage(dmg)
		end
	end

	-- poison slow
	if cfg.slow then
		local hum = getHumanoid(plr)
		if hum and hum.Health > 0 then
			applyPoison(plr, hum, cfg.slow)
		end
	end

	target:Destroy()
end

-------------------------------------------------
-- RESET FLAGS ON SPAWN
-------------------------------------------------
Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("Poisoned", false)
	plr.CharacterAdded:Connect(function()
		plr:SetAttribute("Poisoned", false)
	end)
end)

invEvent.OnServerEvent:Connect(function(plr, action, target)
	if action == "eatWorld" and target then
		eatWorld(plr, target)
	end
end)