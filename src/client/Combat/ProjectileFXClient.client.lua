-- StarterPlayerScripts/BulletFX.client.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProjectileFX = script.Parent:WaitForChild("ProjectileFX")
local BulletProjectileFX = require(ProjectileFX:WaitForChild("BulletProjectileFX"))
local ArrowProjectileFX = require(ProjectileFX:WaitForChild("ArrowProjectileFX"))

local bulletFX = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BulletFX")

local function ensureFXFolder()
	local f = workspace:FindFirstChild("FX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "FX"
		f.Parent = workspace
	end
	return f
end

local FX = ensureFXFolder()
BulletProjectileFX.Init(FX)
ArrowProjectileFX.Init(FX)

bulletFX.OnClientEvent:Connect(function(kind: string, payload)
	if kind == "Start" then
		BulletProjectileFX.Start(payload)
		return
	end

	if kind == "Stop" then
		if not BulletProjectileFX.Stop(payload) then
			ArrowProjectileFX.Stop(payload)
		end
		return
	end

	if kind == "ArrowStart" then
		ArrowProjectileFX.Start(payload)
		return
	end

	if kind == "ArrowStop" then
		ArrowProjectileFX.Stop(payload)
		return
	end
end)

RunService.RenderStepped:Connect(function(dt)
	BulletProjectileFX.Update(dt)
	ArrowProjectileFX.Update(dt)
end)
