--[[
	PlantConfig — Économie des 4 graines (courbe de progression).
	Ble → Carotte → Tomate → Magique.
]]

local PlantConfig = {
	Ble = {
		RequiredLevel = 1,
		Time = 8,
		PrixAchat = 10,
		Reward = 15,
		XPReward = 5,
		Color = Color3.fromRGB(255, 215, 0),
	},
	Carotte = {
		RequiredLevel = 1,
		Time = 20,
		PrixAchat = 30,
		Reward = 50,
		XPReward = 15,
		Color = Color3.fromRGB(255, 128, 0),
	},
	Tomate = {
		RequiredLevel = 1,
		Time = 45,
		PrixAchat = 100,
		Reward = 200,
		XPReward = 40,
		Color = Color3.fromRGB(255, 0, 0),
	},
	Magique = {
		RequiredLevel = 1,
		Time = 120,
		PrixAchat = 500,
		Reward = 1500,
		XPReward = 150,
		Color = Color3.fromRGB(180, 100, 255),
	},
}

return PlantConfig
