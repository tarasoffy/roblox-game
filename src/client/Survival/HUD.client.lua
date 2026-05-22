-- HUD.client.lua
-- Entry point for Health + Hunger + Stamina HUD.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local HUDConfig = require(script.Parent:WaitForChild("HUDConfig"))
local HUDView = require(script.Parent:WaitForChild("HUDView"))
local HUDDamageVignette = require(script.Parent:WaitForChild("HUDDamageVignette"))
local StaminaController = require(script.Parent:WaitForChild("StaminaController"))

local player = Players.LocalPlayer

local humanoid: Humanoid? = nil
local lastHp: number? = nil

local UI = HUDView.Create(player, HUDConfig)

local function getHumanoid(): Humanoid?
	if humanoid and humanoid.Parent then
		return humanoid
	end

	return nil
end

local function getServerHunger(): (number, number)
	local maxH = player:GetAttribute("HungerMax")

	if typeof(maxH) ~= "number" then
		maxH = 100
	end

	local h = player:GetAttribute("Hunger")

	if typeof(h) ~= "number" then
		h = maxH
	end

	return h, maxH
end

local function getHealth(): (number, number)
	local currentHumanoid = getHumanoid()

	if currentHumanoid then
		return currentHumanoid.Health, currentHumanoid.MaxHealth
	end

	return 0, 100
end

local function updateHUD()
	local hp, hpMax = getHealth()

	if hpMax <= 0 then
		hpMax = 100
	end

	HUDView.SetBar(UI.healthFill, UI.healthBg, hp / hpMax)

	local hungerVal, hungerMax = getServerHunger()

	if hungerMax <= 0 then
		hungerMax = 100
	end

	HUDView.SetBar(UI.hungerFill, UI.hungerBg, hungerVal / hungerMax)
	HUDView.SetBar(UI.staminaFill, UI.staminaBg, StaminaController.GetStaminaRatio())
end

HUDDamageVignette.Init(UI, HUDConfig)
StaminaController.Init(player, HUDConfig, getHumanoid, updateHUD)

player:GetAttributeChangedSignal("Hunger"):Connect(updateHUD)
player:GetAttributeChangedSignal("HungerMax"):Connect(updateHUD)

player:GetAttributeChangedSignal("Starving"):Connect(function()
	StaminaController.ApplyRunState()
end)

player:GetAttributeChangedSignal("Poisoned"):Connect(function()
	StaminaController.ApplyRunState()
end)

local function onCharacter(character: Model)
	humanoid = character:WaitForChild("Humanoid")

	StaminaController.Reset()

	lastHp = humanoid.Health
	HUDDamageVignette.Reset()

	humanoid.HealthChanged:Connect(function(newHp)
		updateHUD()

		if lastHp ~= nil and newHp < lastHp then
			local delta = lastHp - newHp
			local maxHealth = math.max(humanoid.MaxHealth, 1)
			local damageRatio = delta / maxHealth

			HUDDamageVignette.Flash(damageRatio)
		end

		lastHp = newHp
	end)

	updateHUD()
end

if player.Character then
	onCharacter(player.Character)
end

player.CharacterAdded:Connect(onCharacter)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		StaminaController.SetWantRun(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		StaminaController.SetWantRun(false)
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	StaminaController.Update(deltaTime)
end)

updateHUD()