--[[
	XPService — Gestion XP et montée de niveau.
	Utilise DataService pour lire/écrire XP, XPMax, NiveauTotal.
	Récolte normale +5 XP, récolte rare (Magique) +15 XP, kill monstre +20 XP.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.DataService)

----- RemoteEvent Level Up -----

local playerLevelUpEvent = ReplicatedStorage:FindFirstChild("PlayerLevelUp")
if not playerLevelUpEvent then
	playerLevelUpEvent = Instance.new("RemoteEvent")
	playerLevelUpEvent.Name = "PlayerLevelUp"
	playerLevelUpEvent.Parent = ReplicatedStorage
end

local XPService = {}

--- Appelle le callback (pour override / tests) et fire le client.
function XPService.onLevelUp(player, newLevel)
	playerLevelUpEvent:FireClient(player, newLevel)
	print("🎉 [XPService]", player.Name, "Niveau", newLevel)
end

--- Ajoute amount XP au joueur. Gère level up : XP -= XPMax, NiveauTotal += 1, XPMax *= 1.4.
--- Réplique vers le client après chaque modification.
function XPService.addXP(player, amount)
	if type(amount) ~= "number" or amount <= 0 then return end
	local data = DataService.getData(player)
	if not data then return end

	data.XP = (data.XP or 0) + amount

	while data.XP >= (data.XPMax or 100) do
		data.XP = data.XP - (data.XPMax or 100)
		data.NiveauTotal = (data.NiveauTotal or 1) + 1
		data.XPMax = math.floor((data.XPMax or 100) * 1.4)
		XPService.onLevelUp(player, data.NiveauTotal)
	end

	DataService.replicateToClient(player)
end

return XPService
