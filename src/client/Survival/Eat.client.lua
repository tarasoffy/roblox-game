-- Eat.client.lua (StarterPlayerScripts)
-- Press E to eat food on ground (works regardless of tool)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local invEvent = ReplicatedStorage:WaitForChild("InventoryEvent")

local KEY = Enum.KeyCode.E
local COOLDOWN = 0.2
local last = 0

local function findPickableUpwards(inst: Instance?): Instance?
	local cur = inst
	while cur and cur ~= workspace do
		local id = cur:GetAttribute("PickupId")
		if typeof(id) == "string" and id ~= "" then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

local function raycastFromMouse(ignoreList: {Instance}): RaycastResult?
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList
	params.IgnoreWater = true

	return workspace:Raycast(ray.Origin, ray.Direction * 250, params)
end

local function getHitInstance(): Instance?
	local ignore = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end

	local tries = 0
	local maxTries = 6

	while tries < maxTries do
		tries += 1
		local res = raycastFromMouse(ignore)
		if not res then return nil end

		local inst = res.Instance
		if not inst then return nil end

		if inst:IsA("Terrain") then
			table.insert(ignore, inst)
			continue
		end

		return inst
	end

	return nil
end

local function tryEat()
	local hit = getHitInstance()
	local pickable = findPickableUpwards(hit)
	if not pickable then return end

	-- Сервер сам проверит дистанцию и что это еда
	invEvent:FireServer("eatWorld", pickable)
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode ~= KEY then return end

	local now = os.clock()
	if now - last < COOLDOWN then return end
	last = now

	tryEat()
end)