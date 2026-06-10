-- StaminaController
-- Handles sprint, stamina, and slowed movement state.

local StaminaController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimalConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalConfig"))
local setAnimalSprint = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SetAnimalSprint")

local player: Player? = nil
local config = nil
local getHumanoid = nil
local onChanged = nil

local stamina = 0
local wantRun = false
local isRunning = false
local lastDrainTime = 0
local exhausted = false

-- Temporary for character/spawn testing: keep sprint/HUD behavior, but pause stamina drain.
local TEMP_DISABLE_STAMINA_DRAIN_FOR_SPAWN_TESTING = true

local function notifyChanged()
	if onChanged then
		onChanged()
	end
end

local function isSlowed(): boolean
	if not player then
		return false
	end

	return player:GetAttribute("Starving") == true or player:GetAttribute("Poisoned") == true
end

local function getCharacter(): Model?
	local humanoid = getHumanoid and getHumanoid()
	local character = humanoid and humanoid.Parent

	if character and character:IsA("Model") then
		return character
	end

	return nil
end

local function isAnimalCharacter(): boolean
	local character = getCharacter()
	return character ~= nil and character:GetAttribute("IsAnimalCharacter") == true
end

local function getFearMoveSpeedMultiplier(): number
	if isAnimalCharacter() then
		return 1
	end

	local character = getCharacter()
	local feared = (player ~= nil and player:GetAttribute("Feared") == true)
		or (character ~= nil and character:GetAttribute("Feared") == true)

	if not feared then
		return 1
	end

	local multiplier = character and character:GetAttribute("FearMoveSpeedMultiplier")

	if typeof(multiplier) ~= "number" and player then
		multiplier = player:GetAttribute("FearMoveSpeedMultiplier")
	end

	if typeof(multiplier) ~= "number" then
		multiplier = 0.7
	end

	return math.clamp(multiplier, 0.1, 1)
end

local function getAnimalStats()
	local character = getCharacter()

	if not character or character:GetAttribute("IsAnimalCharacter") ~= true then
		return nil
	end

	local animalType = character:GetAttribute("AnimalType")
	return typeof(animalType) == "string" and AnimalConfig[animalType] or nil
end

local function setSpeed(speed: number)
	if isSlowed() then
		speed = config.SLOW_SPEED
	end

	local humanoid = getHumanoid and getHumanoid()

	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = speed
	end
end

local function getWalkSpeed(): number
	if isAnimalCharacter() then
		local stats = getAnimalStats()

		if stats and typeof(stats.WalkSpeed) == "number" then
			return stats.WalkSpeed
		end
	end

	return config.WALK_SPEED * getFearMoveSpeedMultiplier()
end

local function getRunSpeed(): number
	return config.RUN_SPEED * getFearMoveSpeedMultiplier()
end

local function canRunNow(): boolean
	if exhausted then
		return false
	end

	return stamina >= config.MIN_STAMINA_TO_START
end

function StaminaController.Init(nextPlayer: Player, nextConfig, nextGetHumanoid, nextOnChanged)
	player = nextPlayer
	config = nextConfig
	getHumanoid = nextGetHumanoid
	onChanged = nextOnChanged

	stamina = config.STAMINA_MAX
end

function StaminaController.Reset()
	if isAnimalCharacter() then
		setAnimalSprint:FireServer(false)
	end

	stamina = config.STAMINA_MAX
	wantRun = false
	isRunning = false
	lastDrainTime = 0
	exhausted = false

	setSpeed(getWalkSpeed())
	notifyChanged()
end

function StaminaController.ApplyRunState()
	if isAnimalCharacter() then
		isRunning = wantRun
		setAnimalSprint:FireServer(wantRun)
		notifyChanged()
		return
	end

	if isSlowed() then
		isRunning = false
		setSpeed(getWalkSpeed())
		notifyChanged()
		return
	end

	if wantRun and canRunNow() then
		isRunning = true
		setSpeed(getRunSpeed())
	else
		isRunning = false
		setSpeed(getWalkSpeed())
	end

	notifyChanged()
end

function StaminaController.SetWantRun(nextWantRun: boolean)
	wantRun = nextWantRun

	if not nextWantRun then
		exhausted = false
	end

	StaminaController.ApplyRunState()
end

function StaminaController.Update(deltaTime: number)
	local humanoid = getHumanoid and getHumanoid()

	if not humanoid or not humanoid.Parent then
		notifyChanged()
		return
	end

	if isAnimalCharacter() then
		notifyChanged()
		return
	end

	local moving = humanoid.MoveDirection.Magnitude > 0.05
	local slowed = isSlowed()

	if isRunning and moving and not slowed then
		if not TEMP_DISABLE_STAMINA_DRAIN_FOR_SPAWN_TESTING then
			stamina -= config.DRAIN_PER_SEC * deltaTime
		end

		if stamina <= 0 then
			stamina = 0
			exhausted = true
			StaminaController.ApplyRunState()
		end

		lastDrainTime = 0
	else
		if exhausted and wantRun then
			notifyChanged()
			return
		end

		lastDrainTime += deltaTime

		if lastDrainTime >= config.REGEN_DELAY then
			stamina += config.REGEN_PER_SEC * deltaTime

			if stamina > config.STAMINA_MAX then
				stamina = config.STAMINA_MAX
			end
		end
	end

	notifyChanged()
end

function StaminaController.GetStaminaRatio(): number
	return stamina / config.STAMINA_MAX
end

return StaminaController
