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
		print("[DataService] Profil libéré (sauvegardé) pour " .. player.Name .. ".")
		player:Kick("Tes données ont été reprises par un autre serveur. Reconnecte-toi.")
	end)

	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	profiles[player] = profile
	print("[DataService] Profil chargé pour " .. player.Name .. " — Pieces: " .. tostring(profile.Data.Pieces) .. ", Niveau: " .. tostring(profile.Data.Niveau))
end

----- Libération (sauvegarde) à la déconnexion -----

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if profile then
		print("[DataService] Sauvegarde et libération du profil pour " .. player.Name .. ".")
		profile:Release()
		profiles[player] = nil
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

function DataService.getProfile(player)
	return profiles[player]
end

function DataService.getData(player)
	local profile = profiles[player]
	return profile and profile.Data or nil
end

return DataService
