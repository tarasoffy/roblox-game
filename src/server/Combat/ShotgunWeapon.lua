local ShotgunWeapon = {}

local function makeBasis(forward: Vector3)
	local up = Vector3.new(0, 1, 0)

	if math.abs(forward:Dot(up)) > 0.98 then
		up = Vector3.new(1, 0, 0)
	end

	local right = forward:Cross(up).Unit
	local realUp = right:Cross(forward).Unit

	return right, realUp
end

local function randomDirInCone(forwardUnit: Vector3, maxAngleRad: number, rng: Random): Vector3
	local u = rng:NextNumber()
	local v = rng:NextNumber()

	local cosMax = math.cos(maxAngleRad)
	local cosTheta = 1 - u * (1 - cosMax)
	local sinTheta = math.sqrt(math.max(0, 1 - cosTheta * cosTheta))
	local phi = 2 * math.pi * v

	local right, up = makeBasis(forwardUnit)
	local lateral = (right * math.cos(phi) + up * math.sin(phi)) * sinTheta

	return (forwardUnit * cosTheta + lateral).Unit
end

local function spawnTracer(origin: Vector3, dirUnit: Vector3, speed: number, range: number, finalPos: Vector3, dependencies)
	local bulletFX = dependencies.bulletFX
	local bulletId = dependencies.NextProjectileId()

	bulletFX:FireAllClients("Start", {
		id = bulletId,
		origin = origin,
		dir = dirUnit,
		speed = speed,
		range = range,
	})

	local dist = (finalPos - origin).Magnitude
	local t = dist / math.max(speed, 1)

	task.delay(t, function()
		bulletFX:FireAllClients("Stop", {
			id = bulletId,
			finalPos = finalPos,
		})
	end)
end

function ShotgunWeapon.Shoot(player: Player, origin: Vector3, aimPos: Vector3, cfg, dependencies)
	local CombatHelpers = dependencies.CombatHelpers
	local AnimalsService = dependencies.AnimalsService
	local rng = dependencies.RNG

	local char = CombatHelpers.GetCharacter(player)
	if not char then
		return
	end

	local base = aimPos - origin
	local dist = base.Magnitude

	if dist < 0.001 then
		return
	end

	local forward = base.Unit
	local params = CombatHelpers.MakeRayParams(char)

	local pellets = cfg.pellets or 6
	local spreadRad = math.rad(cfg.spreadDeg or 9)

	local MIN_ORIGIN_PUSH = 2.0
	if dist < MIN_ORIGIN_PUSH then
		origin = origin - forward * (MIN_ORIGIN_PUSH - dist)
	end

	local CONTACT_DIST = 1.2
	local CONTACT_RADIUS = 1.5

	if dist < CONTACT_DIST then
		local parts = workspace:GetPartBoundsInRadius(origin, CONTACT_RADIUS, params)
		local damaged = false

		for _, part in ipairs(parts) do
			if part:IsA("BasePart") and not part:IsDescendantOf(char) then
				local model = part:FindFirstAncestorOfClass("Model")

				if model and AnimalsService.IsAnimalModel(model) then
					AnimalsService.ApplyDamage(model, cfg.damage, origin)
					damaged = true
					break
				end
			end
		end

		for _ = 1, pellets do
			local dir = randomDirInCone(forward, spreadRad, rng)
			local castVec = dir * cfg.range

			spawnTracer(origin, dir, cfg.speed, cfg.range, origin + castVec, dependencies)
		end

		if damaged then
			return
		end
	end

	for _ = 1, pellets do
		local dir = randomDirInCone(forward, spreadRad, rng)
		local castVec = dir * cfg.range

		local result = workspace:Raycast(origin, castVec, params)
		local hitPos = origin + castVec

		if result then
			hitPos = result.Position

			local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
			if hitModel and AnimalsService.IsAnimalModel(hitModel) then
				AnimalsService.ApplyDamage(hitModel, cfg.damage, hitPos)
			end
		end

		spawnTracer(origin, dir, cfg.speed, cfg.range, hitPos, dependencies)
	end
end

return ShotgunWeapon