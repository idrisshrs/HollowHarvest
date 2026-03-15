--[[
	WorkerService — Système d'Ouvriers (NPCs) qui récolte automatiquement.
	Les ouvriers récolent les plots "ready" toutes les 8 secondes.
]]

local WorkerService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local GrowthService = require(script.Parent.GrowthService)
local PlantConfig = require(ReplicatedStorage:WaitForChild("PlantConfig"))

----- RemoteEvent -----

local workerStatusUpdatedEvent = ReplicatedStorage:FindFirstChild("WorkerStatusUpdated")
if not workerStatusUpdatedEvent then
	workerStatusUpdatedEvent = Instance.new("RemoteEvent")
	workerStatusUpdatedEvent.Name = "WorkerStatusUpdated"
	workerStatusUpdatedEvent.Parent = ReplicatedStorage
end

----- Boucle de récolte automatique (toutes les 8 secondes) -----

local function harvestPlots()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = DataService.getData(player)
		if not data or not data.WorkerCount or data.WorkerCount <= 0 then
			continue
		end

		-- Cherche les plots "ready" dans workspace
		local readyPlots = {}
		
		-- Parcourir tous les enfants du Workspace pour trouver les plots
		local function findReadyPlots(parent)
			for _, child in pairs(parent:GetChildren()) do
				if child:IsA("BasePart") and child.Name == "Plot" then
					if child:GetAttribute("PlotState") == "ready" then
						table.insert(readyPlots, child)
					end
				end
				-- Récursivement dans les dossiers
				if child:IsA("Folder") or child:IsA("Model") then
					findReadyPlots(child)
				end
			end
		end
		findReadyPlots(Workspace)

		-- Récolter un maximum de plots égal au nombre d'ouvriers
		local harvestCount = 0
		for i, plot in ipairs(readyPlots) do
			if harvestCount >= data.WorkerCount then
				break
			end

			-- Récupérer le gain de pièces (basé sur PlantConfig)
			local plantType = plot:GetAttribute("PlantType")
			if not plantType then
				continue
			end

			local config = PlantConfig[plantType]
			if not config then
				continue
			end

			local pieceGain = config.Gain or 15
			data.Pieces = data.Pieces + pieceGain

			-- Ajouter l'XP si disponible
			local xpGain = config.XPReward or 5
			if data.XP then
				data.XP = data.XP + xpGain
				-- Vérifier level up
				if data.XP >= data.XPMax then
					data.XP = data.XP - data.XPMax
					data.NiveauTotal = (data.NiveauTotal or 1) + 1
					local playerDataUpdatedEvent = ReplicatedStorage:FindFirstChild("PlayerDataUpdated")
					if playerDataUpdatedEvent then
						playerDataUpdatedEvent:FireClient(player, data.Pieces, data.Niveau, data.XP, data.XPMax, data.NiveauTotal)
					end
				end
			end

			-- Remettre l'état du plot à "vide"
			plot:SetAttribute("PlotState", "vide")

			-- Mettre à jour l'apparence du plot
			plot.Color = Color3.fromRGB(130, 90, 50)

			harvestCount = harvestCount + 1
		end

		-- Répliquer les données au client
		if harvestCount > 0 then
			local playerDataUpdatedEvent = ReplicatedStorage:FindFirstChild("PlayerDataUpdated")
			if playerDataUpdatedEvent then
				playerDataUpdatedEvent:FireClient(player, data.Pieces, data.Niveau, data.XP, data.XPMax, data.NiveauTotal)
			end
			workerStatusUpdatedEvent:FireClient(player, data.WorkerCount, harvestCount)
		end
	end
end

----- API : Embaucher un ouvrier -----

function WorkerService.hire(player)
	if not player or not player:IsA("Player") then
		return false
	end

	local data = DataService.getData(player)
	if not data then
		return false
	end

	-- Vérifier que le joueur n'a pas plus de 3 ouvriers
	if data.WorkerCount >= 3 then
		return false
	end

	data.WorkerCount = data.WorkerCount + 1

	-- Notifier le client
	workerStatusUpdatedEvent:FireClient(player, data.WorkerCount, 0)

	-- Créer le visuel du nouvel ouvrier
	WorkerService.spawnWorkerVisual(player)

	return true
end

----- API : Créer le visuel des ouvriers (Cube + Sphère + BillboardGui) -----

function WorkerService.spawnWorkerVisual(player)
	if not player or not player:IsA("Player") then
		return
	end

	local data = DataService.getData(player)
	if not data or not data.WorkerCount or data.WorkerCount <= 0 then
		return
	end

	-- Créer un dossier pour les ouvriers du joueur s'il n'existe pas
	local workersFolder = Workspace:FindFirstChild("Workers_" .. player.UserId)
	if not workersFolder then
		workersFolder = Instance.new("Folder")
		workersFolder.Name = "Workers_" .. player.UserId
		workersFolder.Parent = Workspace
	end

	-- Compter les ouvriers actuels du joueur
	local currentWorkerCount = #workersFolder:GetChildren()

	-- Créer les ouvriers manquants
	for i = currentWorkerCount + 1, data.WorkerCount do
		-- Corps (Cube)
		local body = Instance.new("Part")
		body.Name = "WorkerBody_" .. i
		body.Shape = Enum.PartType.Block
		body.Size = Vector3.new(1, 1.5, 1)
		body.Color = Color3.fromRGB(100, 150, 200)
		body.TopSurface = Enum.SurfaceType.Smooth
		body.BottomSurface = Enum.SurfaceType.Smooth
		body.CanCollide = false
		body.CFrame = Workspace:FindFirstChild("SpawnArea") and Workspace:FindFirstChild("SpawnArea").CFrame or CFrame.new(0, 5, 0)

		-- Tête (Sphère)
		local head = Instance.new("Part")
		head.Name = "WorkerHead_" .. i
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(0.8, 0.8, 0.8)
		head.Color = Color3.fromRGB(255, 200, 100)
		head.TopSurface = Enum.SurfaceType.Smooth
		head.BottomSurface = Enum.SurfaceType.Smooth
		head.CanCollide = false
		head.CFrame = body.CFrame + Vector3.new(0, 1.2, 0)

		-- Weld : attacher la tête au corps
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = head
		weld.Parent = head

		-- BillboardGui
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Name = "WorkerLabel"
		billboardGui.Size = UDim2.new(4, 0, 2, 0)
		billboardGui.MaxDistance = 100
		billboardGui.Parent = body

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Label"
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.Text = "👷 Ouvrier"
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.Parent = billboardGui

		-- Ajouter au dossier
		body.Parent = workersFolder
		head.Parent = workersFolder
	end
end

----- Boucle de récolte principale (toutes les 8 secondes) -----

function WorkerService.start()
	print("[WorkerService] Démarrage du service d'ouvriers...")

	task.spawn(function()
		while true do
			task.wait(8)
			harvestPlots()
		end
	end)

	print("[WorkerService] Boucle de récolte lancée (8s cycle)")
end

return WorkerService
