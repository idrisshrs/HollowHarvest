-- ============================================================
-- GrowthService.lua — src/server/
-- ============================================================

local GrowthService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local VFXService = require(script.Parent.VFXService)
local PlantConfig = require(ReplicatedStorage:WaitForChild("PlantConfig"))

local function getBestPlantForLevel(level: number)
	local bestName = nil
	local bestConfig = nil
	for name, config in pairs(PlantConfig) do
		if name ~= "Rare" and typeof(config) == "table" then
			local reqLevel = config.RequiredLevel
			if typeof(reqLevel) == "number" and reqLevel <= level then
				if not bestConfig or reqLevel > bestConfig.RequiredLevel then
					bestName = name
					bestConfig = config
				end
			end
		end
	end
	return bestName, bestConfig
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

	-- Adapter le texte pour le joueur qui regarde le prompt (graine rare vs achat normal)
	prompt.PromptShown:Connect(function(player: Player)
		if etat ~= "vide" then
			return
		end

		local data = DataService.getData(player)
		local niveau = data and data.Niveau or 1
		local grainesRares = player:GetAttribute("GrainesRares") or 0

		if grainesRares > 0 then
			prompt.ActionText = "Planter"
			prompt.ObjectText = "Rare (Gratuit - Graine possédée)"
		else
			local bestName, bestConfig = getBestPlantForLevel(niveau)
			if bestName and bestConfig then
				prompt.ObjectText = bestName .. " (Gratuit)"
			else
				prompt.ObjectText = "Planter"
			end
		end
	end)

	prompt.Triggered:Connect(function(player: Player)
		if etat == "vide" then
			local data = DataService.getData(player)
			if not data then
				warn("[GrowthService] Données introuvables pour le joueur " .. player.Name)
				return
			end

			local niveau = data.Niveau or 1
			local grainesRares = player:GetAttribute("GrainesRares") or 0

			if grainesRares > 0 then
				typePlante = "Rare"
			else
				local plantName, _ = getBestPlantForLevel(niveau)
				if not plantName then
					warn("[GrowthService] Aucune plante disponible pour le niveau " .. tostring(niveau) .. " de " .. player.Name)
					return
				end
				typePlante = plantName
			end

			local config = typePlante and PlantConfig[typePlante]
			if not config then
				warn("[GrowthService] Config manquante pour le type de plante: " .. tostring(typePlante))
				return
			end

			if typePlante == "Rare" then
				if grainesRares <= 0 then
					warn("[GrowthService] " .. player.Name .. " n'a plus de graines rares.")
					return
				end
				player:SetAttribute("GrainesRares", grainesRares - 1)
			else
				if data.Pieces < config.Price then
					warn("[GrowthService] " .. player.Name .. " n'a pas assez de pièces pour planter " .. tostring(typePlante) .. ". Requis: " .. tostring(config.Price) .. ", a: " .. tostring(data.Pieces))
					return
				end

				data.Pieces = data.Pieces - config.Price
				DataService.replicateToClient(player)
			end

			etat = "planted"
			prompt.Enabled = false

			plotPart.Color = Color3.fromRGB(80, 50, 20)

			task.spawn(function()
				task.wait(config.Time)

				etat = "ready"
				plotPart.Color = config.Color
				prompt.ActionText = "Récolter"
				prompt.ObjectText = string.format("%s : %d 🪙", typePlante, config.Reward)
				prompt.Enabled = true

				VFXService.plantGrow(plotPart.Position)
			end)

		elseif etat == "ready" then
			local data = DataService.getData(player)
			local niveau = data and data.Niveau or 1
			local config = typePlante and PlantConfig[typePlante]

			if not config then
				local _, bestConfig = getBestPlantForLevel(niveau)
				config = bestConfig
			end

			etat = "vide"
			setEmptyState(plotPart, prompt)

			if data and config then
				data.Pieces = data.Pieces + config.Reward
				print("💰 " .. player.Name .. " : Récolte " .. tostring(typePlante or "Inconnue") .. " +" .. tostring(config.Reward) .. " Pièces")
				DataService.replicateToClient(player)
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
