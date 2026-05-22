-- InteractHighlight.client.lua (NO CURSOR)
-- Universal highlight for interactables (always on)
-- Highlights ONLY within interaction distance.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui")

local INTERACT_DISTANCE = 10
local RAY_DISTANCE = 200
local MAX_TRIES = 6

local currentTarget: Instance? = nil
local currentHighlight: Highlight? = nil

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

local function getAdornee(target: Instance): Instance?
	if target:IsA("Model") then
		return target
	end
	return target
end

local function clearHighlight()
	if currentHighlight then
		currentHighlight:Destroy()
		currentHighlight = nil
	end
	currentTarget = nil
end

local function setHighlight(target: Instance)
	local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
	if model then
		target = model
	end
	if currentTarget == target then return end

	clearHighlight()
	currentTarget = target

	local adornee = getAdornee(target)
	if not adornee then
		currentTarget = nil
		return
	end

	local hl = Instance.new("Highlight")
	hl.Name = "InteractHighlight"
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = adornee
	hl.Parent = playerGui

	currentHighlight = hl
end

local function getCharacterRoot(): BasePart?
	local char = player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	return nil
end

local function getWorldPos(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position
	end
	if inst:IsA("Model") then
		local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
		if pp then return pp.Position end
	end
	return nil
end

local function raycastFromMouse(ignoreList: {Instance}): RaycastResult?
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = ignoreList
	params.IgnoreWater = true

	return workspace:Raycast(ray.Origin, ray.Direction * RAY_DISTANCE, params)
end

local function getHitInstance(): Instance?
	local ignore = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end

	local tries = 0
	while tries < MAX_TRIES do
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

local function updateHover()
	local hrp = getCharacterRoot()
	if not hrp then
		clearHighlight()
		return
	end

	local hit = getHitInstance()
	local pickable = findPickableUpwards(hit)

	if not pickable then
		clearHighlight()
		return
	end

	local pos = getWorldPos(pickable)
	if not pos then
		clearHighlight()
		return
	end

	if (hrp.Position - pos).Magnitude > INTERACT_DISTANCE then
		clearHighlight()
		return
	end

	setHighlight(pickable)
end

RunService.RenderStepped:Connect(updateHover)
