local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hum = character:WaitForChild("Humanoid")
		hum.BreakJointsOnDeath = false
	end)
end)