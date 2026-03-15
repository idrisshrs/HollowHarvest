--[[
	ShopService — Le Marché 'Next Gen' (UI type MMORPG).
	Onglets : Améliorations, Graines, Armes.
	Graines : grille de cartes (UIGridLayout), achat → InventaireGraines.
]]

local ShopService = {}
local DataService = require(script.Parent.DataService)
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlantConfig = require(ReplicatedStorage:WaitForChild("PlantConfig"))

local FADE_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Ordre et noms affichés pour les graines (clé PlantConfig → libellé)
local GRAINE_ORDER = { "Ble", "Carotte", "Tomate", "Magique" }
local GRAINE_LABELS = {
	Ble = "Blé",
	Carotte = "Carotte",
	Tomate = "Tomate",
	Magique = "Magique",
}

-- Config Améliorations (niveau)
local AMELIORATION_PRICE = 50

function ShopService.start()
	local shopPart = workspace:WaitForChild("ShopPart", 10)
	if not shopPart then
		return
	end
	local prompt = shopPart:WaitForChild("ProximityPrompt")
	prompt.Triggered:Connect(function(player)
		ShopService.openShop(player)
	end)
end

function ShopService.openShop(player)
	if not player or not player:IsA("Player") then
		return
	end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui or playerGui:FindFirstChild("ShopGUI") then
		return
	end

	-- ─── ROOT ─────────────────────────────────────────────────────
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopGUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Ombre (Frame sombre décalée derrière)
	local shadow = Instance.new("Frame")
	shadow.Size = UDim2.new(0, 544, 0, 364)
	shadow.Position = UDim2.new(0.5, -272, 0.5, -182)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BorderSizePixel = 0
	shadow.Parent = screenGui
	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 20)
	shadowCorner.Parent = shadow
	shadow.BackgroundTransparency = 0.6

	-- Main frame (gris très foncé, contours 16px)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 520, 0, 340)
	mainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(50, 50, 55)
	mainStroke.Thickness = 1
	mainStroke.Parent = mainFrame
	mainFrame.ClipsDescendants = true

	-- Titre : 🌾 MARCHÉ DU VILLAGE 🌾 (doré, FredokaOne)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 44)
	title.Position = UDim2.new(0, 12, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.Text = "🌾 MARCHÉ DU VILLAGE 🌾"
	title.TextColor3 = Color3.fromRGB(255, 200, 80)
	title.TextScaled = true
	title.Parent = mainFrame

	-- Zone des onglets (en haut sous le titre)
	local tabList = Instance.new("Frame")
	tabList.Size = UDim2.new(1, -24, 0, 40)
	tabList.Position = UDim2.new(0, 12, 0, 52)
	tabList.BackgroundTransparency = 1
	tabList.Parent = mainFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabList

	-- Zone de contenu : 3 frames (un par onglet), un seul visible à la fois
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -24, 1, -120)
	contentArea.Position = UDim2.new(0, 12, 0, 100)
	contentArea.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	contentArea.BorderSizePixel = 0
	contentArea.ClipsDescendants = true
	contentArea.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 12)
	contentCorner.Parent = contentArea

	-- Conteneurs par onglet (visibility = seul moyen de changer d'onglet)
	local frameAmeliorations = Instance.new("Frame")
	frameAmeliorations.Name = "Ameliorations"
	frameAmeliorations.Size = UDim2.new(1, 0, 1, 0)
	frameAmeliorations.Position = UDim2.new(0, 0, 0, 0)
	frameAmeliorations.BackgroundTransparency = 1
	frameAmeliorations.Visible = false
	frameAmeliorations.Parent = contentArea
	local padA = Instance.new("UIPadding")
	padA.PaddingTop = UDim.new(0, 12)
	padA.PaddingBottom = UDim.new(0, 12)
	padA.PaddingLeft = UDim.new(0, 12)
	padA.PaddingRight = UDim.new(0, 12)
	padA.Parent = frameAmeliorations

	local frameGraines = Instance.new("Frame")
	frameGraines.Name = "Graines"
	frameGraines.Size = UDim2.new(1, 0, 1, 0)
	frameGraines.Position = UDim2.new(0, 0, 0, 0)
	frameGraines.BackgroundTransparency = 1
	frameGraines.Visible = false
	frameGraines.Parent = contentArea
	local padG = Instance.new("UIPadding")
	padG.PaddingTop = UDim.new(0, 12)
	padG.PaddingBottom = UDim.new(0, 12)
	padG.PaddingLeft = UDim.new(0, 12)
	padG.PaddingRight = UDim.new(0, 12)
	padG.Parent = frameGraines

	local frameArmes = Instance.new("Frame")
	frameArmes.Name = "Armes"
	frameArmes.Size = UDim2.new(1, 0, 1, 0)
	frameArmes.Position = UDim2.new(0, 0, 0, 0)
	frameArmes.BackgroundTransparency = 1
	frameArmes.Visible = false
	frameArmes.Parent = contentArea
	local padAr = Instance.new("UIPadding")
	padAr.PaddingTop = UDim.new(0, 12)
	padAr.PaddingBottom = UDim.new(0, 12)
	padAr.PaddingLeft = UDim.new(0, 12)
	padAr.PaddingRight = UDim.new(0, 12)
	padAr.Parent = frameArmes

	-- Bouton Fermer
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 100, 0, 28)
	closeButton.Position = UDim2.new(1, -112, 1, -36)
	closeButton.BackgroundColor3 = Color3.fromRGB(120, 50, 55)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.Text = "Fermer"
	closeButton.Parent = mainFrame
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- État : onglet actif + contenu déjà construit par onglet (on ne rebuild pas)
	local currentTab = nil
	local tabButtons = {}
	local built = { Ameliorations = false, Graines = false, Armes = false }

	local function highlightTab(btn, selected)
		if selected then
			btn.BackgroundColor3 = Color3.fromRGB(70, 110, 180)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
			btn.TextColor3 = Color3.fromRGB(200, 200, 210)
		end
	end

	-- Construire l'onglet Améliorations (une seule fois)
	local function buildAmeliorations()
		if built.Ameliorations then return end
		built.Ameliorations = true
		local data = DataService.getData(player)
		local levelText = data and tostring(data.Niveau or 1) or "?"

		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1, 0, 0, 36)
		info.BackgroundTransparency = 1
		info.Font = Enum.Font.GothamBold
		info.TextSize = 16
		info.TextColor3 = Color3.fromRGB(230, 230, 255)
		info.Text = "Niveau actuel : " .. levelText
		info.Parent = frameAmeliorations

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.Padding = UDim.new(0, 8)
		listLayout.Parent = frameAmeliorations

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 48)
		btn.BackgroundColor3 = Color3.fromRGB(60, 140, 90)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 18
		btn.Text = "Acheter Niveau (+1) — 50 🪙"
		btn.Parent = frameAmeliorations
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 10)
		bc.Parent = btn

		btn.MouseButton1Click:Connect(function()
			local currentData = DataService.getData(player)
			if not currentData or type(currentData.Pieces) ~= "number" then return end
			if currentData.Pieces < AMELIORATION_PRICE then
				btn.Text = "Pas assez de pièces"
				task.delay(0.8, function()
					if btn and btn.Parent then btn.Text = "Acheter Niveau (+1) — 50 🪙" end
				end)
				return
			end
			currentData.Pieces = currentData.Pieces - AMELIORATION_PRICE
			currentData.Niveau = (currentData.Niveau or 1) + 1
			DataService.replicateToClient(player)
			btn.Text = "Niveau amélioré !"
			task.delay(0.9, function()
				if btn and btn.Parent then btn.Text = "Acheter Niveau (+1) — 50 🪙" end
			end)
		end)

		-- Bouton "Ouvrier" (Worker)
		local workerBtn = Instance.new("TextButton")
		workerBtn.Size = UDim2.new(1, 0, 0, 48)
		workerBtn.BackgroundColor3 = Color3.fromRGB(100, 120, 60)
		workerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		workerBtn.Font = Enum.Font.GothamBold
		workerBtn.TextSize = 18
		workerBtn.Parent = frameAmeliorations
		local workerCorner = Instance.new("UICorner")
		workerCorner.CornerRadius = UDim.new(0, 10)
		workerCorner.Parent = workerBtn

		-- Fonction pour mettre à jour le texte du bouton
		local function updateWorkerButtonText()
			local wd = DataService.getData(player)
			if not wd then return end
			local workerCount = wd.WorkerCount or 0
			if workerCount >= 3 then
				workerBtn.Text = "👷 Ouvrier — Limite atteinte (3/3)"
				workerBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			else
				workerBtn.Text = string.format("👷 Ouvrier — %d/3 — 500 🪙", workerCount)
				workerBtn.BackgroundColor3 = Color3.fromRGB(100, 120, 60)
			end
		end
		updateWorkerButtonText()

		workerBtn.MouseButton1Click:Connect(function()
			local currentData = DataService.getData(player)
			if not currentData then return end
			
			-- Vérifier la limite
			if (currentData.WorkerCount or 0) >= 3 then
				workerBtn.Text = "Limite de 3 ouvriers atteinte"
				task.delay(1.2, updateWorkerButtonText)
				return
			end
			
			-- Vérifier les pièces
			if currentData.Pieces < 500 then
				workerBtn.Text = "Pas assez de pièces (500 nécessaires)"
				task.delay(1.2, updateWorkerButtonText)
				return
			end
			
			-- Effectuer l'achat
			currentData.Pieces = currentData.Pieces - 500
			currentData.WorkerCount = (currentData.WorkerCount or 0) + 1
			DataService.replicateToClient(player)
			
			-- Appeler WorkerService pour créer le visuel
			local WorkerService = require(script.Parent.WorkerService)
			WorkerService.spawnWorkerVisual(player)
			
			workerBtn.Text = "👷 Ouvrier embauché !"
			task.delay(1.0, updateWorkerButtonText)
		end)

		-- Bouton "Prestige" (Rebirth)
		local prestigeBtn = Instance.new("TextButton")
		prestigeBtn.Size = UDim2.new(1, 0, 0, 48)
		prestigeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		prestigeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		prestigeBtn.Font = Enum.Font.GothamBold
		prestigeBtn.TextSize = 18
		prestigeBtn.Parent = frameAmeliorations
		local prestigeCorner = Instance.new("UICorner")
		prestigeCorner.CornerRadius = UDim.new(0, 10)
		prestigeCorner.Parent = prestigeBtn

		-- Fonction pour mettre à jour l'état du bouton Prestige
		local function updatePrestigeButtonText()
			local pd = DataService.getData(player)
			if not pd then return end
			local niveauTotal = pd.NiveauTotal or 1
			local prestiges = pd.Prestiges or 0
			if niveauTotal >= 10 then
				prestigeBtn.Text = string.format("✨ Prestige #%d (Niveau %d/10) ✨", prestiges + 1, niveauTotal)
				prestigeBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 180)
			else
				prestigeBtn.Text = string.format("✨ Prestige (Niveau %d/10) ✨", niveauTotal)
				prestigeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			end
		end
		updatePrestigeButtonText()

		prestigeBtn.MouseButton1Click:Connect(function()
			local currentData = DataService.getData(player)
			if not currentData then return end
			
			-- Vérifier le niveau
			if (currentData.NiveauTotal or 1) < 10 then
				prestigeBtn.Text = "Niveau 10 requis"
				task.delay(1.0, updatePrestigeButtonText)
				return
			end
			
			-- Afficher popup de confirmation (Glassmorphism)
			local playerGui = player:FindFirstChild("PlayerGui")
			if not playerGui then return end
			
			local popupGui = Instance.new("ScreenGui")
			popupGui.Name = "PrestigeConfirmPopup"
			popupGui.ResetOnSpawn = false
			popupGui.IgnoreGuiInset = true
			popupGui.Parent = playerGui

			-- Arrière-plan semi-transparent
			local backdrop = Instance.new("Frame")
			backdrop.Size = UDim2.new(1, 0, 1, 0)
			backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			backdrop.BackgroundTransparency = 0.5
			backdrop.BorderSizePixel = 0
			backdrop.Parent = popupGui

			-- Popup frame (Glassmorphism)
			local popup = Instance.new("Frame")
			popup.Size = UDim2.new(0, 380, 0, 220)
			popup.Position = UDim2.new(0.5, -190, 0.5, -110)
			popup.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
			popup.BackgroundTransparency = 0.15
			popup.BorderSizePixel = 0
			popup.Parent = popupGui

			local popupCorner = Instance.new("UICorner")
			popupCorner.CornerRadius = UDim.new(0, 20)
			popupCorner.Parent = popup

			local popupStroke = Instance.new("UIStroke")
			popupStroke.Color = Color3.fromRGB(150, 100, 180)
			popupStroke.Thickness = 2
			popupStroke.Parent = popup

			-- Titre
			local popupTitle = Instance.new("TextLabel")
			popupTitle.Size = UDim2.new(1, -24, 0, 50)
			popupTitle.Position = UDim2.new(0, 12, 0, 12)
			popupTitle.BackgroundTransparency = 1
			popupTitle.Font = Enum.Font.FredokaOne
			popupTitle.TextSize = 20
			popupTitle.TextColor3 = Color3.fromRGB(255, 200, 255)
			popupTitle.Text = "✨ Prêt pour le Prestige ?"
			popupTitle.TextWrapped = true
			popupTitle.Parent = popup

			-- Texte descriptif
			local popupDesc = Instance.new("TextLabel")
			popupDesc.Size = UDim2.new(1, -24, 0, 60)
			popupDesc.Position = UDim2.new(0, 12, 0, 62)
			popupDesc.BackgroundTransparency = 1
			popupDesc.Font = Enum.Font.Gotham
			popupDesc.TextSize = 14
			popupDesc.TextColor3 = Color3.fromRGB(220, 220, 220)
			popupDesc.Text = "Reset de progression contre +15% de gains permanents.\n\nNouveaul multiplicateur : " .. string.format("%.2f", 1.0 + ((currentData.Prestiges or 0) + 1) * 0.15) .. "x"
			popupDesc.TextWrapped = true
			popupDesc.Parent = popup

			-- Bouton ✅ (Confirmer)
			local confirmBtn = Instance.new("TextButton")
			confirmBtn.Size = UDim2.new(0, 80, 0, 40)
			confirmBtn.Position = UDim2.new(0, 50, 1, -52)
			confirmBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
			confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			confirmBtn.Font = Enum.Font.GothamBold
			confirmBtn.TextSize = 16
			confirmBtn.Text = "✅ OUI"
			confirmBtn.Parent = popup

			local confirmCorner = Instance.new("UICorner")
			confirmCorner.CornerRadius = UDim.new(0, 10)
			confirmCorner.Parent = confirmBtn

			-- Bouton ❌ (Annuler)
			local cancelBtn = Instance.new("TextButton")
			cancelBtn.Size = UDim2.new(0, 80, 0, 40)
			cancelBtn.Position = UDim2.new(1, -130, 1, -52)
			cancelBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
			cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			cancelBtn.Font = Enum.Font.GothamBold
			cancelBtn.TextSize = 16
			cancelBtn.Text = "❌ NON"
			cancelBtn.Parent = popup

			local cancelCorner = Instance.new("UICorner")
			cancelCorner.CornerRadius = UDim.new(0, 10)
			cancelCorner.Parent = cancelBtn

			-- Logique des boutons
			confirmBtn.MouseButton1Click:Connect(function()
				popupGui:Destroy()
				
				-- Appeler PrestigeService
				local PrestigeService = require(script.Parent.PrestigeService)
				local success = PrestigeService.prestige(player)
				
				if success then
					prestigeBtn.Text = "✨ Prestige réussi ! ✨"
					task.delay(1.5, updatePrestigeButtonText)
				else
					prestigeBtn.Text = "Erreur de prestige"
					task.delay(1.5, updatePrestigeButtonText)
				end
			end)

			cancelBtn.MouseButton1Click:Connect(function()
				popupGui:Destroy()
			end)
		end)
	end

	-- Grille 2x2 : zone utile ~472x196 (contentArea moins padding). CellSize pour 2 colonnes, 2 lignes.
	local CELL_PADDING = 10
	local INNER_W = 496 - 24
	local INNER_H = 220 - 24
	local CELL_W = math.floor((INNER_W - CELL_PADDING) / 2)
	local CELL_H = math.floor((INNER_H - CELL_PADDING) / 2)

	-- Construire l'onglet Graines (grille 2x2, une seule fois)
	local function buildGraines()
		if built.Graines then return end
		built.Graines = true

		local grid = Instance.new("UIGridLayout")
		grid.Name = "GridLayout"
		grid.CellSize = UDim2.new(0, CELL_W, 0, CELL_H)
		grid.CellPadding = UDim2.new(0, CELL_PADDING, 0, CELL_PADDING)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = frameGraines

		for idx, seedKey in ipairs(GRAINE_ORDER) do
			local cfg = PlantConfig[seedKey]
			if not cfg then continue end
			local prix = cfg.PrixAchat or 0
			local label = GRAINE_LABELS[seedKey] or seedKey

			local card = Instance.new("Frame")
			card.Size = UDim2.new(0, CELL_W, 0, CELL_H)
			card.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
			card.BorderSizePixel = 0
			card.LayoutOrder = idx
			card.Parent = frameGraines

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 12)
			cardCorner.Parent = card

			local cardStroke = Instance.new("UIStroke")
			cardStroke.Color = Color3.fromRGB(60, 60, 70)
			cardStroke.Thickness = 1
			cardStroke.Parent = card

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -8, 0, 24)
			nameLabel.Position = UDim2.new(0, 4, 0, 4)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 14
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.Text = label
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			nameLabel.Parent = card

			local priceLabel = Instance.new("TextLabel")
			priceLabel.Size = UDim2.new(1, -8, 0, 28)
			priceLabel.Position = UDim2.new(0, 4, 0, 28)
			priceLabel.BackgroundTransparency = 1
			priceLabel.Font = Enum.Font.GothamBold
			priceLabel.TextSize = 18
			priceLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
			priceLabel.Text = "💰 " .. tostring(prix)
			priceLabel.Parent = card

			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(1, -12, 0, 32)
			buyBtn.Position = UDim2.new(0, 6, 1, -38)
			buyBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 80)
			buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 14
			buyBtn.Text = "Acheter"
			buyBtn.Parent = card
			local buyCorner = Instance.new("UICorner")
			buyCorner.CornerRadius = UDim.new(0, 8)
			buyCorner.Parent = buyBtn

			buyBtn.MouseButton1Click:Connect(function()
				local currentData = DataService.getData(player)
				if not currentData or type(currentData.Pieces) ~= "number" then return end
				if currentData.Pieces < prix then
					local orig = buyBtn.Text
					buyBtn.Text = "Pas assez 🪙"
					task.delay(0.8, function()
						if buyBtn and buyBtn.Parent then buyBtn.Text = orig end
					end)
					return
				end
				currentData.Pieces = currentData.Pieces - prix
				currentData.InventaireGraines = currentData.InventaireGraines or {}
				currentData.InventaireGraines[seedKey] = (currentData.InventaireGraines[seedKey] or 0) + 1
				DataService.replicateToClient(player)
				DataService.replicateSeedInventoryToClient(player)
				local origText = buyBtn.Text
				buyBtn.Text = "Acheté !"
				buyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
				task.delay(0.9, function()
					if buyBtn and buyBtn.Parent then
						buyBtn.Text = origText
						buyBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 80)
					end
				end)
			end)
		end
	end

	-- Construire l'onglet Armes (une seule fois)
	local function buildArmes()
		if built.Armes then return end
		built.Armes = true
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 50)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 18
		label.TextColor3 = Color3.fromRGB(230, 230, 255)
		label.Text = "🔒 Armes — Niveau 10 requis"
		label.Parent = frameArmes
	end

	-- Changer d'onglet : cacher les autres, afficher celui cliqué, construire si besoin
	local function selectTab(key)
		if currentTab == key then return end
		currentTab = key
		frameAmeliorations.Visible = (key == "Ameliorations")
		frameGraines.Visible = (key == "Graines")
		frameArmes.Visible = (key == "Armes")
		for name, btn in pairs(tabButtons) do
			highlightTab(btn, name == key)
		end
		if key == "Ameliorations" then buildAmeliorations()
		elseif key == "Graines" then buildGraines()
		elseif key == "Armes" then buildArmes()
		end
	end

	-- Création des boutons d'onglets
	local function addTab(key, text)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 140, 0, 36)
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btn.TextColor3 = Color3.fromRGB(200, 200, 210)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 15
		btn.Text = text
		btn.Parent = tabList
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn
		btn.MouseButton1Click:Connect(function()
			selectTab(key)
		end)
		tabButtons[key] = btn
	end
	addTab("Ameliorations", "Améliorations")
	addTab("Graines", "Graines")
	addTab("Armes", "Armes")

	-- Onglet par défaut : Graines
	selectTab("Graines")
end

return ShopService
