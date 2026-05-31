local CombatCooldowns = {}

local lastActionAt: {[Player]: number} = {}
local firearmCooldownUntil: {[Player]: number} = {}

local FIREARM_TOOLS = {
	Rifle = true,
	Deagle = true,
	Revolver = true,
	Shotgun = true,
}

function CombatCooldowns.IsFirearm(toolName: string): boolean
	return FIREARM_TOOLS[toolName] == true
end

function CombatCooldowns.CanRun(player: Player, cooldown: number): boolean
	local now = os.clock()
	local last = lastActionAt[player] or 0

	if now - last < cooldown then
		return false
	end

	lastActionAt[player] = now
	return true
end

function CombatCooldowns.GetFirearmCooldownRemaining(player: Player): number
	local untilTime = firearmCooldownUntil[player] or 0
	return math.max(0, untilTime - os.clock())
end

function CombatCooldowns.StartFirearmCooldown(player: Player, seconds: number)
	firearmCooldownUntil[player] = os.clock() + seconds
end

function CombatCooldowns.ClearPlayer(player: Player)
	lastActionAt[player] = nil
	firearmCooldownUntil[player] = nil
end

return CombatCooldowns
