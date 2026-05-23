local Debris = game:GetService("Debris")

local ArrowProjectileFX = {}

local FX: Folder

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

function ArrowProjectileFX.Init(fxFolder: Folder)
	FX = fxFolder
end

local function makeArrowFX(origin: Vector3)
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

	local att0 = Instance.new("Attachment")
	att0.Name = "TrailTail"
	att0.Position = Vector3.new(0, 0, -0.9)
	att0.Parent = mover

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailHead"
	att1.Position = Vector3.new(0, 0, 0.15)
	att1.Parent = mover

	local trail = Instance.new("Trail")
	trail.Name = "ArrowTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.FaceCamera = true
	trail.LightInfluence = 0
	trail.Enabled = true
	trail.Lifetime = 0.1625
	trail.MinLength = 0.01
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.04),
		NumberSequenceKeypoint.new(1.0, 0.13),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1.0),
		NumberSequenceKeypoint.new(0.6, 0.55),
		NumberSequenceKeypoint.new(1.0, 0.05),
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

	local ttl = (a.trail.Lifetime or 0.4) + 0.2
	Debris:AddItem(a.mover, ttl)

	arrows[id] = nil
end

function ArrowProjectileFX.Start(payload)
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
end

function ArrowProjectileFX.Stop(payload)
	local id = payload.id
	local finalPos = payload.finalPos
	cleanupArrow(id, finalPos)
end

function ArrowProjectileFX.Update(dt: number)
	for id, a in pairs(arrows) do
		if a.finished then
			continue
		end

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

		local v = a.vel
		local lookDir = (v.Magnitude > 0.001) and v.Unit or Vector3.new(0, 0, -1)
		a.mover.CFrame = CFrame.lookAt(a.pos, a.pos + lookDir)

		if a.remain <= 0 then
			cleanupArrow(id, a.pos)
		end
	end
end

return ArrowProjectileFX
