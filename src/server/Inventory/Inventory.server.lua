-- Inventory.server.lua
-- Server inventory entry point.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryConfig = require(script.Parent:WaitForChild("InventoryConfig"))
local InventoryStorage = require(script.Parent:WaitForChild("InventoryStorage"))
local InventoryItemUtils = require(script.Parent:WaitForChild("InventoryItemUtils"))
local InventoryActions = require(script.Parent:WaitForChild("InventoryActions"))

-------------------------------------------------
-- RemoteEvent
-------------------------------------------------
local invEvent = ReplicatedStorage:FindFirstChild("InventoryEvent")
if not invEvent then
	invEvent = Instance.new("RemoteEvent")
	invEvent.Name = "InventoryEvent"
	invEvent.Parent = ReplicatedStorage
end

-------------------------------------------------
-- Dependencies
-------------------------------------------------
local actionDependencies = {
	InventoryConfig = InventoryConfig,
	InventoryStorage = InventoryStorage,
	InventoryItemUtils = InventoryItemUtils,
	invEvent = invEvent,
}

-------------------------------------------------
-- Lifecycle
-------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	InventoryStorage.InitPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	InventoryStorage.ClearPlayer(player)
end)

-------------------------------------------------
-- Remote handling
-------------------------------------------------
invEvent.OnServerEvent:Connect(function(player, action: string, target: Instance?)
	if not InventoryStorage.CanAct(player, InventoryConfig.ActionCooldown) then
		return
	end

	if action == "pickup" then
		if target then
			InventoryActions.Pickup(player, target, actionDependencies)
		end

		return
	end

	if action == "drop" then
		InventoryActions.DropLast(player, actionDependencies)
	end
end)