local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local activateAnimalAbility = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ActivateAnimalAbility")

local SLOT_KEYCODES = {
	[Enum.KeyCode.One] = 1,
}

local function isAnimalCharacter(): boolean
	local character = player.Character
	return character ~= nil and character:GetAttribute("IsAnimalCharacter") == true
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	local slot = SLOT_KEYCODES[input.KeyCode]
	if not slot then
		return
	end

	if not isAnimalCharacter() then
		return
	end

	activateAnimalAbility:FireServer(slot)
end)
