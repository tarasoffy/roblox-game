local InventoryItemUtils = {}

function InventoryItemUtils.IsPickableId(id: any, config): (boolean, string?)
	if typeof(id) ~= "string" or id == "" then
		return false, nil
	end

	if not config.PrefabById[id] then
		return false, nil
	end

	return true, id
end

function InventoryItemUtils.GetCharacterRoot(player: Player): BasePart?
	local char = player.Character
	if not char then return nil end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end

	return nil
end

function InventoryItemUtils.GetWorldPos(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position
	end

	if inst:IsA("Model") then
		local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position
		end
	end

	return nil
end

function InventoryItemUtils.ResolvePickableTarget(inst: Instance, config): (Instance?, string?)
	if not inst or not inst.Parent then
		return nil, nil
	end

	local current: Instance? = inst

	while current and current ~= workspace do
		local ok, id = InventoryItemUtils.IsPickableId(current:GetAttribute("PickupId"), config)

		if ok and id then
			return current, id
		end

		current = current.Parent
	end

	return nil, nil
end

function InventoryItemUtils.SetupDropPhysics(inst: Instance)
	for _, descendant in ipairs(inst:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
			descendant.CanQuery = true
			descendant.CanTouch = true
			descendant.Massless = false
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

function InventoryItemUtils.PlaceInstanceAt(inst: Instance, cf: CFrame)
	if inst:IsA("Model") then
		if not inst.PrimaryPart then
			local anyPart = inst:FindFirstChildWhichIsA("BasePart", true)
			if anyPart then
				inst.PrimaryPart = anyPart
			end
		end

		if inst.PrimaryPart then
			inst:PivotTo(cf)
		end

		return
	end

	if inst:IsA("BasePart") then
		inst.CFrame = cf
	end
end

function InventoryItemUtils.ApplyCookedVisual(inst: Instance, config)
	for _, descendant in ipairs(inst:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("Cookable") == true then
			descendant.Color = config.CookColor
		end
	end
end

function InventoryItemUtils.ReadCookedState(realTarget: Instance, id: string, config): boolean?
	if not config.SaveCookedFor[id] then
		return nil
	end

	local model = realTarget:IsA("Model") and realTarget or realTarget:FindFirstAncestorOfClass("Model")
	if model then
		return model:GetAttribute("Cooked") == true
	end

	return realTarget:GetAttribute("Cooked") == true
end

return InventoryItemUtils