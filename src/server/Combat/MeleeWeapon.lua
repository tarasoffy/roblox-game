local MeleeWeapon = {}

function MeleeWeapon.Handle(player: Player, tool: Tool, cfg, dependencies)
	local CombatHelpers = dependencies.CombatHelpers
	local CombatCooldowns = dependencies.CombatCooldowns
	local AnimalsService = dependencies.AnimalsService

	if not cfg or not cfg.radius then
		return
	end

	if not CombatCooldowns.CanRun(player, cfg.cooldown) then
		return
	end

	local char = CombatHelpers.GetCharacter(player)
	if not char then
		return
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	local parts = workspace:GetPartBoundsInRadius(hrp.Position, cfg.radius)
	local bestAnimal: Model? = nil
	local bestDist = math.huge

	for _, part in ipairs(parts) do
		if not part:IsA("BasePart") then
			continue
		end

		if part:IsDescendantOf(char) then
			continue
		end

		local model = part:FindFirstAncestorOfClass("Model")
		if not model then
			continue
		end

		if not AnimalsService.IsAnimalModel(model) then
			continue
		end

		if model:GetAttribute("Dead") then
			continue
		end

		local animalPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if not animalPart then
			continue
		end

		local distance = (hrp.Position - animalPart.Position).Magnitude
		if distance < bestDist then
			bestDist = distance
			bestAnimal = model
		end
	end

	if bestAnimal then
		AnimalsService.ApplyDamage(bestAnimal, cfg.damage, hrp.Position)
	end
end

return MeleeWeapon