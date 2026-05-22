-- AnimalCombatAI.server.lua
-- Entry point for server-side animal AI.

local RunService = game:GetService("RunService")

local AnimalsFolder = script.Parent.Parent

local AnimalsService = require(AnimalsFolder:WaitForChild("AnimalsService"))

local AnimalAIConfig = require(script.Parent:WaitForChild("AnimalCombatAIConfig"))
local AnimalAIUtils = require(script.Parent:WaitForChild("AnimalCombatAIUtils"))
local AnimalTargeting = require(script.Parent:WaitForChild("AnimalCombatAITargeting"))
local AnimalMovement = require(script.Parent:WaitForChild("AnimalCombatAIMovement"))
local AnimalCombat = require(script.Parent:WaitForChild("AnimalCombatAI"))

local trackedAnimals: {Model} = {}
local lastAnimalRefreshTime = 0
local lastAttackTimeByAnimal: {[Model]: number} = {}

local function shouldUseAnimalAI(instance: Instance): boolean
	if not AnimalsService.IsAnimalModel(instance) then
		return false
	end

	if instance:GetAttribute(AnimalAIConfig.AggressiveAttribute) ~= true then
		return false
	end

	if instance:GetAttribute("Dead") == true then
		return false
	end

	return true
end

local function refreshTrackedAnimals()
	local animals = {}

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("Model") and shouldUseAnimalAI(instance) then
			table.insert(animals, instance)
		end
	end

	trackedAnimals = animals
end

local function updateAnimal(animal: Model, deltaTime: number)
	if not animal.Parent then
		lastAttackTimeByAnimal[animal] = nil
		return
	end

	if not shouldUseAnimalAI(animal) then
		return
	end

	local animalRoot = AnimalAIUtils.GetAnimalRoot(animal)

	if not animalRoot then
		return
	end

	local settings = AnimalAIConfig.GetSettings(animal)

	local targetRoot, targetHumanoid = AnimalTargeting.GetNearestPlayerTarget(
		animalRoot.Position,
		settings.AggroDistance
	)

	if not targetRoot or not targetHumanoid then
		return
	end

	AnimalMovement.MoveTowards(animal, animalRoot, targetRoot.Position, settings, deltaTime)

	AnimalCombat.TryAttack(
		animal,
		targetRoot,
		targetHumanoid,
		settings,
		lastAttackTimeByAnimal
	)
end

RunService.Heartbeat:Connect(function(deltaTime)
	local now = os.clock()

	if now - lastAnimalRefreshTime >= AnimalAIConfig.AnimalRefreshRate then
		lastAnimalRefreshTime = now
		refreshTrackedAnimals()
	end

	for _, animal in ipairs(trackedAnimals) do
		updateAnimal(animal, deltaTime)
	end
end)