-- TreeUtils
-- Helpers for finding and validating trees during chopping.

local TreeUtils = {}

function TreeUtils.GetTreeModelFromPart(part: Instance, treeAttributes: {string}): Model?
	local current: Instance? = part

	while current do
		if current:IsA("Model") then
			for _, attributeName in ipairs(treeAttributes) do
				if current:GetAttribute(attributeName) == true then
					return current
				end
			end
		end

		current = current.Parent
	end

	return nil
end

function TreeUtils.GetClosestPartInModelToPoint(model: Model, point: Vector3): (BasePart?, number)
	local closestPart: BasePart? = nil
	local closestDistance = math.huge

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local distance = (descendant.Position - point).Magnitude

			if distance < closestDistance then
				closestDistance = distance
				closestPart = descendant
			end
		end
	end

	return closestPart, closestDistance
end

function TreeUtils.HasLineOfSight(character: Model, fromPosition: Vector3, treeModel: Model, toPosition: Vector3): boolean
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {character}

	local origin = fromPosition + Vector3.new(0, 2, 0)
	local direction = toPosition - origin

	if direction.Magnitude < 0.1 then
		return true
	end

	local result = workspace:Raycast(origin, direction, raycastParams)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(treeModel)
end

function TreeUtils.FindClosestTree(character: Model, originPosition: Vector3, hitDistance: number, treeAttributes: {string}): (Model?, BasePart?)
	local parts = workspace:GetPartBoundsInRadius(originPosition, hitDistance)

	local bestTree: Model? = nil
	local bestTreePart: BasePart? = nil
	local bestDistance = math.huge

	for _, part in ipairs(parts) do
		if not part:IsA("BasePart") then
			continue
		end

		if part:IsDescendantOf(character) then
			continue
		end

		local treeModel = TreeUtils.GetTreeModelFromPart(part, treeAttributes)

		if not treeModel then
			continue
		end

		local closestPart, distance = TreeUtils.GetClosestPartInModelToPoint(treeModel, originPosition)

		if not closestPart then
			continue
		end

		if distance > hitDistance then
			continue
		end

		if not TreeUtils.HasLineOfSight(character, originPosition, treeModel, closestPart.Position) then
			continue
		end

		if distance < bestDistance then
			bestDistance = distance
			bestTree = treeModel
			bestTreePart = closestPart
		end
	end

	return bestTree, bestTreePart
end

return TreeUtils