local Debris = game:GetService("Debris")

local CombatHelpers = {}

function CombatHelpers.GetCharacter(player: Player): Model?
	local char = player.Character
	if not char then return nil end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end

	return char
end

function CombatHelpers.GetEquippedTool(character: Model): Tool?
	return character:FindFirstChildOfClass("Tool")
end

function CombatHelpers.GetMuzzleWorldPos(tool: Tool, character: Model): Vector3
	local handle = tool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		local muzzle = handle:FindFirstChild("Muzzle")
		if muzzle and muzzle:IsA("Attachment") then
			return muzzle.WorldPosition
		end

		return handle.Position
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp.Position + Vector3.new(0, 1.5, 0)
	end

	return character:GetPivot().Position
end

function CombatHelpers.PlayGunShot(tool: Tool)
	local sounds = tool:FindFirstChild("Sounds")
	if not sounds or not sounds:IsA("Folder") then return end

	local shoot = sounds:FindFirstChild("Shoot")
	if not shoot or not shoot:IsA("Sound") then return end

	local handle = tool:FindFirstChild("Handle")
	local parent = (handle and handle:IsA("BasePart")) and handle or tool

	local s = shoot:Clone()
	s.Parent = parent
	s:Play()

	Debris:AddItem(s, 4)
end

function CombatHelpers.MakeRayParams(excludeChar: Model): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { excludeChar }
	params.IgnoreWater = true

	return params
end

return CombatHelpers