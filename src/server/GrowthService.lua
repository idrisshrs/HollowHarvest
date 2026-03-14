-- ============================================================
-- GrowthService.lua — src/server/
-- ============================================================

local GrowthService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local VFXService = require(script.Parent.VFXService)
local XPService = require(script.Parent.XPService)
local PlantConfig = require(ReplicatedStorage:WaitForChild("PlantConfig"))

local SEED_DISPLAY_NAMES = { Ble = "Blé", Carotte = "Carotte", Tomate = "Tomate", Magique = "Magique" }

local function getBestSeedFromInventory(inventaireGraines)
	if not inventaireGraines then
		return nil, nil, 0
	end

	local bestName = nil
	local bestConfig = nil
	local bestPrix = -math.huge
	local stock = 0

	for seedName, quantity in pairs(inventaireGraines) do
		if type(quantity) == "number" and quantity > 0 then
			local config = PlantConfig[seedName]
			if config and typeof(config) == "table" then
				local prix = config.PrixAchat or 0
				if prix > bestPrix then
					bestPrix = prix
					bestName = seedName
					bestConfig = config
					stock = quantity
				end
			end
		end
	end

	return bestName, bestConfig, stock
end

local function setEmptyState(plotPart: BasePart, prompt: ProximityPrompt)
	plotPart.Color = Color3.fromRGB(130, 90, 50)
	prompt.ActionText = "Planter"
	prompt.ObjectText = "Planter"
end

local function initPlot(plotPart: BasePart)
	local prompt = plotPart:WaitForChild("ProximityPrompt") :: ProximityPrompt

	local etat = "vide"
	local typePlante = nil :: string?

	setEmptyState(plotPart, prompt)

	-- Adapter le texte pour le joueur (graine la plus chère disponible dans l'inventaire)
	prompt.PromptShown:Connect(function(player: Player)
		if etat ~= "vide" then
			return
		end
		local data = DataService.getData(player)
		local inventaire = data and data.InventaireGraines or nil
		local bestName, _, stock = getBestSeedFromInventory(inventaire)
		if bestName and stock > 0 then
			local displayName = SEED_DISPLAY_NAMES[bestName] or bestName
			prompt.ActionText = "Planter"
			prompt.ObjectText = string.format("%s (Stock: %d)", displayName, stock)
		else
			prompt.ActionText = "Inventaire vide"
			prompt.ObjectText = "Allez au Marché"
		end
	end)

	prompt.Triggered:Connect(function(player: Player)
		if etat == "vide" then
			local data = DataService.getData(player)
			if not data then
				warn("[GrowthService] Données introuvables pour le joueur " .. player.Name)
				return
			end
			local inventaire = data.InventaireGraines or {}
			local bestName, _, stock = getBestSeedFromInventory(inventaire)
			if not bestName or stock <= 0 then
				warn("[GrowthService] " .. player.Name .. " n'a aucune graine dans son inventaire.")
				return
			end
			typePlante = bestName
			local config = PlantConfig[typePlante]
			if not config then
				warn("[GrowthService] Config manquante pour le type de plante: " .. tostring(typePlante))
				return
			end
			inventaire[typePlante] = math.max((inventaire[typePlante] or 0) - 1, 0)
			DataService.replicateSeedInventoryToClient(player)

			etat = "planted"
			prompt.Enabled = false

			plotPart.Color = Color3.fromRGB(80, 50, 20)

			task.spawn(function()
				task.wait(config.Time)

				etat = "ready"
				plotPart.Color = config.Color
				prompt.ActionText = "Récolter"
				local displayName = SEED_DISPLAY_NAMES[typePlante] or typePlante
				prompt.ObjectText = string.format("%s : %d 🪙", displayName, config.Reward)
				prompt.Enabled = true

				VFXService.plantGrow(plotPart.Position)
			end)

		elseif etat == "ready" then
			local data = DataService.getData(player)
			local config = typePlante and PlantConfig[typePlante]

			if not config then
				warn("[GrowthService] Config manquante au moment de la récolte pour " .. tostring(typePlante))
				etat = "vide"
				setEmptyState(plotPart, prompt)
				return
			end

			etat = "vide"
			setEmptyState(plotPart, prompt)

			if data and config then
				data.Pieces = data.Pieces + config.Reward
				local xpGain = (type(config.XPReward) == "number" and config.XPReward > 0) and config.XPReward or 5
				XPService.addXP(player, xpGain)
				DataService.replicateToClient(player)
				print("💰 " .. player.Name .. " : Récolte " .. tostring(typePlante or "Inconnue") .. " +" .. tostring(config.Reward) .. " Pièces")
			end

			typePlante = nil

			VFXService.harvest(plotPart.Position, player)
		end
	end)
end

function GrowthService.start()
	local plotsFolder = workspace:WaitForChild("Plots")

	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:IsA("BasePart") then
			initPlot(plot)
		end
	end
end

return GrowthService
