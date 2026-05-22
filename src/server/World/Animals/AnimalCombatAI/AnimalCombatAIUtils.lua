-- AnimalAIUtils
-- Shared helpers for animal AI.

local AnimalAIUtils = {}

function AnimalAIUtils.GetAnimalRoot(animal: Model): BasePart?
	local primaryPart = animal.PrimaryPart

	if primaryPart and primaryPart:IsA("BasePart") then
		return primaryPart
	end

	local root = animal:FindFirstChild("Root")

	if root and root:IsA("BasePart") then
		return root
	end

	local humanoidRootPart = animal:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	return animal:FindFirstChildWhichIsA("BasePart", true)
end

function AnimalAIUtils.GetCharacterRoot(character: Model): BasePart?
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	return nil
end

function AnimalAIUtils.GetCharacterHumanoid(character: Model): Humanoid?
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.Health > 0 then
		return humanoid
	end

	return nil
end

function AnimalAIUtils.GetFlatDirection(
	fromPosition: Vector3,
	toPosition: Vector3,
	minMoveDistance: number
): (Vector3?, number)
	local flatTargetPosition = Vector3.new(toPosition.X, fromPosition.Y, toPosition.Z)
	local direction = flatTargetPosition - fromPosition
	local distance = direction.Magnitude

	if distance < minMoveDistance then
		return nil, distance
	end

	return direction.Unit, distance
end

return AnimalAIUtils