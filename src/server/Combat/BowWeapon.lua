local RunService = game:GetService("RunService")

local BowWeapon = {}

function BowWeapon.Simulate(player: Player, origin: Vector3, aimPos: Vector3, cfg, dependencies)
	local CombatHelpers = dependencies.CombatHelpers
	local AnimalsService = dependencies.AnimalsService
	local bulletFX = dependencies.bulletFX

	local char = CombatHelpers.GetCharacter(player)
	if not char then
		return
	end

	local vectorToAim = aimPos - origin
	if vectorToAim.Magnitude < 0.1 then
		return
	end

	local dirUnit = vectorToAim.Unit
	local chargePower = math.clamp(dependencies.ChargePower or 1, 0, 1)
	local maxDist = (cfg.range or 220) * chargePower
	local speed = (cfg.speed or 170) * chargePower
	local gravity = cfg.gravity or 75
	local damage = cfg.damage or 25

	local arrowId = dependencies.NextProjectileId()

	bulletFX:FireAllClients("ArrowStart", {
		id = arrowId,
		origin = origin,
		dir = dirUnit,
		speed = speed,
		range = maxDist,
		gravity = gravity,
	})

	local params = CombatHelpers.MakeRayParams(char)

	local pos = origin
	local velocity = dirUnit * speed
	local travelled = 0

	local startedAt = os.clock()
	local TTL = (maxDist / math.max(speed, 1)) + 2.0
	local MAX_STEP = 6

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if os.clock() - startedAt > TTL then
			if conn then
				conn:Disconnect()
			end

			bulletFX:FireAllClients("ArrowStop", {
				id = arrowId,
				finalPos = pos,
			})
			return
		end

		dt = math.clamp(dt, 0, 1 / 30)

		velocity = velocity + Vector3.new(0, -gravity, 0) * dt

		local desired = velocity * dt
		local desiredDist = desired.Magnitude

		if desiredDist < 1e-6 then
			return
		end

		local segments = math.max(1, math.ceil(desiredDist / MAX_STEP))
		local stepVec = desired / segments

		for _ = 1, segments do
			local stepDist = stepVec.Magnitude

			if travelled + stepDist > maxDist then
				stepVec = stepVec.Unit * math.max(0, maxDist - travelled)
				stepDist = stepVec.Magnitude
			end

			if stepDist <= 0 then
				if conn then
					conn:Disconnect()
				end

				bulletFX:FireAllClients("ArrowStop", {
					id = arrowId,
					finalPos = pos,
				})
				return
			end

			local result = workspace:Raycast(pos, stepVec, params)
			if result then
				if conn then
					conn:Disconnect()
				end

				local hitPos = result.Position

				bulletFX:FireAllClients("ArrowStop", {
					id = arrowId,
					finalPos = hitPos,
				})

				local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
				if hitModel and AnimalsService.IsDamageableAnimalModel(hitModel) then
					AnimalsService.ApplyDamage(hitModel, damage, hitPos, player)
				end

				return
			end

			pos += stepVec
			travelled += stepDist

			if travelled >= maxDist then
				if conn then
					conn:Disconnect()
				end

				bulletFX:FireAllClients("ArrowStop", {
					id = arrowId,
					finalPos = pos,
				})
				return
			end
		end
	end)
end

return BowWeapon
