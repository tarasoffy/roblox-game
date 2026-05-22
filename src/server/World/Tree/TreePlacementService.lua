-- TreePlacementService
-- Handles tree placement, ground snapping, model root placement, and part placement.

local Workspace = game:GetService("Workspace")

local TreePlacementService = {}

function TreePlacementService.SnapPositionToGround(position: Vector3, blacklist: {Instance}, config): Vector3
	if not config.SnapToGround then
		return position
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = blacklist or {}

	local origin = position + Vector3.new(0, config.GroundRayUp, 0)
	local direction = Vector3.new(0, -(config.GroundRayUp + config.GroundRayDown), 0)

	local hit = Workspace:Raycast(origin, direction, raycastParams)

	if hit then
		return Vector3.new(position.X, hit.Position.Y + config.HeightOffset, position.Z)
	end

	return position
end

function TreePlacementService.GetModelRoot(model: Model): BasePart?
	local root = model:FindFirstChild("Root")

	if root and root:IsA("BasePart") then
		return root
	end

	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

function TreePlacementService.PlaceModelByRootOnGround(
	model: Model,
	targetPosition: Vector3,
	yawRadians: number,
	blacklist: {Instance},
	config
)
	local root = TreePlacementService.GetModelRoot(model)

	if not root then
		model:PivotTo(CFrame.new(targetPosition) * CFrame.Angles(0, yawRadians, 0))
		return
	end

	local groundPosition = TreePlacementService.SnapPositionToGround(targetPosition, blacklist, config)

	-- First place the model above the ground to avoid raycast/self-placement issues.
	local baseCFrame = CFrame.new(groundPosition + Vector3.new(0, 50, 0)) * CFrame.Angles(0, yawRadians, 0)
	model:PivotTo(baseCFrame)

	-- Then move the whole model so Root.Y is exactly on ground Y.
	local deltaY = groundPosition.Y - root.Position.Y
	model:PivotTo(baseCFrame + Vector3.new(0, deltaY, 0))
end

function TreePlacementService.PlacePartOnGround(
	part: BasePart,
	targetPosition: Vector3,
	yawRadians: number,
	blacklist: {Instance},
	config
)
	local groundPosition = TreePlacementService.SnapPositionToGround(targetPosition, blacklist, config)

	local centerPosition = Vector3.new(
		groundPosition.X,
		groundPosition.Y + part.Size.Y * 0.5,
		groundPosition.Z
	)

	part.CFrame = CFrame.new(centerPosition) * CFrame.Angles(0, yawRadians, 0)
end

function TreePlacementService.PlaceTree(
	tree: Instance,
	targetPosition: Vector3,
	yawRadians: number,
	blacklist: {Instance},
	config
)
	if tree:IsA("Model") then
		TreePlacementService.PlaceModelByRootOnGround(tree, targetPosition, yawRadians, blacklist, config)
	elseif tree:IsA("BasePart") then
		TreePlacementService.PlacePartOnGround(tree, targetPosition, yawRadians, blacklist, config)
	end
end

return TreePlacementService