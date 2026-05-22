local RangedWeapon = {}

function RangedWeapon.Handle(player: Player, tool: Tool, data: any, cfg, dependencies)
	local weaponAction = dependencies.weaponAction
	local bulletFX = dependencies.bulletFX

	local CombatCooldowns = dependencies.CombatCooldowns
	local CombatHelpers = dependencies.CombatHelpers

	local BulletWeapon = dependencies.BulletWeapon
	local ShotgunWeapon = dependencies.ShotgunWeapon
	local BowWeapon = dependencies.BowWeapon

	if typeof(data) ~= "table" or typeof(data.aimPos) ~= "Vector3" then
		return
	end

	if not cfg or typeof(cfg) ~= "table" then
		return
	end

	local cooldown = cfg.cooldown or 0
	local isBow = cfg.projectile == "Arrow" or tool.Name == "Bow"
	local bowChargePower: number? = nil

	if isBow then
		local chargeTime = cfg.chargeTime or 1
		local minChargeToShoot = cfg.minChargeToShoot or 0
		local serverChargeStartedAt = dependencies.BowChargeStartedAt

		if typeof(serverChargeStartedAt) ~= "number" or chargeTime <= 0 then
			return
		end

		local requestedChargePower = typeof(data.chargePower) == "number" and data.chargePower or 0
		local serverChargePower = math.clamp((os.clock() - serverChargeStartedAt) / chargeTime, 0, 1)
		bowChargePower = math.clamp(math.min(requestedChargePower, serverChargePower + 0.05), 0, 1)

		if bowChargePower < minChargeToShoot then
			return
		end
	end

	if CombatCooldowns.IsFirearm(tool.Name) then
		local remaining = CombatCooldowns.GetFirearmCooldownRemaining(player)

		if remaining > 0 then
			weaponAction:FireClient(player, "Cooldown", {
				seconds = remaining,
				group = "Firearm",
				sourceToolName = tool.Name,
			})
			return
		end

		CombatCooldowns.StartFirearmCooldown(player, cooldown)

		weaponAction:FireClient(player, "Cooldown", {
			seconds = cooldown,
			group = "Firearm",
			sourceToolName = tool.Name,
		})
	else
		if not CombatCooldowns.CanRun(player, cooldown) then
			return
		end

		weaponAction:FireClient(player, "Cooldown", {
			seconds = cooldown,
			sourceToolName = tool.Name,
			initialProgress = bowChargePower,
		})
	end

	CombatHelpers.PlayGunShot(tool)

	local char = CombatHelpers.GetCharacter(player)
	if not char then
		return
	end

	local origin = CombatHelpers.GetMuzzleWorldPos(tool, char)

	if isBow then
		BowWeapon.Simulate(player, origin, data.aimPos, cfg, {
			CombatHelpers = CombatHelpers,
			AnimalsService = dependencies.AnimalsService,
			bulletFX = bulletFX,
			NextProjectileId = dependencies.NextProjectileId,
			ChargePower = bowChargePower,
		})

		return true
	end

	if cfg.pellets and cfg.pellets > 1 then
		ShotgunWeapon.Shoot(player, origin, data.aimPos, cfg, {
			CombatHelpers = CombatHelpers,
			AnimalsService = dependencies.AnimalsService,
			bulletFX = bulletFX,
			NextProjectileId = dependencies.NextProjectileId,
			RNG = dependencies.RNG,
		})

		return true
	end

	if not cfg.range or not cfg.speed then
		return
	end

	local dir = data.aimPos - origin
	if dir.Magnitude < 1 then
		return
	end

	BulletWeapon.Simulate(player, origin, dir.Unit, cfg, {
		CombatHelpers = CombatHelpers,
		AnimalsService = dependencies.AnimalsService,
		bulletFX = bulletFX,
		NextProjectileId = dependencies.NextProjectileId,
	})

	return true
end

return RangedWeapon
