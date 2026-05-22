-- Hunger.server.lua (ServerScriptService)
-- Hunger decreases over time.
-- When Hunger == 0 -> periodic damage + slow (WalkSpeed forced low).
-- No regen logic here (regen is handled elsewhere).

local Players = game:GetService("Players")

local StatusEffectsService = require(
	game.ServerScriptService
		:WaitForChild("Character")
		:WaitForChild("StatusEffects")
		:WaitForChild("StatusEffectsService")
)

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local HUNGER_MAX = 100

local DRAIN_PER_MIN = 8 -- 8
local DRAIN_PER_SEC = DRAIN_PER_MIN / 60

-- Starvation damage
local STARVE_DAMAGE = 5
local STARVE_INTERVAL = 2

-- Starvation slow
local STARVE_SLOW_SPEED = 8

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function getHumanoid(player: Player): Humanoid?
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum:IsA("Humanoid") then return hum end
	return nil
end

-------------------------------------------------
-- INIT
-------------------------------------------------
Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("HungerMax", HUNGER_MAX)
	plr:SetAttribute("Hunger", HUNGER_MAX)
	plr:SetAttribute("LastStarveTick", 0)
	plr:SetAttribute("Starving", false)

	-- on respawn reset starving flag
	plr.CharacterAdded:Connect(function()
		plr:SetAttribute("Starving", false)
	end)
end)

-------------------------------------------------
-- MAIN LOOP
-------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)

		for _, plr in ipairs(Players:GetPlayers()) do
			-- hunger values
			local maxH = plr:GetAttribute("HungerMax")
			if typeof(maxH) ~= "number" then
				maxH = HUNGER_MAX
			end

			local h = plr:GetAttribute("Hunger")
			if typeof(h) ~= "number" then
				h = maxH
			end

			-- drain hunger
			h -= DRAIN_PER_SEC
			if h < 0 then h = 0 end
			plr:SetAttribute("Hunger", h)

			local hum = getHumanoid(plr)

			-- starvation effects
			if h <= 0 then
				if hum and hum.Health > 0 then
					StatusEffectsService.ApplySpeedEffect(plr, hum, "Starving", STARVE_SLOW_SPEED)

					local now = os.clock()
					local last = plr:GetAttribute("LastStarveTick") or 0
					if now - last >= STARVE_INTERVAL then
						hum:TakeDamage(STARVE_DAMAGE)
						plr:SetAttribute("LastStarveTick", now)
					end
				end
			else
				-- if not starving anymore, restore speed
				if hum then
					StatusEffectsService.RemoveSpeedEffect(plr, hum, "Starving")
				else
					plr:SetAttribute("Starving", false)
				end
			end
		end
	end
end)