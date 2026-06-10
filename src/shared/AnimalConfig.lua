local AnimalConfig = {
	Human = {
		MaxHealth = 100,
	},

	Fox = {
		MaxHealth = 90,
		WalkSpeed = 24,
		SprintSpeed = 32,
		Damage = 15,
		AttackRange = 5,
		AttackCooldown = 0.8,
	},

	Wolf = {
		MaxHealth = 120,
		WalkSpeed = 18,
		SprintSpeed = 36,
		Damage = 20,
		AttackRange = 10,
		AttackCooldown = 1.0,
	},

	Bear = {
		MaxHealth = 250,
		WalkSpeed = 13,
		SprintSpeed = 18,
		Damage = 35,
		AttackRange = 7,
		AttackCooldown = 1.3,
	},

	Boar = {
		MaxHealth = 160,
		WalkSpeed = 17,
		SprintSpeed = 25,
		Damage = 25,
		AttackRange = 6,
		AttackCooldown = 1.1,
	},
}

return AnimalConfig
