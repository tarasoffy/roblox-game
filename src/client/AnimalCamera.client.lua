local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local function getCurrentCamera(): Camera?
	local camera = Workspace.CurrentCamera
	local startedAt = os.clock()

	while not camera and os.clock() - startedAt < 5 do
		Workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
		camera = Workspace.CurrentCamera
	end

	return camera
end

local function applyCharacterCamera(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid or not humanoid:IsA("Humanoid") then
		warn("[AnimalSpawn] Camera subject not set; Humanoid missing.")
		return
	end

	local camera = getCurrentCamera()
	if not camera then
		warn("[AnimalSpawn] Camera subject not set; CurrentCamera missing.")
		return
	end

	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom
	print("[AnimalSpawn] Camera subject set on client.")
end

if player.Character then
	applyCharacterCamera(player.Character)
end

player.CharacterAdded:Connect(applyCharacterCamera)
