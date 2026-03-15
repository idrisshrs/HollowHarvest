--[[
	PrestigeService — Système de Prestige (rebirth avec bonus permanent).
	Les joueurs peuvent redémarrer à Niveau 1 pour obtenir un multiplicateur de gains.
]]

local PrestigeService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

----- RemoteEvent -----

local playerPrestigedEvent = ReplicatedStorage:FindFirstChild("PlayerPrestiged")
if not playerPrestigedEvent then
	playerPrestigedEvent = Instance.new("RemoteEvent")
	playerPrestigedEvent.Name = "PlayerPrestiged"
	playerPrestigedEvent.Parent = ReplicatedStorage
end

----- API : Vérifier si un joueur peut faire un prestige -----

function PrestigeService.canPrestige(player)
	if not player or not player:IsA("Player") then
		return false
	end

	local data = DataService.getData(player)
	if not data then
		return false
	end

	return data.NiveauTotal >= 10
end

----- API : Effectuer un prestige -----

function PrestigeService.prestige(player)
	if not player or not player:IsA("Player") then
		return false
	end

	local data = DataService.getData(player)
	if not data then
		return false
	end

	-- Vérifier la condition
	if not PrestigeService.canPrestige(player) then
		warn("[PrestigeService] " .. player.Name .. " n'a pas le niveau suffisant pour faire un prestige (niveau " .. (data.NiveauTotal or 1) .. "/10)")
		return false
	end

	-- Incrémenter les prestiges
	data.Prestiges = (data.Prestiges or 0) + 1

	-- Calculer le nouveau multiplicateur : 1.0 + (Prestiges * 0.15)
	data.PieceMultiplier = 1.0 + (data.Prestiges * 0.15)

	-- Hard reset : réinitialiser la progression
	data.Pieces = 0
	data.XP = 0
	data.NiveauTotal = 1
	data.Niveau = 1
	data.XPMax = 100

	-- Conserver WorkerCount et InventaireGraines
	-- (pas de reset sur ces champs)

	print("[PrestigeService] " .. player.Name .. " a atteint le Prestige #" .. data.Prestiges .. " (multiplicateur: " .. string.format("%.2f", data.PieceMultiplier) .. "x)")

	-- Répliquer les données vers le client
	DataService.replicateToClient(player)

	-- Diffuser l'événement à tous les clients (notification globale)
	playerPrestigedEvent:FireAllClients({
		name = player.Name,
		prestiges = data.Prestiges,
		multiplier = data.PieceMultiplier,
	})

	return true
end

return PrestigeService
