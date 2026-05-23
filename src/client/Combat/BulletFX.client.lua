-- StarterPlayerScripts/BulletFX.client.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local bulletFX = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BulletFX")

-- обычные пули
local bullets = {} :: {[number]: {
	part: Part,
	pos: Vector3,
	dir: Vector3,
	speed: number,
	remain: number,
}}

-- стрелы (дуга) — ТОЛЬКО Trail, без головы
local arrows = {} :: {[number]: {
	mover: Part,
	att0: Attachment,
	att1: Attachment,
	trail: Trail,
	pos: Vector3,
	vel: Vector3,
	gravity: number,
	remain: number,
	finished: boolean,
}}

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

-------------------------------------------------
-- BULLETS (НЕ ТРОГАЕМ)
-------------------------------------------------
local function makeBulletPart(origin: Vector3): Part
	local p = Instance.new("Part")
	p.Name = "Bullet"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = Vector3.new(0.3, 0.3, 0.3)
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.CFrame = CFrame.new(origin)
	p.Parent = FX
	return p
end

-------------------------------------------------
-- ARROW FX (ТОЛЬКО TRAIL)
-------------------------------------------------
local function makeArrowFX(origin: Vector3)
	-- mover: невидимая “плашка”, которая просто несёт attachment'ы
	local mover = Instance.new("Part")
	mover.Name = "ArrowMover"
	mover.Anchored = true
	mover.CanCollide = false
	mover.CanQuery = false
	mover.CanTouch = false
	mover.Transparency = 1
	mover.Size = Vector3.new(0.05, 0.05, 0.05)
	mover.CFrame = CFrame.new(origin)
	mover.Parent = FX

	-- ДВА attachment'а = ровная линия “снаряда”
	-- att1 впереди (голова), att0 сзади (хвост)
	local att0 = Instance.new("Attachment")
	att0.Name = "TrailTail"
	att0.Position = Vector3.new(0, 0, -0.9) -- хвост снаряда (длина линии)
	att0.Parent = mover

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailHead"
	att1.Position = Vector3.new(0, 0, 0.15) -- чуть впереди, чтобы “нос” был заметен
	att1.Parent = mover

	local trail = Instance.new("Trail")
	trail.Name = "ArrowTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.FaceCamera = true
	trail.LightInfluence = 0
	trail.Enabled = true

	-- Длина “воздушного” шлейфа (чем больше, тем длиннее хвост)
	trail.Lifetime = 0.325
	trail.MinLength = 0.01

	-- Белый цвет
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1))

	-- Толщина: хвост тоньше, “нос” чуть толще
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.04), -- хвост
		NumberSequenceKeypoint.new(1.0, 0.13), -- нос
	})

	-- Прозрачность: хвост исчезает, нос яркий
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1.0),   -- хвост исчез
		NumberSequenceKeypoint.new(0.6, 0.55),  -- середина
		NumberSequenceKeypoint.new(1.0, 0.05),  -- нос
	})

	trail.Parent = mover

	return mover, att0, att1, trail
end

local function cleanupArrow(id: number, finalPos: Vector3?)
	local a = arrows[id]
	if not a then return end

	if finalPos then
		a.pos = finalPos
		a.mover.CFrame = CFrame.new(finalPos)
	end

	a.finished = true
	a.trail.Enabled = false

	-- даём “дотлеть” хвосту
	local ttl = (a.trail.Lifetime or 0.4) + 0.2
	Debris:AddItem(a.mover, ttl)

	arrows[id] = nil
end

-------------------------------------------------
-- EVENTS
-------------------------------------------------
bulletFX.OnClientEvent:Connect(function(kind: string, payload)
	-- обычные пули
	if kind == "Start" then
		local id = payload.id
		local origin = payload.origin
		local dir = payload.dir
		local speed = payload.speed
		local range = payload.range

		local part = makeBulletPart(origin)

		bullets[id] = {
			part = part,
			pos = origin,
			dir = dir,
			speed = speed,
			remain = range,
		}

		Debris:AddItem(part, 3)
		return
	end

	if kind == "Stop" then
		local id = payload.id
		local finalPos = payload.finalPos

		local b = bullets[id]
		if b then
			b.part.CFrame = CFrame.new(finalPos)
			b.part:Destroy()
			bullets[id] = nil
			return
		end

		-- если по id оказалась стрела
		if arrows[id] then
			cleanupArrow(id, finalPos)
		end
		return
	end

	-- стрелы
	if kind == "ArrowStart" then
		local id = payload.id
		local origin = payload.origin
		local dir = payload.dir
		local speed = payload.speed
		local range = payload.range
		local gravity = payload.gravity or 75

		local mover, att0, att1, trail = makeArrowFX(origin)

		arrows[id] = {
			mover = mover,
			att0 = att0,
			att1 = att1,
			trail = trail,
			pos = origin,
			vel = dir.Unit * speed,
			gravity = gravity,
			remain = range,
			finished = false,
		}

		Debris:AddItem(mover, 8)
		return
	end

	if kind == "ArrowStop" then
		local id = payload.id
		local finalPos = payload.finalPos
		cleanupArrow(id, finalPos)
		return
	end
end)

-------------------------------------------------
-- UPDATE LOOP
-------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	-- пули
	for id, b in pairs(bullets) do
		local step = b.speed * dt
		if step > b.remain then step = b.remain end

		b.pos = b.pos + (b.dir * step)
		b.remain -= step
		b.part.CFrame = CFrame.new(b.pos)

		if b.remain <= 0 then
			b.part:Destroy()
			bullets[id] = nil
		end
	end

	-- стрелы (дуга)
	for id, a in pairs(arrows) do
		if a.finished then
			continue
		end

		-- гравитация
		a.vel = a.vel + Vector3.new(0, -a.gravity, 0) * dt

		local stepVec = a.vel * dt
		local stepDist = stepVec.Magnitude

		if stepDist > a.remain then
			if stepDist > 0.0001 then
				stepVec = stepVec.Unit * a.remain
				stepDist = a.remain
			else
				stepVec = Vector3.zero
				stepDist = 0
			end
		end

		a.pos = a.pos + stepVec
		a.remain -= stepDist

		-- ориентация по скорости, чтобы линия была ровная и “смотрела” по полёту
		local v = a.vel
		local lookDir = (v.Magnitude > 0.001) and v.Unit or Vector3.new(0, 0, -1)
		a.mover.CFrame = CFrame.lookAt(a.pos, a.pos + lookDir)

		if a.remain <= 0 then
			cleanupArrow(id, a.pos)
		end
	end
end)
