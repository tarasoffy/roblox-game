local InventoryStorage = {}

export type StackItem = {
	id: string,
	cooked: boolean?,
}

type Stack = {StackItem}

local stacks: {[Player]: Stack} = {}
local lastTime: {[Player]: number} = {}

function InventoryStorage.InitPlayer(player: Player)
	stacks[player] = {}
	lastTime[player] = 0
end

function InventoryStorage.ClearPlayer(player: Player)
	stacks[player] = nil
	lastTime[player] = nil
end

function InventoryStorage.GetStack(player: Player): Stack
	local stack = stacks[player]

	if not stack then
		stack = {}
		stacks[player] = stack
	end

	return stack
end

function InventoryStorage.CanAct(player: Player, cooldown: number): boolean
	local now = os.clock()
	local last = lastTime[player] or 0

	if now - last < cooldown then
		return false
	end

	lastTime[player] = now
	return true
end

function InventoryStorage.GetItemIds(player: Player): {string}
	local stack = stacks[player] or {}
	local ids = table.create(#stack)

	for i, item in ipairs(stack) do
		ids[i] = item.id
	end

	return ids
end

function InventoryStorage.PushItem(player: Player, item: StackItem)
	local stack = InventoryStorage.GetStack(player)
	table.insert(stack, item)
end

function InventoryStorage.PopItem(player: Player): StackItem?
	local stack = InventoryStorage.GetStack(player)

	if #stack == 0 then
		return nil
	end

	local item = stack[#stack]
	stack[#stack] = nil

	return item
end

function InventoryStorage.GetCount(player: Player): number
	local stack = stacks[player]
	return stack and #stack or 0
end

return InventoryStorage