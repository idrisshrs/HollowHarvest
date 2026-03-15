local DailyService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Création du RemoteEvent pour les récompenses journalières AVANT tout require
local dailyRewardClaimedEvent = ReplicatedStorage:FindFirstChild("DailyRewardClaimed")
if not dailyRewardClaimedEvent then
	dailyRewardClaimedEvent = Instance.new("RemoteEvent")
	dailyRewardClaimedEvent.Name = "DailyRewardClaimed"
	dailyRewardClaimedEvent.Parent = ReplicatedStorage
end

local DataService = require(script.Parent.DataService)

function DailyService.checkAndGive(player)
	local profile = DataService.getProfile(player)
	if not profile then
		warn("[DailyService] Profil non trouvé pour le joueur : " .. player.Name)
		return
	end

	local now = os.time()
	local lastLoginDay = profile.Data.LastLoginDay
	local diff = now - lastLoginDay

	-- Si moins de 20 heures se sont écoulées, le joueur a déjà réclamé ou il est trop tôt
	if diff < 72000 then -- 20 hours * 3600 seconds/hour
		print("[DailyService] " .. player.Name .. " a déjà réclamé sa récompense ou est trop tôt.")
		return
	end

	-- Mise à jour du LoginStreak
	if diff >= 72000 and diff < 172800 then -- 20 hours to 48 hours
		profile.Data.LoginStreak = math.min(profile.Data.LoginStreak + 1, 7)
	else -- Plus de 48 heures, la série est cassée
		profile.Data.LoginStreak = 1
	end

	profile.Data.LastLoginDay = now
	profile.Data.TotalDaysPlayed = profile.Data.TotalDaysPlayed + 1

	local streak = profile.Data.LoginStreak
	local awardedPieces = 0
	local awardedItems = {}

	if streak == 1 then
		awardedPieces = 50
	elseif streak == 2 then
		awardedPieces = 75
		awardedItems.Ble = (awardedItems.Ble or 0) + 1
	elseif streak == 3 then
		awardedPieces = 100
	elseif streak == 4 then
		awardedPieces = 150
		awardedItems.Carotte = (awardedItems.Carotte or 0) + 1
	elseif streak == 5 then
		awardedPieces = 200
	elseif streak == 6 then
		awardedPieces = 250
		awardedItems.Tomate = (awardedItems.Tomate or 0) + 1
	elseif streak == 7 then
		awardedPieces = 500
		awardedItems.Magique = (awardedItems.Magique or 0) + 1
	end

	-- Appliquer les récompenses
	profile.Data.Pieces += awardedPieces
	for item, amount in pairs(awardedItems) do
		if profile.Data.InventaireGraines[item] then
			profile.Data.InventaireGraines[item] += amount
		else
			profile.Data.InventaireGraines[item] = amount
		end
	end

	DataService.replicateToClient(player)
	DataService.replicateSeedInventoryToClient(player)

	print(string.format("[DailyService] %s a réclamé sa récompense journalière J%d : %d pièces, items: %s",
		player.Name, streak, awardedPieces, game.HttpService:JSONEncode(awardedItems)))

	dailyRewardClaimedEvent:FireClient(player, streak, awardedPieces, awardedItems)
end

return DailyService