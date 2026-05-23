local Debris = game:GetService("Debris")

local BulletProjectileFX = {}

local FX: Folder

local bullets = {} :: {[number]: {
	part: Part,
	pos: Vector3,
	dir: Vector3,
	speed: number,
	remain: number,
}}

function BulletProjectileFX.Init(fxFolder: Folder)
	FX = fxFolder
end

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

function BulletProjectileFX.Start(payload)
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
end

function BulletProjectileFX.Stop(payload): boolean
	local id = payload.id
	local finalPos = payload.finalPos

	local b = bullets[id]
	if not b then
		return false
	end

	b.part.CFrame = CFrame.new(finalPos)
	b.part:Destroy()
	bullets[id] = nil
	return true
end

function BulletProjectileFX.Update(dt: number)
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
end

return BulletProjectileFX
