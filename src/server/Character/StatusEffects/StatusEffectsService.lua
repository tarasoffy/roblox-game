local StatusEffectsService = {}

type SpeedEffect = {
	speed: number,
	token: number,
}

local activeSpeedEffects: {[Humanoid]: {[string]: SpeedEffect}} = {}
local baseWalkSpeed: {[Humanoid]: number} = {}

local function getEffects(humanoid: Humanoid): {[string]: SpeedEffect}
	local effects = activeSpeedEffects[humanoid]

	if not effects then
		effects = {}
		activeSpeedEffects[humanoid] = effects
	end

	return effects
end

local function updateWalkSpeed(humanoid: Humanoid)
	if not humanoid.Parent then
		activeSpeedEffects[humanoid] = nil
		baseWalkSpeed[humanoid] = nil
		return
	end

	local effects = activeSpeedEffects[humanoid]
	if not effects then
		return
	end

	local slowestSpeed: number? = nil

	for _, effect in pairs(effects) do
		if not slowestSpeed or effect.speed < slowestSpeed then
			slowestSpeed = effect.speed
		end
	end

	if slowestSpeed then
		humanoid.WalkSpeed = slowestSpeed
		return
	end

	local originalSpeed = baseWalkSpeed[humanoid]
	if typeof(originalSpeed) == "number" then
		humanoid.WalkSpeed = originalSpeed
	end

	activeSpeedEffects[humanoid] = nil
	baseWalkSpeed[humanoid] = nil
end

function StatusEffectsService.ApplySpeedEffect(
	player: Player,
	humanoid: Humanoid,
	effectName: string,
	speed: number,
	duration: number?
)
	if not humanoid.Parent then
		return
	end

	if not baseWalkSpeed[humanoid] then
		baseWalkSpeed[humanoid] = humanoid.WalkSpeed
	end

	local effects = getEffects(humanoid)
	local previous = effects[effectName]
	local token = previous and previous.token + 1 or 1

	effects[effectName] = {
		speed = speed,
		token = token,
	}

	player:SetAttribute(effectName, true)

	updateWalkSpeed(humanoid)

	if duration then
		task.delay(duration, function()
			local currentEffects = activeSpeedEffects[humanoid]
			local current = currentEffects and currentEffects[effectName]

			if not current or current.token ~= token then
				return
			end

			StatusEffectsService.RemoveSpeedEffect(player, humanoid, effectName)
		end)
	end
end

function StatusEffectsService.RemoveSpeedEffect(player: Player, humanoid: Humanoid, effectName: string)
	local effects = activeSpeedEffects[humanoid]
	if not effects then
		player:SetAttribute(effectName, false)
		return
	end

	effects[effectName] = nil
	player:SetAttribute(effectName, false)

	updateWalkSpeed(humanoid)
end

function StatusEffectsService.ClearHumanoid(humanoid: Humanoid)
	activeSpeedEffects[humanoid] = nil
	baseWalkSpeed[humanoid] = nil
end

return StatusEffectsService