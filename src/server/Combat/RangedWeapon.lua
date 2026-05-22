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
		})
	end

	CombatHelpers.PlayGunShot(tool)

	local char = CombatHelpers.GetCharacter(player)
	if not char then
		return
	end

	local origin = CombatHelpers.GetMuzzleWorldPos(tool, char)

	if cfg.projectile == "Arrow" or tool.Name == "Bow" then
		BowWeapon.Simulate(player, origin, data.aimPos, cfg, {
			CombatHelpers = CombatHelpers,
			AnimalsService = dependencies.AnimalsService,
			bulletFX = bulletFX,
			NextProjectileId = dependencies.NextProjectileId,
		})

		return
	end

	if cfg.pellets and cfg.pellets > 1 then
		ShotgunWeapon.Shoot(player, origin, data.aimPos, cfg, {
			CombatHelpers = CombatHelpers,
			AnimalsService = dependencies.AnimalsService,
			bulletFX = bulletFX,
			NextProjectileId = dependencies.NextProjectileId,
			RNG = dependencies.RNG,
		})

		return
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
end

return RangedWeapon