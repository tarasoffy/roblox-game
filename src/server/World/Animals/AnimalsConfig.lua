-- AnimalsConfig
-- Shared config for animal damage, drops, and pooling.

local AnimalsConfig = {
	DropLifetime = 200,

	MeatPrefabPath = {"Prefabs", "Meat"},
	MeatPickupId = "Meat",

	MeatDropByAnimal = {
		wolf = 2,
		bear = 3,
		deer = 3,
	},

	DefaultMeatDrop = 2,

	PoolFolderName = "__AnimalPool",
	MaxPool = 50,

	GroundRayHeight = 20,
	GroundRayDepth = 300,
	GroundDropYOffset = 1.5,
	FallbackDropHeight = 6,

	MeatDropOffsetMultiplier = 0.1,
	MeatDropOffsetMin = -12,
	MeatDropOffsetMax = 12,

	HealthBarName = "HealthBar",
}

return AnimalsConfig