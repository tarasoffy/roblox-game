local MeleeWeapon = {}

local pendingDelayedHits: {[Player]: boolean} = {}

local function applyHit(player: Player, tool: Tool, cfg, dependencies)
	local CombatHelpers = dependencies.CombatHelpers
	local AnimalsService = dependencies.AnimalsService

	local char = CombatHelpers.GetCharacter(player)
	if not char then
		return
	end

	if tool.Parent ~= char then
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
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

		if not AnimalsService.IsDamageableAnimalModel(model) then
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
		AnimalsService.ApplyDamage(bestAnimal, cfg.damage, hrp.Position, player)
	end
end

function MeleeWeapon.Handle(player: Player, tool: Tool, cfg, dependencies)
	local CombatHelpers = dependencies.CombatHelpers
	local CombatCooldowns = dependencies.CombatCooldowns

	if not cfg or not cfg.radius then
		return
	end

	if cfg.impactDelay and pendingDelayedHits[player] then
		return
	end

	if not CombatCooldowns.CanRun(player, cfg.cooldown) then
		return
	end

	local impactDelay = cfg.impactDelay or 0
	if impactDelay > 0 then
		local char = CombatHelpers.GetCharacter(player)
		if not char then
			return
		end

		pendingDelayedHits[player] = true
		local unequipped = false
		local ancestryConn

		ancestryConn = tool.AncestryChanged:Connect(function()
			if tool.Parent ~= char then
				unequipped = true
			end
		end)

		task.delay(impactDelay, function()
			pendingDelayedHits[player] = nil

			if ancestryConn then
				ancestryConn:Disconnect()
			end

			if unequipped then
				return
			end

			applyHit(player, tool, cfg, dependencies)
		end)

		return true
	end

	applyHit(player, tool, cfg, dependencies)
	return true
end

function MeleeWeapon.ClearPlayer(player: Player)
	pendingDelayedHits[player] = nil
end

return MeleeWeapon
