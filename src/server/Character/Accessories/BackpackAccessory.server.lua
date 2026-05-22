local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local BACKPACK_NAME = "BackpackAccessory"

local function giveBackpack(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- не выдаём второй раз
	for _, acc in ipairs(character:GetChildren()) do
		if acc:IsA("Accessory") and acc.Name == BACKPACK_NAME then
			return
		end
	end

	local accTemplate = ServerStorage:FindFirstChild(BACKPACK_NAME)
	if not accTemplate then
		warn("No backpack accessory in ServerStorage:", BACKPACK_NAME)
		return
	end

	local acc = accTemplate:Clone()
	humanoid:AddAccessory(acc)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		giveBackpack(character)
	end)
end)
