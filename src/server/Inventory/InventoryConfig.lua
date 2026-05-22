local InventoryConfig = {}

InventoryConfig.PrefabById = {
	Log = "Log",
	Meat = "Meat",
	Mushroom = "Mushroom",
	Mushroom_Trampoline = "Mushroom Trampoline",
	Blueberry = "Blueberry",
}

InventoryConfig.Capacity = 5
InventoryConfig.PickupDistance = 10
InventoryConfig.DropDistance = 4
InventoryConfig.DropLifetime = 200
InventoryConfig.ActionCooldown = 0.2

InventoryConfig.CookColor = Color3.fromRGB(120, 72, 35)

InventoryConfig.SaveCookedFor = {
	Meat = true,
	Mushroom = true,
}

return InventoryConfig