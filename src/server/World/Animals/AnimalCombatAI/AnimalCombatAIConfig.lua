-- AnimalAIConfig
-- Config for animal AI behavior.
-- Per-animal values can be configured by model name.
-- Attributes on a specific animal override these config values.

local AnimalAIConfig = {
	AnimalRefreshRate = 1,

	AggressiveAttribute = "Aggressive",

	AttributeNames = {
		MoveSpeed = "MoveSpeed",
		AggroDistance = "AggroDistance",
		AttackDistance = "AttackDistance",
		AttackDamage = "AttackDamage",
		AttackCooldown = "AttackCooldown",
		YawOffset = "YawOffset",
	},

	Defaults = {
		AggroDistance = 50,
		AttackDistance = 5,
		MoveSpeed = 10,
		AttackDamage = 10,
		AttackCooldown = 1.2,
		YawOffset = 0,
		MinMoveDistance = 0.1,
	},

	-- Default settings by animal model name.
	-- Attribute values on the model override these.
	ByAnimalName = {
		bear = {
			YawOffset = 90,
			MoveSpeed = 10,
			AggroDistance = 50,
			AttackDistance = 7,
			AttackDamage = 10,
			AttackCooldown = 1.2,
		},

		wolf = {
			YawOffset = 0,
			MoveSpeed = 14,
			AggroDistance = 70,
			AttackDistance = 7,
			AttackDamage = 8,
			AttackCooldown = 1,
		},
	},
}

local function getNumberAttribute(instance: Instance, attributeName: string, fallback: number): number
	local value = instance:GetAttribute(attributeName)

	if typeof(value) == "number" then
		return value
	end

	return fallback
end

local function getByNameValue(animal: Model, key: string): number?
	local animalName = string.lower(animal.Name)
	local animalConfig = AnimalAIConfig.ByAnimalName[animalName]

	if not animalConfig then
		return nil
	end

	local value = animalConfig[key]

	if typeof(value) == "number" then
		return value
	end

	return nil
end

local function resolveNumber(animal: Model, key: string, attributeName: string): number
	local defaultValue = AnimalAIConfig.Defaults[key]
	local byNameValue = getByNameValue(animal, key)

	if typeof(byNameValue) == "number" then
		defaultValue = byNameValue
	end

	return getNumberAttribute(animal, attributeName, defaultValue)
end

function AnimalAIConfig.GetSettings(animal: Model)
	local attributeNames = AnimalAIConfig.AttributeNames

	return {
		AggroDistance = resolveNumber(animal, "AggroDistance", attributeNames.AggroDistance),
		AttackDistance = resolveNumber(animal, "AttackDistance", attributeNames.AttackDistance),
		MoveSpeed = resolveNumber(animal, "MoveSpeed", attributeNames.MoveSpeed),
		AttackDamage = resolveNumber(animal, "AttackDamage", attributeNames.AttackDamage),
		AttackCooldown = resolveNumber(animal, "AttackCooldown", attributeNames.AttackCooldown),
		YawOffset = resolveNumber(animal, "YawOffset", attributeNames.YawOffset),
		MinMoveDistance = AnimalAIConfig.Defaults.MinMoveDistance,
	}
end

return AnimalAIConfig