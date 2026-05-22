-- TreeService.server.lua
-- Handles tree chopping, hit feedback, tree health, and tree drops.

local Players = game:GetService("Players")

local TreeConfig = require(script.Parent:WaitForChild("TreeConfig"))
local TreeRemotes = require(script.Parent:WaitForChild("TreeRemotes"))
local TreeUtils = require(script.Parent:WaitForChild("TreeUtils"))
local TreeDrops = require(script.Parent:WaitForChild("TreeDrops"))

local treeRemotes = TreeRemotes.Get()
local chopEvent = treeRemotes.ChopTree
local feedbackEvent = treeRemotes.TreeHitFeedback

local lastChopTimeByPlayer: {[Player]: number} = {}

local function canChop(player: Player): boolean
	local now = os.clock()
	local lastChopTime = lastChopTimeByPlayer[player] or 0

	if now - lastChopTime < TreeConfig.ChopCooldown then
		return false
	end

	lastChopTimeByPlayer[player] = now

	return true
end

local function getHumanoidRootPart(character: Model): BasePart?
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	return nil
end

local function getHitsLeft(treeModel: Model): number
	local hitsLeft = treeModel:GetAttribute("HitsLeft")

	if typeof(hitsLeft) == "number" then
		return hitsLeft
	end

	return TreeConfig.DefaultHits
end

local function damageTree(treeModel: Model): number
	local hitsLeft = getHitsLeft(treeModel)
	hitsLeft -= 1

	treeModel:SetAttribute("HitsLeft", hitsLeft)

	return hitsLeft
end

chopEvent.OnServerEvent:Connect(function(player: Player)
	if not canChop(player) then
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local humanoidRootPart = getHumanoidRootPart(character)

	if not humanoidRootPart then
		return
	end

	local treeModel, treePart = TreeUtils.FindClosestTree(
		character,
		humanoidRootPart.Position,
		TreeConfig.HitDistance,
		TreeConfig.TreeAttributes
	)

	if not treeModel or not treePart then
		return
	end

	local hitsLeft = damageTree(treeModel)

	feedbackEvent:FireAllClients(treeModel)

	if hitsLeft <= 0 then
		local dropPosition = treePart.Position

		treeModel:Destroy()
		TreeDrops.SpawnLogs(dropPosition, TreeConfig)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastChopTimeByPlayer[player] = nil
end)