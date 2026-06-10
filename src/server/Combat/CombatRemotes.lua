local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatRemotes = {}

local function ensureFolder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)

	if folder and folder:IsA("Folder") then
		return folder
	end

	if folder then
		folder:Destroy()
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = name
	newFolder.Parent = parent

	return newFolder
end

local function ensureRemoteEvent(parent: Instance, name: string): RemoteEvent
	local remote = parent:FindFirstChild(name)

	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	if remote then
		remote:Destroy()
	end

	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = name
	newRemote.Parent = parent

	return newRemote
end

function CombatRemotes.Get()
	local remotesFolder = ensureFolder(ReplicatedStorage, "Remotes")

	return {
		WeaponAction = ensureRemoteEvent(remotesFolder, "WeaponAction"),
		BulletFX = ensureRemoteEvent(remotesFolder, "BulletFX"),
		AnimalAttack = ensureRemoteEvent(remotesFolder, "AnimalAttack"),
		ShowTargetHealthBar = ensureRemoteEvent(remotesFolder, "ShowTargetHealthBar"),
	}
end

return CombatRemotes
