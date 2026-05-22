-- TreeRemotes
-- Ensures tree-related RemoteEvents exist in ReplicatedStorage/Remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TreeRemotes = {}

local REMOTES_FOLDER_NAME = "Remotes"
local CHOP_TREE_EVENT_NAME = "ChopTree"
local TREE_HIT_FEEDBACK_EVENT_NAME = "TreeHitFeedback"

local function ensureRemoteEvent(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)

	if existing then
		if existing:IsA("RemoteEvent") then
			return existing
		end

		existing:Destroy()
	end

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = name
	remoteEvent.Parent = parent

	return remoteEvent
end

function TreeRemotes.Get()
	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)

	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end

	return {
		ChopTree = ensureRemoteEvent(remotesFolder, CHOP_TREE_EVENT_NAME),
		TreeHitFeedback = ensureRemoteEvent(remotesFolder, TREE_HIT_FEEDBACK_EVENT_NAME),
	}
end

return TreeRemotes