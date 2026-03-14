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
