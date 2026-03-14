--[[
	DataService — Sauvegarde des joueurs avec ProfileService.
	Données : Pieces (0 par défaut), Niveau (1 par défaut).
	ProfileService est dans ReplicatedStorage (src/shared/ProfileService.lua).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ReplicatedStorage:WaitForChild("ProfileService"))

----- Template (valeurs par défaut pour un nouveau profil) -----

local profileTemplate = {
	Pieces = 100,
	Niveau = 1,
	XP = 0,
	XPMax = 100,
	NiveauTotal = 1,
	InventaireGraines = {
		Ble = 5,
		Carotte = 0,
		Tomate = 0,
		Magique = 0,
	},
}

----- Store & cache -----

local profileStore = ProfileService.GetProfileStore("PlayerData_v1", profileTemplate)
local profiles = {} -- [player] = profile
local profilesByUserId = {} -- [userId] = profile (pour lookup flexible)

----- RemoteEvents de réplication -----

local playerDataUpdatedEvent = ReplicatedStorage:WaitForChild("PlayerDataUpdated") :: RemoteEvent

local seedInventoryUpdatedEvent = ReplicatedStorage:FindFirstChild("SeedInventoryUpdated")
if not seedInventoryUpdatedEvent then
	seedInventoryUpdatedEvent = Instance.new("RemoteEvent")
	seedInventoryUpdatedEvent.Name = "SeedInventoryUpdated"
	seedInventoryUpdatedEvent.Parent = ReplicatedStorage
end

----- Chargement d'un profil -----

local function onPlayerAdded(player)
	local profileKey = "Player_" .. player.UserId
	local profile = profileStore:LoadProfileAsync(profileKey)

	if profile == nil then
		warn("[DataService] Profil non chargé pour " .. player.Name .. " (UserId: " .. player.UserId .. ") — possible session lock.")
		player:Kick("Impossible de charger tes données. Réessaie dans un instant.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile:ListenToRelease(function()
		profiles[player] = nil
		profilesByUserId[player.UserId] = nil
		print("[DataService] Profil libéré (sauvegardé) pour " .. player.Name .. ".")
		player:Kick("Tes données ont été reprises par un autre serveur. Reconnecte-toi.")
	end)

	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	profiles[player] = profile
	profilesByUserId[player.UserId] = profile

	-- Migration : forcer InventaireGraines avec au moins 5 Blé si absent (anciens profils)
	local inv = profile.Data.InventaireGraines
	if type(inv) ~= "table" then
		profile.Data.InventaireGraines = {
			Ble = 5,
			Carotte = 0,
			Tomate = 0,
			Magique = 0,
		}
	else
		if inv.Ble == nil or (type(inv.Ble) == "number" and inv.Ble < 0) then
			inv.Ble = 5
		end
		if inv.Carotte == nil then inv.Carotte = 0 end
		if inv.Tomate == nil then inv.Tomate = 0 end
		if inv.Magique == nil then inv.Magique = 0 end
	end

	-- Migration sauvegarde actuelle : donner 100 pièces et 5 Blé si compte à zéro
	if profile.Data.Pieces == 0 then
		profile.Data.Pieces = 100
	end
	if not profile.Data.InventaireGraines.Ble or profile.Data.InventaireGraines.Ble == 0 then
		profile.Data.InventaireGraines.Ble = 5
	end

	-- Migration XP (Reconcile ajoute les champs manquants ; sécuriser les anciens profils)
	if profile.Data.XP == nil or type(profile.Data.XP) ~= "number" then profile.Data.XP = 0 end
	if profile.Data.XPMax == nil or type(profile.Data.XPMax) ~= "number" then profile.Data.XPMax = 100 end
	if profile.Data.NiveauTotal == nil or type(profile.Data.NiveauTotal) ~= "number" then profile.Data.NiveauTotal = 1 end

	print("[DataService] Profil chargé pour " .. player.Name .. " — Pieces: " .. tostring(profile.Data.Pieces) .. ", Niveau: " .. tostring(profile.Data.Niveau))

	-- Répliquer les données vers le client (HUD + inventaire) dès la connexion
	playerDataUpdatedEvent:FireClient(player, profile.Data.Pieces, profile.Data.Niveau, profile.Data.XP, profile.Data.XPMax, profile.Data.NiveauTotal)
	seedInventoryUpdatedEvent:FireClient(player, profile.Data.InventaireGraines)
end

----- Libération (sauvegarde) à la déconnexion -----

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if profile then
		print("[DataService] Sauvegarde et libération du profil pour " .. player.Name .. ".")
		profile:Release()
		profiles[player] = nil
		profilesByUserId[player.UserId] = nil
	end
end

----- Initialisation -----

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

----- API (optionnel) : accès au profil depuis d'autres scripts -----

local DataService = {}

--- Retourne le profil (objet ProfileService) pour un joueur.
--- Accepte un Player ou un UserId (number).
function DataService.getProfile(playerOrUserId)
	local profile = nil
	if type(playerOrUserId) == "number" then
		profile = profilesByUserId[playerOrUserId]
	else
		profile = profiles[playerOrUserId]
	end
	return profile
end

--- Retourne la table Data (Pieces, Niveau) pour un joueur, ou nil si pas chargé.
--- Accepte un Player ou un UserId (number).
function DataService.getData(playerOrUserId)
	local profile = DataService.getProfile(playerOrUserId)
	local data = profile and profile.Data or nil
	local keyStr = type(playerOrUserId) == "number" and ("UserId=" .. tostring(playerOrUserId)) or ("Player " .. tostring(playerOrUserId.Name) .. "/" .. tostring(playerOrUserId.UserId))
	print("[DataService] getData(" .. keyStr .. ") -> profile=" .. (profile and "ok" or "nil") .. ", data=" .. (data and "ok" or "nil"))
	return data
end

--- Envoie les données actuelles du joueur à son client (pour le HUD).
--- À appeler après toute modification de Pieces, Niveau ou XP côté serveur.
function DataService.replicateToClient(player)
	local data = DataService.getData(player)
	if data then
		playerDataUpdatedEvent:FireClient(player, data.Pieces, data.Niveau, data.XP, data.XPMax, data.NiveauTotal)
	end
end

--- Réplique uniquement l'inventaire de graines vers le client.
--- À appeler après toute modification de data.InventaireGraines.
function DataService.replicateSeedInventoryToClient(player)
	local data = DataService.getData(player)
	if data and data.InventaireGraines then
		seedInventoryUpdatedEvent:FireClient(player, data.InventaireGraines)
	end
end

return DataService
