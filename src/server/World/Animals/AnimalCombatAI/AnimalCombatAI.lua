-- AnimalCombat
-- Handles animal attacks against players.

local AnimalCombat = {}

local function getClosestAnimalPartDistanceToPosition(animal: Model, position: Vector3): number
	local closestDistance = math.huge

	for _, descendant in ipairs(animal:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.CanQuery then
			local distance = (descendant.Position - position).Magnitude

			if distance < closestDistance then
				closestDistance = distance
			end
		end
	end

	return closestDistance
end

function AnimalCombat.TryAttack(
	animal: Model,
	targetRoot: BasePart,
	targetHumanoid: Humanoid,
	settings,
	lastAttackTimeByAnimal: {[Model]: number}
)
	if settings.AttackDamage <= 0 or settings.AttackDistance <= 0 then
		return
	end

	local distance = getClosestAnimalPartDistanceToPosition(animal, targetRoot.Position)

	if distance > settings.AttackDistance then
		return
	end

	local now = os.clock()
	local lastAttackTime = lastAttackTimeByAnimal[animal] or 0

	if now - lastAttackTime < settings.AttackCooldown then
		return
	end

	lastAttackTimeByAnimal[animal] = now
	targetHumanoid:TakeDamage(settings.AttackDamage)
end

return AnimalCombat