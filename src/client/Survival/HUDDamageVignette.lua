-- HUDDamageVignette
-- Custom damage flash effect for the survival HUD.

local TweenService = game:GetService("TweenService")

local HUDDamageVignette = {}

local ui = nil
local config = nil

local lastFlashAt = 0
local outTween: Tween? = nil
local inTween: Tween? = nil

function HUDDamageVignette.Init(nextUI, nextConfig)
	ui = nextUI
	config = nextConfig
end

function HUDDamageVignette.Reset()
	lastFlashAt = 0

	if inTween then
		inTween:Cancel()
		inTween = nil
	end

	if outTween then
		outTween:Cancel()
		outTween = nil
	end

	if ui and ui.damage then
		ui.damage.BackgroundTransparency = 1
	end
end

function HUDDamageVignette.Flash(damageRatio: number)
	if not ui or not ui.damage or not config then
		return
	end

	local now = os.clock()

	if now - lastFlashAt < config.DAMAGE_MAX_COOLDOWN then
		return
	end

	lastFlashAt = now

	damageRatio = math.clamp(damageRatio, 0, 1)
	local peak = config.DAMAGE_BASE_PEAK + config.DAMAGE_EXTRA_PEAK * damageRatio

	if inTween then
		inTween:Cancel()
	end

	if outTween then
		outTween:Cancel()
	end

	local overlay = ui.damage
	overlay.BackgroundTransparency = 1

	inTween = TweenService:Create(
		overlay,
		TweenInfo.new(config.DAMAGE_FLASH_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 - peak }
	)

	outTween = TweenService:Create(
		overlay,
		TweenInfo.new(config.DAMAGE_FLASH_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)

	inTween:Play()
	inTween.Completed:Once(function()
		if outTween then
			outTween:Play()
		end
	end)
end

return HUDDamageVignette