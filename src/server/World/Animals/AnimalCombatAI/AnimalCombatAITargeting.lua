-- AnimalTargeting
-- Finds player targets for animal AI.

local Players = game:GetService("Players")

local AnimalAIUtils = require(script.Parent:WaitForChild("AnimalCombatAIUtils"))

local AnimalTargeting = {}

function AnimalTargeting.GetNearestPlayerTarget(position: Vector3, maxDistance: number): (BasePart?, Humanoid?)
	local nearestRoot: BasePart? = nil
	local nearestHumanoid: Humanoid? = nil
	local nearestDistance = math.huge

	if maxDistance <= 0 then
		return nil, nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character

		if not character then
			continue
		end

		local humanoid = AnimalAIUtils.GetCharacterHumanoid(character)

		if not humanoid then
			continue
		end

		local root = AnimalAIUtils.GetCharacterRoot(character)

		if not root then
			continue
		end

		local distance = (root.Position - position).Magnitude

		if distance <= maxDistance and distance < nearestDistance then
			nearestRoot = root
			nearestHumanoid = humanoid
			nearestDistance = distance
		end
	end

	return nearestRoot, nearestHumanoid
end

return AnimalTargeting