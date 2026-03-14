--[[
	HUDController — Redesign HUD (pills Pièces/Niveau, bouton Sac, panneau inventaire en grille).
	Écoute PlayerDataUpdated (Pièces, Niveau) et SeedInventoryUpdated (graines).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----- Thème -----
local COLOR_BG_DARK = Color3.fromRGB(25, 25, 30)
local COLOR_PILL_BG = Color3.fromRGB(30, 30, 38)
local COLOR_GOLD = Color3.fromRGB(255, 200, 50)
local COLOR_VIOLET = Color3.fromRGB(180, 120, 255)
local COLOR_CARD_BG = Color3.fromRGB(30, 30, 40)
local COLOR_CARD_STROKE = Color3.fromRGB(60, 60, 75)
local COLOR_QTY_OR = Color3.fromRGB(255, 200, 50)
local COLOR_QTY_ZERO = Color3.fromRGB(120, 120, 130)
local COLOR_XP_BAR = Color3.fromRGB(50, 180, 80)
local COLOR_XP_BG = Color3.fromRGB(40, 40, 45)
local TWEEN_HOVER = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_PANEL = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_XP_BAR = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_LEVEL_FLASH = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

----- Noms + emojis des graines -----
local SEED_DISPLAY = {
	Ble = { name = "Blé", emoji = "🌾" },
	Carotte = { name = "Carotte", emoji = "🥕" },
	Tomate = { name = "Tomate", emoji = "🍅" },
	Magique = { name = "Magique", emoji = "✨" },
}

local FIXED_SEED_ORDER = { "Ble", "Carotte", "Tomate", "Magique" }

local function addCorner(parent, radiusScale)
	local c = Instance.new("UICorner")
	-- radiusScale peut être un nombre (pixels) ou 1 pour pilule (UDim.new(1,0))
	c.CornerRadius = type(radiusScale) == "number" and radiusScale >= 2
		and UDim.new(0, radiusScale)
		or UDim.new(1, 0)
	c.Parent = parent
	return c
end

----- Root -----
local mainHUD = Instance.new("ScreenGui")
mainHUD.Name = "MainHUD"
mainHUD.ResetOnSpawn = false
mainHUD.IgnoreGuiInset = true
mainHUD.Parent = playerGui

-- ========== 1. Barre Pièces + Niveau (en haut à droite) ==========
local topRightContainer = Instance.new("Frame")
topRightContainer.Name = "TopRightBar"
topRightContainer.AnchorPoint = Vector2.new(1, 0)
topRightContainer.Position = UDim2.new(1, -12, 0, 12)
topRightContainer.Size = UDim2.new(0, 0, 0, 0)
topRightContainer.AutomaticSize = Enum.AutomaticSize.XY
topRightContainer.BackgroundTransparency = 1
topRightContainer.Parent = mainHUD

local topRightLayout = Instance.new("UIListLayout")
topRightLayout.FillDirection = Enum.FillDirection.Vertical
topRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
topRightLayout.VerticalAlignment = Enum.VerticalAlignment.Top
topRightLayout.Padding = UDim.new(0, 6)
topRightLayout.Parent = topRightContainer

-- Ligne 1 : pills (Pièces + Niveau) en horizontal
local pillsRow = Instance.new("Frame")
pillsRow.Name = "PillsRow"
pillsRow.Size = UDim2.new(0, 0, 0, 36)
pillsRow.AutomaticSize = Enum.AutomaticSize.X
pillsRow.BackgroundTransparency = 1
pillsRow.Parent = topRightContainer

local pillsLayout = Instance.new("UIListLayout")
pillsLayout.FillDirection = Enum.FillDirection.Horizontal
pillsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
pillsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
pillsLayout.Padding = UDim.new(0, 8)
pillsLayout.Parent = pillsRow

-- Pill Pièces
local pillPieces = Instance.new("Frame")
pillPieces.Name = "PillPieces"
pillPieces.Size = UDim2.new(0, 110, 0, 36)
pillPieces.BackgroundColor3 = COLOR_PILL_BG
pillPieces.BackgroundTransparency = 0.15
pillPieces.BorderSizePixel = 0
pillPieces.Parent = pillsRow
addCorner(pillPieces, 1) -- 1 = pilule (UDim 1,0)
local strokePieces = Instance.new("UIStroke")
strokePieces.Color = COLOR_GOLD
strokePieces.Thickness = 1
strokePieces.Parent = pillPieces
local piecesLabel = Instance.new("TextLabel")
piecesLabel.Name = "Pieces"
piecesLabel.Size = UDim2.new(1, -12, 1, 0)
piecesLabel.Position = UDim2.new(0, 6, 0, 0)
piecesLabel.BackgroundTransparency = 1
piecesLabel.Font = Enum.Font.GothamBold
piecesLabel.Text = "💰 0"
piecesLabel.TextColor3 = COLOR_GOLD
piecesLabel.TextSize = 14
piecesLabel.TextXAlignment = Enum.TextXAlignment.Center
piecesLabel.Parent = pillPieces

-- Pill Niveau
local pillNiveau = Instance.new("Frame")
pillNiveau.Name = "PillNiveau"
pillNiveau.Size = UDim2.new(0, 110, 0, 36)
pillNiveau.BackgroundColor3 = COLOR_PILL_BG
pillNiveau.BackgroundTransparency = 0.15
pillNiveau.BorderSizePixel = 0
pillNiveau.Parent = pillsRow
addCorner(pillNiveau, 1)
local strokeNiveau = Instance.new("UIStroke")
strokeNiveau.Color = COLOR_VIOLET
strokeNiveau.Thickness = 1
strokeNiveau.Parent = pillNiveau
local nivLabel = Instance.new("TextLabel")
nivLabel.Name = "Niveau"
nivLabel.Size = UDim2.new(1, -12, 1, 0)
nivLabel.Position = UDim2.new(0, 6, 0, 0)
nivLabel.BackgroundTransparency = 1
nivLabel.Font = Enum.Font.GothamBold
nivLabel.Text = "⭐ Niv. 1"
nivLabel.TextColor3 = COLOR_VIOLET
nivLabel.TextSize = 14
nivLabel.TextXAlignment = Enum.TextXAlignment.Center
nivLabel.Parent = pillNiveau

-- Barre XP (220x14) sous les pills
local xpBarContainer = Instance.new("Frame")
xpBarContainer.Name = "XPBarContainer"
xpBarContainer.Size = UDim2.new(0, 220, 0, 14)
xpBarContainer.BackgroundColor3 = COLOR_XP_BG
xpBarContainer.BackgroundTransparency = 0.2
xpBarContainer.BorderSizePixel = 0
xpBarContainer.Parent = topRightContainer
addCorner(xpBarContainer, 4)

local xpBarFill = Instance.new("Frame")
xpBarFill.Name = "XPBarFill"
xpBarFill.Size = UDim2.new(0, 0, 1, 0)
xpBarFill.Position = UDim2.new(0, 0, 0, 0)
xpBarFill.AnchorPoint = Vector2.new(0, 0)
xpBarFill.BackgroundColor3 = COLOR_XP_BAR
xpBarFill.BorderSizePixel = 0
xpBarFill.Parent = xpBarContainer
addCorner(xpBarFill, 4)

local xpBarLabel = Instance.new("TextLabel")
xpBarLabel.Name = "XPBarLabel"
xpBarLabel.Size = UDim2.new(1, 0, 1, 0)
xpBarLabel.Position = UDim2.new(0, 0, 0, 0)
xpBarLabel.BackgroundTransparency = 1
xpBarLabel.Font = Enum.Font.GothamBold
xpBarLabel.Text = "Niv. 1 — 0/100"
xpBarLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
xpBarLabel.TextSize = 11
xpBarLabel.TextXAlignment = Enum.TextXAlignment.Center
xpBarLabel.TextYAlignment = Enum.TextYAlignment.Center
xpBarLabel.Parent = xpBarContainer

local function updateXPBar(xp, xpMax, niveauTotal)
	local xpVal = type(xp) == "number" and xp or 0
	local maxVal = type(xpMax) == "number" and xpMax > 0 and xpMax or 100
	local niv = type(niveauTotal) == "number" and niveauTotal or 1
	local ratio = math.clamp(xpVal / maxVal, 0, 1)
	xpBarLabel.Text = string.format("Niv. %d — %d/%d", niv, xpVal, maxVal)
	TweenService:Create(xpBarFill, TWEEN_XP_BAR, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
end

local function updateVital(pieces, niveau)
	piecesLabel.Text = "💰 " .. tostring(pieces or 0)
	nivLabel.Text = "⭐ Niv. " .. tostring(niveau or 1)
end

-- Bouton Sac (juste en dessous)
local invButton = Instance.new("TextButton")
invButton.Name = "InventoryButton"
invButton.Size = UDim2.new(0, 110, 0, 34)
invButton.BackgroundColor3 = COLOR_PILL_BG
invButton.BackgroundTransparency = 0.15
invButton.Text = "🎒 Inventaire"
invButton.TextColor3 = COLOR_GOLD
invButton.TextSize = 13
invButton.Font = Enum.Font.GothamBold
invButton.BorderSizePixel = 0
invButton.Parent = topRightContainer
addCorner(invButton, 1)
local strokeInvBtn = Instance.new("UIStroke")
strokeInvBtn.Color = Color3.fromRGB(80, 80, 95)
strokeInvBtn.Thickness = 1
strokeInvBtn.Parent = invButton

invButton.MouseEnter:Connect(function()
	TweenService:Create(invButton, TWEEN_HOVER, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(strokeInvBtn, TWEEN_HOVER, { Color = COLOR_GOLD }):Play()
end)
invButton.MouseLeave:Connect(function()
	TweenService:Create(invButton, TWEEN_HOVER, { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(strokeInvBtn, TWEEN_HOVER, { Color = Color3.fromRGB(80, 80, 95) }):Play()
end)

-- ========== 2. Panneau Inventaire (grille 90x90, cartes graines) ==========
local invPanel = Instance.new("Frame")
invPanel.Name = "InventoryPanel"
invPanel.AnchorPoint = Vector2.new(1, 0)
invPanel.Position = UDim2.new(1, 12, 0, 12)
invPanel.Size = UDim2.new(0, 210, 0, 0)
invPanel.AutomaticSize = Enum.AutomaticSize.Y
invPanel.BackgroundColor3 = COLOR_BG_DARK
invPanel.BackgroundTransparency = 0.1
invPanel.BorderSizePixel = 0
invPanel.Visible = false
invPanel.Parent = mainHUD
addCorner(invPanel, 10)
local invPanelStroke = Instance.new("UIStroke")
invPanelStroke.Color = COLOR_CARD_STROKE
invPanelStroke.Thickness = 1
invPanelStroke.Parent = invPanel

local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, -16, 0, 36)
invTitle.Position = UDim2.new(0, 8, 0, 6)
invTitle.BackgroundTransparency = 1
invTitle.Font = Enum.Font.GothamBold
invTitle.Text = "🎒 Inventaire"
invTitle.TextColor3 = COLOR_GOLD
invTitle.TextSize = 16
invTitle.TextXAlignment = Enum.TextXAlignment.Left
invTitle.Parent = invPanel

-- Conteneur grille (2 colonnes, cellules 90x90, padding 8)
local invList = Instance.new("Frame")
invList.Name = "List"
invList.Size = UDim2.new(1, -16, 0, 0)
invList.Position = UDim2.new(0, 8, 0, 44)
invList.AutomaticSize = Enum.AutomaticSize.Y
invList.BackgroundTransparency = 1
invList.Parent = invPanel

local invGrid = Instance.new("UIGridLayout")
invGrid.CellSize = UDim2.new(0, 90, 0, 90)
invGrid.CellPadding = UDim2.new(0, 8, 0, 8)
invGrid.SortOrder = Enum.SortOrder.LayoutOrder
invGrid.Parent = invList

local invPadding = Instance.new("UIPadding")
invPadding.PaddingBottom = UDim.new(0, 10)
invPadding.Parent = invList

local PANEL_OPEN_OFFSET = -12
local PANEL_CLOSED_OFFSET = 240
local invPanelOpen = false

local function setInvPanelOpen(open)
	if invPanelOpen == open then return end
	invPanelOpen = open
	invPanel.Visible = true
	local goalPos = open
		and UDim2.new(1, PANEL_OPEN_OFFSET, 0, 12)
		or UDim2.new(1, PANEL_CLOSED_OFFSET, 0, 12)
	TweenService:Create(invPanel, TWEEN_PANEL, { Position = goalPos }):Play()
	if not open then
		task.delay(TWEEN_PANEL.Time + 0.05, function()
			if invPanel and invPanel.Parent then
				invPanel.Visible = false
			end
		end)
	end
end

invButton.MouseButton1Click:Connect(function()
	setInvPanelOpen(not invPanelOpen)
end)

-- Création d'une carte graine : emoji haut, nom milieu, quantité bas (or ou gris si 0)
local function createOneCard(key, qty, layoutOrder)
	local num = (qty == nil or type(qty) ~= "number") and 0 or qty
	local info = SEED_DISPLAY[key] or { name = tostring(key), emoji = "?" }
	local card = Instance.new("Frame")
	card.Name = "Card_" .. key
	card.Size = UDim2.new(0, 90, 0, 90)
	card.BackgroundColor3 = COLOR_CARD_BG
	card.BackgroundTransparency = (num == 0) and 0.6 or 0
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = invList
	addCorner(card, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLOR_CARD_STROKE
	stroke.Thickness = 1
	stroke.Transparency = (num == 0) and 0.5 or 0
	stroke.Parent = card

	local cardLayout = Instance.new("UIListLayout")
	cardLayout.FillDirection = Enum.FillDirection.Vertical
	cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	cardLayout.Padding = UDim.new(0, 2)
	cardLayout.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = card

	-- Haut : emoji
	local emojiLabel = Instance.new("TextLabel")
	emojiLabel.Size = UDim2.new(1, 0, 0, 24)
	emojiLabel.BackgroundTransparency = 1
	emojiLabel.Font = Enum.Font.GothamBold
	emojiLabel.Text = info.emoji
	emojiLabel.TextColor3 = (num == 0) and COLOR_QTY_ZERO or Color3.fromRGB(255, 255, 255)
	emojiLabel.TextSize = 18
	emojiLabel.Parent = card

	-- Milieu : nom
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = info.name
	nameLabel.TextColor3 = (num == 0) and COLOR_QTY_ZERO or Color3.fromRGB(220, 220, 230)
	nameLabel.TextSize = 11
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	-- Bas : quantité en gras
	local qtyLabel = Instance.new("TextLabel")
	qtyLabel.Name = "Qty"
	qtyLabel.Size = UDim2.new(1, 0, 0, 18)
	qtyLabel.BackgroundTransparency = 1
	qtyLabel.Font = Enum.Font.GothamBold
	qtyLabel.Text = "x " .. tostring(num)
	qtyLabel.TextColor3 = (num == 0) and COLOR_QTY_ZERO or COLOR_QTY_OR
	qtyLabel.TextSize = 12
	qtyLabel.Parent = card
end

local function rebuildInventorySlots(inventaireGraines)
	for _, child in ipairs(invList:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Card_") then
			child:Destroy()
		end
	end
	local inv = type(inventaireGraines) == "table" and inventaireGraines or {}
	for idx, key in ipairs(FIXED_SEED_ORDER) do
		local qty = inv[key]
		if qty == nil or type(qty) ~= "number" then qty = 0 end
		createOneCard(key, qty, idx)
	end
end

invPanel.Position = UDim2.new(1, PANEL_CLOSED_OFFSET, 0, 12)

-- ========== Événements serveur ==========
local playerDataUpdated = ReplicatedStorage:WaitForChild("PlayerDataUpdated") :: RemoteEvent
playerDataUpdated.OnClientEvent:Connect(function(pieces, niveau, xp, xpMax, niveauTotal)
	updateVital(pieces, niveau)
	if xp ~= nil and xpMax ~= nil and niveauTotal ~= nil then
		updateXPBar(xp, xpMax, niveauTotal)
	end
end)

local playerLevelUp = ReplicatedStorage:FindFirstChild("PlayerLevelUp")
if playerLevelUp then
	playerLevelUp.OnClientEvent:Connect(function(newLevel)
		-- Flash doré 0.5s sur la barre XP
		TweenService:Create(xpBarContainer, TWEEN_LEVEL_FLASH, { BackgroundColor3 = COLOR_GOLD }):Play()
		TweenService:Create(xpBarFill, TWEEN_LEVEL_FLASH, { BackgroundColor3 = Color3.fromRGB(255, 255, 200) }):Play()
		task.delay(0.5, function()
			if xpBarContainer and xpBarContainer.Parent then
				TweenService:Create(xpBarContainer, TWEEN_LEVEL_FLASH, { BackgroundColor3 = COLOR_XP_BG }):Play()
			end
			if xpBarFill and xpBarFill.Parent then
				TweenService:Create(xpBarFill, TWEEN_LEVEL_FLASH, { BackgroundColor3 = COLOR_XP_BAR }):Play()
			end
		end)
	end)
end

local seedInventoryUpdated = ReplicatedStorage:FindFirstChild("SeedInventoryUpdated")
if seedInventoryUpdated then
	seedInventoryUpdated.OnClientEvent:Connect(function(inventaireGraines)
		rebuildInventorySlots(inventaireGraines)
	end)
end

updateVital(0, 1)
