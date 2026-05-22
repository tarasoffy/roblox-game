-- AutoRegen.server.lua (ServerScriptService)
-- Health regen ONLY if player is not hungry and not poisoned

local Players = game:GetService("Players")

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local REGEN_PER_SEC = 1
local TICK = 1

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function getHumanoid(plr: Player): Humanoid?
	local char = plr.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function canRegen(plr: Player): boolean
	local hunger = plr:GetAttribute("Hunger")
	if typeof(hunger) ~= "number" or hunger <= 0 then
		return false
	end
	if plr:GetAttribute("Poisoned") == true then
		return false
	end
	return true
end

-------------------------------------------------
-- LOOP
-------------------------------------------------
task.spawn(function()
	while true do
		task.wait(TICK)

		for _, plr in ipairs(Players:GetPlayers()) do
			local hum = getHumanoid(plr)
			if not hum or hum.Health <= 0 then
				continue
			end

			if canRegen(plr) then
				hum.Health = math.min(
					hum.MaxHealth,
					hum.Health + REGEN_PER_SEC
				)
			end
		end
	end
end)