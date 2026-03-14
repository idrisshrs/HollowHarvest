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
	Pieces = 0,
	Niveau = 1,
}

----- Store & cache -----

local profileStore = ProfileService.GetProfileStore("PlayerData_v1", profileTemplate)
local profiles = {} -- [player] = profile
local profilesByUserId = {} -- [userId] = profile (pour lookup flexible)

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
	print("[DataService] Profil chargé pour " .. player.Name .. " — Pieces: " .. tostring(profile.Data.Pieces) .. ", Niveau: " .. tostring(profile.Data.Niveau))

	-- Répliquer les données vers le client pour le HUD (source de vérité = serveur)
	local playerDataUpdated = ReplicatedStorage:WaitForChild("PlayerDataUpdated") :: RemoteEvent
	playerDataUpdated:FireClient(player, profile.Data.Pieces, profile.Data.Niveau)
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
--- À appeler après toute modification de Pieces ou Niveau côté serveur.
function DataService.replicateToClient(player)
	local data = DataService.getData(player)
	if data then
		local playerDataUpdated = ReplicatedStorage:WaitForChild("PlayerDataUpdated") :: RemoteEvent
		playerDataUpdated:FireClient(player, data.Pieces, data.Niveau)
	end
end

return DataService
