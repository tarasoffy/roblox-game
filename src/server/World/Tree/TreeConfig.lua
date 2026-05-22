-- TreeConfig
-- Shared config for tree chopping and tree drops.

local TreeConfig = {
	DefaultHits = 5,
	HitDistance = 12,
	ChopCooldown = 0.25,

	LogPrefabPath = {"Prefabs", "Log"},
	LogPickupId = "Log",
	LogDropCount = 3,
	LogDropLifetime = 200,

	LogSpawnRadius = 6,
	LogSpawnHeight = 6,

	LogLinearVelocityMin = -10,
	LogLinearVelocityMax = 10,
	LogLinearVelocityYMin = 14,
	LogLinearVelocityYMax = 22,

	LogAngularVelocityMin = -8,
	LogAngularVelocityMax = 8,

	TreeAttributes = {
		"IsTree",
		"is3",
	},
}

return TreeConfig