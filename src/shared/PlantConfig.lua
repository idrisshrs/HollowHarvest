local PlantConfig = {
	["Blé"] = {
		RequiredLevel = 1,
		Time = 10,
		Price = 0,
		Reward = 10,
		Color = Color3.fromRGB(255, 215, 0),
	},

	Carotte = {
		RequiredLevel = 2,
		Time = 15,
		Price = 0,
		Reward = 25,
		Color = Color3.fromRGB(255, 128, 0),
	},

	Tomate = {
		RequiredLevel = 3,
		Time = 20,
		Price = 0,
		Reward = 50,
		Color = Color3.fromRGB(255, 0, 0),
	},

	Rare = {
		Time = 20,
		Price = 50,
		Reward = 150,
		Color = Color3.fromRGB(255, 100, 255),
	},
}

return PlantConfig
