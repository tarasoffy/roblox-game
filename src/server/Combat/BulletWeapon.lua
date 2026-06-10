local RunService = game:GetService("RunService")

local BulletWeapon = {}

function BulletWeapon.Simulate(player: Player, origin: Vector3, dirUnit: Vector3, cfg, dependencies)
	local CombatHelpers = dependencies.CombatHelpers
	local AnimalsService = dependencies.AnimalsService
	local bulletFX = dependencies.bulletFX

	local char = CombatHelpers.GetCharacter(player)
	if not char then return end

	local bulletId = dependencies.NextProjectileId()

	local maxDist = cfg.range
	local speed = cfg.speed
	local damage = cfg.damage

	bulletFX:FireAllClients("Start", {
		id = bulletId,
		origin = origin,
		dir = dirUnit,
		speed = speed,
		range = maxDist,
	})

	local params = CombatHelpers.MakeRayParams(char)

	local pos = origin
	local travelled = 0

	local startedAt = os.clock()
	local TTL = (maxDist / math.max(speed, 1)) + 0.35
	local MAX_STEP = 4

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if os.clock() - startedAt > TTL then
			if conn then conn:Disconnect() end
			bulletFX:FireAllClients("Stop", { id = bulletId, finalPos = pos })
			return
		end

		dt = math.clamp(dt, 0, 1 / 20)
		local remaining = speed * dt

		while remaining > 0 do
			local stepDist = math.min(remaining, MAX_STEP)
			if travelled + stepDist > maxDist then
				stepDist = maxDist - travelled
			end

			if stepDist <= 0 then
				if conn then conn:Disconnect() end
				bulletFX:FireAllClients("Stop", { id = bulletId, finalPos = pos })
				return
			end

			local stepVec = dirUnit * stepDist
			local result = workspace:Raycast(pos, stepVec, params)

			if result then
				if conn then conn:Disconnect() end

				local hitPos = result.Position
				bulletFX:FireAllClients("Stop", { id = bulletId, finalPos = hitPos })

				local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
				if hitModel and AnimalsService.IsDamageableAnimalModel(hitModel) then
					AnimalsService.ApplyDamage(hitModel, damage, hitPos, player)
				end

				return
			end

			pos += stepVec
			travelled += stepDist
			remaining -= stepDist

			if travelled >= maxDist then
				if conn then conn:Disconnect() end
				bulletFX:FireAllClients("Stop", { id = bulletId, finalPos = pos })
				return
			end
		end
	end)
end

return BulletWeapon
