local WeaponConfig = {
	Rifle = {
		range = 500,
		cooldown = 3.0,
		damage = 50,
		speed = 500,
	},

	Deagle = {
		range = 300,
		cooldown = 1.0,
		damage = 20,
		speed = 300,
	},

	Bow = {
		range = 220,
		cooldown = 0.9,
		damage = 25,
		speed = 170,
		gravity = 30,
		projectile = "Arrow",
	},

	Shotgun = {
		range = 150,
		cooldown = 2.0,
		damage = 12,
		speed = 320,
		pellets = 8,
		spreadDeg = 7,
	},

	Axe = {
		radius = 10,
		cooldown = 0.35,
		damage = 25,
	},
}

return WeaponConfig