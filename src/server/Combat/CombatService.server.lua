-- ServerScriptService/CombatService.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CONFIG = require(script.Parent:WaitForChild("WeaponConfig"))
local CombatCooldowns = require(script.Parent:WaitForChild("CombatCooldowns"))
local CombatHelpers = require(script.Parent:WaitForChild("CombatHelpers"))
local MeleeWeapon = require(script.Parent:WaitForChild("MeleeWeapon"))
local BulletWeapon = require(script.Parent:WaitForChild("BulletWeapon"))
local ShotgunWeapon = require(script.Parent:WaitForChild("ShotgunWeapon"))
local BowWeapon = require(script.Parent:WaitForChild("BowWeapon"))
local CombatRemotes = require(script.Parent:WaitForChild("CombatRemotes"))
local RangedWeapon = require(script.Parent:WaitForChild("RangedWeapon"))


local ServerScriptService = game:GetService("ServerScriptService")

local AnimalsService = require(
	ServerScriptService
		:WaitForChild("World")
		:WaitForChild("Animals")
		:WaitForChild("AnimalsService")
)

-------------------------------------------------
-- REMOTES
-------------------------------------------------
local combatRemotes = CombatRemotes.Get()
local weaponAction = combatRemotes.WeaponAction
local bulletFX = combatRemotes.BulletFX

-------------------------------------------------
-- STATE
-------------------------------------------------
local bulletIdCounter = 0
local RNG = Random.new()
local bowChargeStartedAt: {[Player]: number} = {}

local function nextProjectileId(): number
	bulletIdCounter += 1
	return bulletIdCounter
end


weaponAction.OnServerEvent:Connect(function(player: Player, action: string, data: any)
	print("[CombatDebug] server action received", "player=", player.Name, "action=", action)

	local char = CombatHelpers.GetCharacter(player)
	if not char then return end

	if action == "ChargeCancel" then
		bowChargeStartedAt[player] = nil
		return
	end

	local tool = CombatHelpers.GetEquippedTool(char)
	if not tool then return end
	print("[CombatDebug] server equipped tool", "player=", player.Name, "toolName=", tool.Name)

	if action == "ChargeStart" then
		if tool.Name == "Bow" then
			bowChargeStartedAt[player] = os.clock()
		end

		return
	end

	if action == "Shoot" then
		local cfg = CONFIG[tool.Name]
		print("[CombatDebug] server weapon config", "toolName=", tool.Name, "hasConfig=", cfg ~= nil)

		local shotHandled = RangedWeapon.Handle(player, tool, data, cfg, {
			weaponAction = weaponAction,
			bulletFX = bulletFX,

			CombatCooldowns = CombatCooldowns,
			CombatHelpers = CombatHelpers,

			AnimalsService = AnimalsService,

			BulletWeapon = BulletWeapon,
			ShotgunWeapon = ShotgunWeapon,
			BowWeapon = BowWeapon,

			NextProjectileId = nextProjectileId,
			RNG = RNG,
			BowChargeStartedAt = bowChargeStartedAt[player],
		})

		if tool.Name == "Bow" and shotHandled then
			bowChargeStartedAt[player] = nil
		end

		return
	end

	if action == "Melee" then
		local cfg = CONFIG[tool.Name]

		MeleeWeapon.Handle(player, tool, cfg, {
			CombatHelpers = CombatHelpers,
			CombatCooldowns = CombatCooldowns,
			AnimalsService = AnimalsService,
		})

		return
	end
end)

Players.PlayerRemoving:Connect(function(player)
	CombatCooldowns.ClearPlayer(player)
	MeleeWeapon.ClearPlayer(player)
	bowChargeStartedAt[player] = nil
end)
