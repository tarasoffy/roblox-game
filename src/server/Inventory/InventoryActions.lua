-- InventoryActions
-- Handles pickup/drop inventory actions.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryActions = {}

local prefabs = ReplicatedStorage:WaitForChild("Prefabs")

local function sendUpdate(player: Player, invEvent: RemoteEvent, InventoryStorage)
	local ids = InventoryStorage.GetItemIds(player)
	invEvent:FireClient(player, "invUpdate", ids)
end

function InventoryActions.Pickup(player: Player, target: Instance, dependencies)
	local InventoryConfig = dependencies.InventoryConfig
	local InventoryStorage = dependencies.InventoryStorage
	local InventoryItemUtils = dependencies.InventoryItemUtils
	local invEvent = dependencies.invEvent

	local realTarget, id = InventoryItemUtils.ResolvePickableTarget(target, InventoryConfig)
	if not realTarget or not id then
		return
	end

	if not realTarget.Parent then
		return
	end

	local hrp = InventoryItemUtils.GetCharacterRoot(player)
	if not hrp then
		return
	end

	local pos = InventoryItemUtils.GetWorldPos(realTarget)
	if not pos then
		return
	end

	if (hrp.Position - pos).Magnitude > InventoryConfig.PickupDistance then
		return
	end

	if InventoryStorage.GetCount(player) >= InventoryConfig.Capacity then
		invEvent:FireClient(player, "invFull", InventoryConfig.Capacity)
		return
	end

	local cooked = InventoryItemUtils.ReadCookedState(realTarget, id, InventoryConfig)

	InventoryStorage.PushItem(player, {
		id = id,
		cooked = cooked,
	})

	realTarget:Destroy()

	sendUpdate(player, invEvent, InventoryStorage)
end

function InventoryActions.DropLast(player: Player, dependencies)
	local InventoryConfig = dependencies.InventoryConfig
	local InventoryStorage = dependencies.InventoryStorage
	local InventoryItemUtils = dependencies.InventoryItemUtils
	local invEvent = dependencies.invEvent

	local hrp = InventoryItemUtils.GetCharacterRoot(player)
	if not hrp then
		return
	end

	local lastItem = InventoryStorage.PopItem(player)
	if not lastItem then
		return
	end

	local lastId = lastItem.id
	local cooked = lastItem.cooked == true

	local prefabName = InventoryConfig.PrefabById[lastId]
	local prefab = prefabName and prefabs:FindFirstChild(prefabName)

	if not prefab then
		warn("[Inventory] Missing prefab:", prefabName, "for id:", lastId)
		sendUpdate(player, invEvent, InventoryStorage)
		return
	end

	local inst = prefab:Clone()
	inst.Parent = workspace
	inst:SetAttribute("PickupId", lastId)

	if InventoryConfig.SaveCookedFor[lastId] then
		inst:SetAttribute("Cooked", cooked)

		if cooked then
			InventoryItemUtils.ApplyCookedVisual(inst, InventoryConfig)
		end
	end

	local forward = hrp.CFrame.LookVector
	local spawnPos = hrp.Position + forward * InventoryConfig.DropDistance + Vector3.new(0, 2, 0)

	InventoryItemUtils.PlaceInstanceAt(inst, CFrame.new(spawnPos))
	InventoryItemUtils.SetupDropPhysics(inst)

	local kick = forward * 12 + Vector3.new(0, 6, 0)
	local primaryPart = inst:IsA("BasePart") and inst or (inst:IsA("Model") and inst.PrimaryPart)

	if primaryPart and primaryPart:IsA("BasePart") then
		primaryPart.AssemblyLinearVelocity = kick
	end

	Debris:AddItem(inst, InventoryConfig.DropLifetime)

	sendUpdate(player, invEvent, InventoryStorage)
end

return InventoryActions