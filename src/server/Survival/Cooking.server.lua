-- Cooking.server.lua
-- Готовим ТОЛЬКО: Meat и Mushroom
-- Механика: если предмет с PickupId в списке и касается CookZone -> Cooked=true + перекраска Cookable частей

local Players = game:GetService("Players")

local COOK_COLOR = Color3.fromRGB(120, 72, 35)

-- Разрешаем готовить только эти PickupId
local COOKABLE_IDS: {[string]: boolean} = {
	Meat = true,
	Mushroom = true,
}

local function getModelFromHit(inst: Instance): Model?
	if inst:IsA("Model") then return inst end
	return inst:FindFirstAncestorOfClass("Model")
end

local function getPickupId(inst: Instance): string?
	-- PickupId может быть на модели или на детали
	local model = getModelFromHit(inst)
	if model then
		local id = model:GetAttribute("PickupId")
		if typeof(id) == "string" and id ~= "" then
			return id
		end
	end
	local id2 = inst:GetAttribute("PickupId")
	if typeof(id2) == "string" and id2 ~= "" then
		return id2
	end
	return nil
end

local function setCookedVisual(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		-- красим ТОЛЬКО части с Cookable=true
		if d:IsA("BasePart") and d:GetAttribute("Cookable") == true then
			d.Color = COOK_COLOR
		end
	end
end

local function cookModel(model: Model)
	-- уже приготовлено
	if model:GetAttribute("Cooked") == true then return end
	-- дебаунс, чтобы Touched не дергал 100 раз
	if model:GetAttribute("_Cooking") == true then return end
	model:SetAttribute("_Cooking", true)

	model:SetAttribute("Cooked", true)
	setCookedVisual(model)

	model:SetAttribute("_Cooking", false)
end

local function hookCookZone(zonePart: BasePart)
	zonePart.Touched:Connect(function(hit: BasePart)
		-- игнор игроков
		local char = hit:FindFirstAncestorOfClass("Model")
		if char and Players:GetPlayerFromCharacter(char) then return end

		local id = getPickupId(hit)
		if not id or not COOKABLE_IDS[id] then return end

		local model = getModelFromHit(hit)
		if not model then return end

		cookModel(model)
	end)
end

-- существующие CookZone
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == "CookZone" then
		hookCookZone(d)
	end
end

-- если CookZone появится позже
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") and d.Name == "CookZone" then
		hookCookZone(d)
	end
end)