local ServerStorage = game:GetService("ServerStorage")

local HumanToolService = {}

local HUMAN_TOOLS_FOLDER_NAME = "HumanTools"

local HUMAN_STARTER_TOOLS = {
	"Axe",
	"Backpack",
}

local HUMAN_ONLY_TOOLS = {
	"Axe",
	"Backpack",
	"Bow",
	"Revolver",
	"Shotgun",
	"Rifle",
}

local humanStarterToolSet: {[string]: boolean} = {}
local humanOnlyToolSet: {[string]: boolean} = {}

for _, toolName in ipairs(HUMAN_STARTER_TOOLS) do
	humanStarterToolSet[toolName] = true
end

for _, toolName in ipairs(HUMAN_ONLY_TOOLS) do
	humanOnlyToolSet[toolName] = true
end

local function warnTools(message: string)
	warn("[HumanToolService] " .. message)
end

local function getOrCreateHumanToolsFolder(): Folder?
	local existing = ServerStorage:FindFirstChild(HUMAN_TOOLS_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end

	if existing then
		warnTools("ServerStorage.HumanTools exists but is not a Folder; human starter tools cannot be granted.")
		return nil
	end

	local folder = Instance.new("Folder")
	folder.Name = HUMAN_TOOLS_FOLDER_NAME
	folder.Parent = ServerStorage
	return folder
end

local function getBackpack(player: Player): Backpack?
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		return backpack
	end

	local waited = player:WaitForChild("Backpack", 5)
	if waited and waited:IsA("Backpack") then
		return waited
	end

	return nil
end

local function removeMatchingTools(container: Instance?, toolSet: {[string]: boolean})
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") and toolSet[child.Name] then
			child:Destroy()
		end
	end
end

function HumanToolService.IsHumanCharacter(player: Player): boolean
	local character = player.Character
	return character ~= nil and character:GetAttribute("IsAnimalCharacter") ~= true
end

function HumanToolService.HasTool(player: Player, toolName: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then
		return true
	end

	local character = player.Character
	if character and character:FindFirstChild(toolName) then
		return true
	end

	return false
end

function HumanToolService.ClearHumanTools(player: Player)
	removeMatchingTools(player:FindFirstChildOfClass("Backpack"), humanOnlyToolSet)
	removeMatchingTools(player.Character, humanOnlyToolSet)
end

function HumanToolService.GiveHumanStarterTools(player: Player)
	if not HumanToolService.IsHumanCharacter(player) then
		HumanToolService.ClearHumanTools(player)
		return
	end

	local humanTools = getOrCreateHumanToolsFolder()
	if not humanTools then
		return
	end

	local backpack = getBackpack(player)
	if not backpack then
		warnTools(("Backpack missing for %s; cannot give human starter tools."):format(player.Name))
		return
	end

	removeMatchingTools(backpack, humanStarterToolSet)
	removeMatchingTools(player.Character, humanStarterToolSet)

	for _, toolName in ipairs(HUMAN_STARTER_TOOLS) do
		if not HumanToolService.HasTool(player, toolName) then
			local template = humanTools:FindFirstChild(toolName)
			if template and template:IsA("Tool") then
				local tool = template:Clone()
				tool.Parent = backpack
			else
				warnTools(("ServerStorage.HumanTools.%s missing or not a Tool."):format(toolName))
			end
		end
	end
end

return HumanToolService
