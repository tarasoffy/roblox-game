local Players = game:GetService("Players")

local AnimalAttack = {}

local FRONT_DOT_MIN = 0.2
local cooldownUntil: {[Player]: number} = {}

local function log(...)
	print("[AnimalAttack]", ...)
end

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function getHumanoid(model: Model): Humanoid?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end

	return nil
end

local function getAnimalType(character: Model): string?
	local animalType = character:GetAttribute("AnimalType")
	if typeof(animalType) == "string" then
		return animalType
	end

	return nil
end

local function isValidTarget(attackerCharacter: Model, candidate: Model): boolean
	if candidate == attackerCharacter then
		return false
	end

	local humanoid = getHumanoid(candidate)
	if not humanoid then
		return false
	end

	return true
end

local function findNearestTarget(attackerCharacter: Model, attackerRoot: BasePart, attackRange: number): (Model?, Humanoid?)
	local parts = workspace:GetPartBoundsInRadius(attackerRoot.Position, attackRange)
	local lookVector = attackerRoot.CFrame.LookVector
	local bestTarget: Model? = nil
	local bestHumanoid: Humanoid? = nil
	local bestDistance = math.huge
	local seen: {[Model]: boolean} = {}

	for _, part in ipairs(parts) do
		if not part:IsA("BasePart") or part:IsDescendantOf(attackerCharacter) then
			continue
		end

		local model = part:FindFirstAncestorOfClass("Model")
		if not model or seen[model] then
			continue
		end

		seen[model] = true

		if not isValidTarget(attackerCharacter, model) then
			continue
		end

		local targetRoot = getRoot(model)
		if not targetRoot then
			continue
		end

		local offset = targetRoot.Position - attackerRoot.Position
		local distance = offset.Magnitude
		if distance <= 0 or distance > attackRange then
			continue
		end

		local dot = lookVector:Dot(offset.Unit)
		if dot <= FRONT_DOT_MIN then
			continue
		end

		if distance < bestDistance then
			bestDistance = distance
			bestTarget = model
			bestHumanoid = getHumanoid(model)
		end
	end

	return bestTarget, bestHumanoid
end

function AnimalAttack.Handle(player: Player, animalConfig)
	local character = player.Character
	if not character then
		log("Rejected: missing character", player.Name)
		return
	end

	if character:GetAttribute("IsAnimalCharacter") ~= true then
		log("Rejected: not an animal character", player.Name)
		return
	end

	local humanoid = getHumanoid(character)
	if not humanoid then
		log("Rejected: attacker humanoid missing or dead", player.Name)
		return
	end

	local animalType = getAnimalType(character)
	local stats = animalType and animalConfig[animalType]
	if not animalType or not stats then
		log("Rejected: missing stats", player.Name, tostring(animalType))
		return
	end

	local damage = stats.Damage
	local attackRange = stats.AttackRange
	local cooldown = stats.AttackCooldown
	if typeof(damage) ~= "number" or typeof(attackRange) ~= "number" or typeof(cooldown) ~= "number" then
		log("Rejected: invalid stats", player.Name, animalType)
		return
	end

	local now = os.clock()
	local nextAllowedAt = cooldownUntil[player] or 0
	if now < nextAllowedAt then
		log("Rejected: cooldown", player.Name, animalType)
		return
	end

	local attackerRoot = getRoot(character)
	if not attackerRoot then
		log("Rejected: missing HumanoidRootPart", player.Name, animalType)
		return
	end

	cooldownUntil[player] = now + cooldown

	local target, targetHumanoid = findNearestTarget(character, attackerRoot, attackRange)
	if not target or not targetHumanoid then
		log("Miss", player.Name, animalType)
		return
	end

	targetHumanoid:TakeDamage(damage)
	log("Hit", player.Name, animalType, "target=", target.Name, "damage=", damage)
end

function AnimalAttack.ClearPlayer(player: Player)
	cooldownUntil[player] = nil
end

return AnimalAttack
