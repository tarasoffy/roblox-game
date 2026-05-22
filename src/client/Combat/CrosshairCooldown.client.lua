-- StarterPlayerScripts/Combat/CrosshairCooldown.client.lua
-- Server sends: weaponAction:FireClient(player, "Cooldown", { seconds = cfg.cooldown })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Config = require(script.Parent:WaitForChild("CooldownDialConfig"))
local DialView = require(script.Parent:WaitForChild("CooldownDialView"))

local player = Players.LocalPlayer
local weaponAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WeaponAction")
DialView.create(player:WaitForChild("PlayerGui"))

local active = false
local activeMode: "cooldown" | "charge" | nil = nil
local chargeStartT = 0
local chargeDuration = 0
local chargeReady = false
local readyPulseStartT: number? = nil

local cooldowns = {}

local FIREARM_TOOLS = {
	Rifle = true,
	Deagle = true,
	Shotgun = true,
}

local function getEquippedToolName(): string?
	local char = player.Character
	if not char then return nil end

	local tool = char:FindFirstChildOfClass("Tool")
	return tool and tool.Name or nil
end

local function getCooldownKey(toolName: string?): string?
	if not toolName then return nil end

	if FIREARM_TOOLS[toolName] then
		return "Firearm"
	end

	return toolName
end

local function showDial()
	UserInputService.MouseIconEnabled = false
	DialView.setVisible(true)
end

local function hideDial()
	DialView.reset()
	UserInputService.MouseIconEnabled = true
end

local function startCooldown(seconds: number)
	if seconds <= 0 then return end

	local toolName = getEquippedToolName()
	local key = getCooldownKey(toolName)

	if not key then return end

	local existingCooldown = cooldowns[key]

	if existingCooldown then
		local elapsed = os.clock() - existingCooldown.startT
		local remaining = existingCooldown.duration - elapsed

		if remaining > 0 then
			return
		end
	end

	active = true
	activeMode = "cooldown"
	chargeReady = false
	readyPulseStartT = nil

	cooldowns[key] = {
		startT = os.clock(),
		duration = seconds,
	}

	showDial()
	DialView.setAllOn()
end

local function startBowCharge()
	if getEquippedToolName() ~= "Bow" then return end
	if Config.BOW_CHARGE_TIME <= 0 then return end
	if activeMode ~= nil then return end

	active = true
	activeMode = "charge"
	chargeStartT = os.clock()
	chargeDuration = Config.BOW_CHARGE_TIME
	chargeReady = false
	readyPulseStartT = nil

	showDial()
	DialView.setChargeInitial()
end

local function stopBowCharge()
	if activeMode ~= "charge" then return end

	active = false
	activeMode = nil
	chargeReady = false
	readyPulseStartT = nil

	hideDial()
end

local function stopCooldown()
	if activeMode == "charge" then
		stopBowCharge()
		return
	end

	active = false
	activeMode = nil
	hideDial()
end

RunService.RenderStepped:Connect(function()
	local inset = GuiService:GetGuiInset()
	local mousePosition = UserInputService:GetMouseLocation() - inset
	DialView.setPosition(mousePosition)

	if activeMode == "charge" then
		if getEquippedToolName() ~= "Bow" or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			stopBowCharge()
			return
		end

		local progress = math.clamp((os.clock() - chargeStartT) / chargeDuration, 0, 1)
		DialView.setChargeProgress(progress)

		if progress >= 1 and not chargeReady then
			chargeReady = true
			readyPulseStartT = os.clock()
			DialView.setChargeReady()
		end

		if readyPulseStartT then
			local pulseProgress = math.clamp((os.clock() - readyPulseStartT) / Config.READY_PULSE_SECONDS, 0, 1)
			DialView.setScale(1 + math.sin(pulseProgress * math.pi) * 0.25)

			if pulseProgress >= 1 then
				readyPulseStartT = nil
				DialView.setScale(1)
			end
		end

		return
	end

	local toolName = getEquippedToolName()
	local key = getCooldownKey(toolName)

	if not key then
		stopCooldown()
		return
	end

	local cooldown = cooldowns[key]

	if not cooldown then
		stopCooldown()
		return
	end

	local progress = math.clamp((os.clock() - cooldown.startT) / cooldown.duration, 0, 1)

	if progress >= 1 then
		cooldowns[key] = nil
		stopCooldown()
		return
	end

	active = true
	activeMode = "cooldown"
	showDial()
	DialView.setCooldownProgress(progress)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and getEquippedToolName() == "Bow" then
		startBowCharge()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		stopBowCharge()
	end
end)

weaponAction.OnClientEvent:Connect(function(kind: string, payload: any)
	if kind == "Cooldown" and typeof(payload) == "table" and typeof(payload.seconds) == "number" then
		stopBowCharge()
		startCooldown(payload.seconds)
	end
end)

local function bindCharacter(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			local toolName = getEquippedToolName()
			local key = getCooldownKey(toolName)

			if key and cooldowns[key] then
				active = true
				showDial()
			end
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			local toolName = getEquippedToolName()
			local key = getCooldownKey(toolName)

			if not key or not cooldowns[key] then
				stopCooldown()
			end
		end
	end)
end

if player.Character then
	bindCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
	bindCharacter(char)

	if not active then
		UserInputService.MouseIconEnabled = true
	end
end)
