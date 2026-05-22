-- TreeSpawner.server.lua
-- Entry point for spawning trees from ServerStorage templates at predefined spawn points.

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local TreeSpawnConfig = require(script.Parent:WaitForChild("TreeSpawnConfig"))
local TreeSpawnUtils = require(script.Parent:WaitForChild("TreeSpawnUtils"))
local TreePlacementService = require(script.Parent:WaitForChild("TreePlacementService"))

math.randomseed(os.clock() * 1000000)

-------------------------------------------------
-- FOLDERS
-------------------------------------------------
local spawnFolder = TreeSpawnUtils.GetFolder(Workspace, TreeSpawnConfig.SpawnFolderPath)

if not spawnFolder then
	warn("[TreeSpawner] Spawn folder not found: Workspace/" .. table.concat(TreeSpawnConfig.SpawnFolderPath, "/"))
	return
end

local templatesFolder = TreeSpawnUtils.GetFolder(ServerStorage, TreeSpawnConfig.TemplatesFolderPath)

if not templatesFolder then
	warn("[TreeSpawner] Templates folder not found: ServerStorage/" .. table.concat(TreeSpawnConfig.TemplatesFolderPath, "/"))
	return
end

local outputFolder = TreeSpawnUtils.EnsureFolder(Workspace, TreeSpawnConfig.OutputFolderName)

-------------------------------------------------
-- DATA
-------------------------------------------------
local points = TreeSpawnUtils.GetSpawnPoints(spawnFolder)
local templates = TreeSpawnUtils.GetTemplates(templatesFolder)

if #points == 0 then
	warn("[TreeSpawner] No spawn points found in:", spawnFolder:GetFullName())
	return
end

if #templates == 0 then
	warn("[TreeSpawner] No templates found in:", templatesFolder:GetFullName())
	return
end

outputFolder:ClearAllChildren()

local chosenPoints = TreeSpawnUtils.GetChosenPoints(points, TreeSpawnConfig)
local placedPositions = {}
local placedCount = 0

-------------------------------------------------
-- SPAWN
-------------------------------------------------
for _, point in ipairs(chosenPoints) do
	local basePosition = point.Position
	local testPosition = TreePlacementService.SnapPositionToGround(basePosition, {outputFolder}, TreeSpawnConfig)

	if not TreeSpawnUtils.IsFarEnough(testPosition, placedPositions, TreeSpawnConfig.MinDistance) then
		continue
	end

	local template = TreeSpawnUtils.ChooseRandom(templates)

	if not template then
		break
	end

	local tree = template:Clone()
	tree.Name = template.Name .. "_Spawned"
	tree.Parent = outputFolder

	if TreeSpawnConfig.ForceAnchored then
		TreeSpawnUtils.SetAnchoredRecursive(tree, true, TreeSpawnConfig.ForceCanCollide)
	end

	local yaw = math.rad(math.random(0, 359))

	-- Important: blacklist includes the output folder and the spawned tree,
	-- so ground raycasts do not hit already spawned trees or the tree itself.
	local blacklist = {outputFolder, tree}

	TreePlacementService.PlaceTree(tree, basePosition, yaw, blacklist, TreeSpawnConfig)

	table.insert(placedPositions, testPosition)
	placedCount += 1
end

print(("[TreeSpawner] Spawned %d trees"):format(placedCount))