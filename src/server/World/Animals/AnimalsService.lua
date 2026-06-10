-- AnimalsService
-- Public API for animal detection and damage.

local Players = game:GetService("Players")

local AnimalsConfig = require(script.Parent:WaitForChild("AnimalsConfig"))
local AnimalDrops = require(script.Parent:WaitForChild("AnimalDrops"))
local AnimalHealthBar = require(script.Parent:WaitForChild("AnimalHealthBar"))
local AnimalPool = require(script.Parent:WaitForChild("AnimalPool"))

local AnimalsService = {}

local function showTargetHealthBar(attacker: Player?, target: Model, humanoid: Humanoid)
	if not attacker then
		return
	end

	if attacker.Character == target then
		return
	end

	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local showTargetHealthBarRemote = remotes and remotes:FindFirstChild("ShowTargetHealthBar")
	if showTargetHealthBarRemote and showTargetHealthBarRemote:IsA("RemoteEvent") then
		showTargetHealthBarRemote:FireClient(attacker, target, humanoid.Health, humanoid.MaxHealth)
	end
end

local function getAnimalRootPosition(animal: Model, fallbackPosition: Vector3?): Vector3
	local root = animal.PrimaryPart
		or animal:FindFirstChild("HumanoidRootPart")
		or animal:FindFirstChildWhichIsA("BasePart", true)

	if root and root:IsA("BasePart") then
		return fallbackPosition or root.Position
	end

	return fallbackPosition or Vector3.zero
end

function AnimalsService.IsAnimalModel(model: Instance): boolean
	if not model:IsA("Model") then
		return false
	end

	if Players:GetPlayerFromCharacter(model) then
		return false
	end

	return model:FindFirstChildOfClass("Humanoid") ~= nil
end

function AnimalsService.IsDamageableAnimalModel(model: Instance): boolean
	if not model:IsA("Model") then
		return false
	end

	if model:GetAttribute("IsAnimalCharacter") == true then
		return model:FindFirstChildOfClass("Humanoid") ~= nil
	end

	return AnimalsService.IsAnimalModel(model)
end

function AnimalsService.ApplyDamage(animal: Model, damage: number, hitPosition: Vector3?, attacker: Player?)
	local humanoid = animal:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	if animal:GetAttribute("Dead") then
		return
	end

	local targetPlayer = Players:GetPlayerFromCharacter(animal)
	if not attacker and not targetPlayer and not animal:FindFirstChild(AnimalsConfig.HealthBarName) then
		AnimalHealthBar.Attach(animal, AnimalsConfig)
	end

	if targetPlayer then
		humanoid:TakeDamage(damage)
		showTargetHealthBar(attacker, animal, humanoid)
		return
	end

	humanoid:TakeDamage(damage)
	showTargetHealthBar(attacker, animal, humanoid)

	if humanoid.Health > 0 then
		return
	end

	animal:SetAttribute("Dead", true)

	-- Avoid default Humanoid death pipeline.
	humanoid.Health = 1

	local dropPosition = getAnimalRootPosition(animal, hitPosition)
	local dropCount = AnimalDrops.ResolveDropCount(animal, AnimalsConfig)

	AnimalDrops.CreateMeatDrops(dropPosition, dropCount, AnimalsConfig)
	AnimalHealthBar.Remove(animal, AnimalsConfig)

	if animal.Parent then
		AnimalPool.ReturnAnimal(animal, AnimalsConfig)
	end
end

return AnimalsService
