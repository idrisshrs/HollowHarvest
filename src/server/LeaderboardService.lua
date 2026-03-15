--[[
	LeaderboardService — Gère le classement dynamique des Top 5 joueurs
	Trie par Pieces décroissant et envoie les mises à jour aux clients.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)

----- Créer le RemoteEvent LeaderboardUpdated -----

local leaderboardUpdatedEvent = ReplicatedStorage:FindFirstChild("LeaderboardUpdated")
if not leaderboardUpdatedEvent then
	leaderboardUpdatedEvent = Instance.new("RemoteEvent")
	leaderboardUpdatedEvent.Name = "LeaderboardUpdated"
	leaderboardUpdatedEvent.Parent = ReplicatedStorage
end

----- Module LeaderboardService -----

local LeaderboardService = {}

--[[
	Fonction privée : Collecte les données des joueurs et trie par Pieces décroissant.
	Retourne une table du Top 5 : { {name = "...", pieces = X, niveau = X}, ... }
]]
local function buildTop5()
	local playerDataList = {} -- Table de travail temporaire

	for _, player in pairs(Players:GetPlayers()) do
		local data = DataService.getData(player)

		-- IMPORTANT : Vérifier que data n'est pas nil (si le profil n'est pas encore chargé)
		if data then
			table.insert(playerDataList, {
				name = player.Name,
				pieces = data.Pieces or 0,
				niveau = data.NiveauTotal or 1,
			})
		end
	end

	-- Trier par Pieces décroissant
	table.sort(playerDataList, function(a, b)
		return a.pieces > b.pieces
	end)

	-- Extraire le Top 5
	local top5 = {}
	for i = 1, math.min(5, #playerDataList) do
		table.insert(top5, playerDataList[i])
	end

	return top5
end

--[[
	Mise à jour du leaderboard :
	1. Construit le Top 5
	2. Envoie aux clients via FireAllClients
]]
function LeaderboardService.update()
	local top5 = buildTop5()
	leaderboardUpdatedEvent:FireAllClients(top5)
end

--[[
	Démarre la boucle de mise à jour :
	1. Update immédiat
	2. Puis toutes les 15 secondes
]]
function LeaderboardService.start()
	task.spawn(function()
		LeaderboardService.update() -- Mise à jour immédiate

		while true do
			task.wait(15)
			LeaderboardService.update()
		end
	end)

	print("✅ [LeaderboardService] Démarré — mise à jour toutes les 15 secondes")
end

return LeaderboardService
