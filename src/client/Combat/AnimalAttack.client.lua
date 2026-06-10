local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local animalAttack = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AnimalAttack")

local function isAnimalCharacter(): boolean
	local character = player.Character
	return character ~= nil and character:GetAttribute("IsAnimalCharacter") == true
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if not isAnimalCharacter() then
		return
	end

	animalAttack:FireServer()
end)
