-- AnimalsService
-- Public API for animal detection and damage.

local Players = game:GetService("Players")

local AnimalsConfig = require(script.Parent:WaitForChild("AnimalsConfig"))
local AnimalDrops = require(script.Parent:WaitForChild("AnimalDrops"))
local AnimalHealthBar = require(script.Parent:WaitForChild("AnimalHealthBar"))
local AnimalPool = require(script.Parent:WaitForChild("AnimalPool"))

local AnimalsService = {}

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

function AnimalsService.ApplyDamage(animal: Model, damage: number, hitPosition: Vector3?)
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

	if not animal:FindFirstChild(AnimalsConfig.HealthBarName) then
		AnimalHealthBar.Attach(animal, AnimalsConfig)
	end

	humanoid:TakeDamage(damage)

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