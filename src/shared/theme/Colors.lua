local Colors = {
	BackgroundDark = Color3.fromRGB(20, 20, 20),
	CardDark = Color3.fromRGB(30, 30, 30),
	PanelDark = Color3.fromRGB(60, 60, 60),

	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(230, 230, 230),
	BorderLight = Color3.fromRGB(255, 255, 255),
	TextStrokeDark = Color3.fromRGB(0, 0, 0),

	HealthRed = Color3.fromRGB(220, 80, 80),
	DamageRed = Color3.fromRGB(255, 0, 0),
	HungerYellow = Color3.fromRGB(230, 180, 60),
	WarningYellow = Color3.fromRGB(230, 200, 80),

	SuccessGreen = Color3.fromRGB(80, 200, 120),
}

Colors.BackpackGreen = Colors.SuccessGreen
Colors.StaminaGreen = Colors.SuccessGreen

Colors.PanelBackgroundColor = Colors.CardDark
Colors.PanelBackgroundTransparency = 0.15
Colors.PanelBorderColor = Colors.BorderLight
Colors.PanelBorderTransparency = 0.75

return Colors
