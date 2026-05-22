-- TreeSpawnConfig
-- Configuration for tree spawning.

local TreeSpawnConfig = {
	SpawnFolderPath = {"Spawns", "TreeSpawns"}, -- Workspace/Spawns/TreeSpawns
	OutputFolderName = "Trees",
	TemplatesFolderPath = {"TreeTemplates"}, -- ServerStorage/TreeTemplates

	UseFixedCount = false,
	FixedCount = 120,
	ChancePerPoint = 1, -- 0..1

	SnapToGround = true,
	GroundRayUp = 250,
	GroundRayDown = 1200,
	HeightOffset = 0,

	MinDistance = 10,

	ForceAnchored = true,
	ForceCanCollide = true,
}

return TreeSpawnConfig