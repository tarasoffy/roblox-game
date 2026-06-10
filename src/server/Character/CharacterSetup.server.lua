local Players = game:GetService("Players")

local function configureHumanoid(humanoid: Humanoid)
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
end

local function bindPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		local hum = character:WaitForChild("Humanoid")
		if hum and hum:IsA("Humanoid") then
			configureHumanoid(hum)
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)
