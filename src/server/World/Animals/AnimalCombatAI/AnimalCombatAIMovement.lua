-- AnimalMovement
-- Handles animal movement and facing direction.

local AnimalAIUtils = require(script.Parent:WaitForChild("AnimalCombatAIUtils"))

local AnimalMovement = {}

local function pivotAnimalFacingDirection(animal: Model, position: Vector3, direction: Vector3, yawOffsetDegrees: number)
	local yaw = math.atan2(-direction.X, -direction.Z)
	local yawOffset = math.rad(yawOffsetDegrees)

	animal:PivotTo(
		CFrame.new(position)
			* CFrame.Angles(0, yaw + yawOffset, 0)
	)
end

function AnimalMovement.MoveTowards(
	animal: Model,
	animalRoot: BasePart,
	targetPosition: Vector3,
	settings,
	deltaTime: number
)
	local currentRootPosition = animalRoot.Position
	local direction, distance = AnimalAIUtils.GetFlatDirection(
		currentRootPosition,
		targetPosition,
		settings.MinMoveDistance
	)

	if not direction then
		return
	end

	if distance <= settings.AttackDistance then
		pivotAnimalFacingDirection(animal, animal:GetPivot().Position, direction, settings.YawOffset)
		return
	end

	local moveAmount = math.min(settings.MoveSpeed * deltaTime, distance - settings.AttackDistance)

	local rootNewPosition = currentRootPosition + direction * moveAmount
	local pivot = animal:GetPivot()
	local pivotDelta = rootNewPosition - currentRootPosition
	local newPivotPosition = pivot.Position + pivotDelta

	pivotAnimalFacingDirection(animal, newPivotPosition, direction, settings.YawOffset)
end

return AnimalMovement