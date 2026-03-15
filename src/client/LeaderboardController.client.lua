--[[
	LeaderboardController.client.lua — Interface du leaderboard côté client
	Toggle button 🏆 + Panneau Top 5 avec animations TweenService.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local leaderboardUpdatedEvent = ReplicatedStorage:WaitForChild("LeaderboardUpdated")

----- Constantes visuelles -----

local TOGGLE_BUTTON_SIZE = UDim2.new(0, 44, 0, 44)
local TOGGLE_BUTTON_POS = UDim2.new(0, 12, 0, 12)
local PANEL_SIZE = UDim2.new(0, 280, 0, 240)
local PANEL_POS = UDim2.new(0, 12, 0, 62)

local BACKGROUND_COLOR = Color3.fromRGB(12, 12, 20)
local GOLD_COLOR = Color3.fromRGB(255, 215, 0)
local TEXT_WHITE = Color3.fromRGB(255, 255, 255)
local HIGHLIGHT_GOLD = Color3.fromRGB(50, 45, 15) -- Fond doré léger pour le joueur local

local MEDALS = { "🥇", "🥈", "🥉", "4️⃣", "5️⃣" }
local LINE_COLORS = {
	Color3.fromRGB(40, 40, 50),  -- Gris foncé
	Color3.fromRGB(35, 35, 45),  -- Gris plus foncé
}

----- Créer l'écran ScreenGui -----

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LeaderboardGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

----- Créer le bouton Toggle -----

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "LeaderboardToggle"
toggleButton.Size = TOGGLE_BUTTON_SIZE
toggleButton.Position = TOGGLE_BUTTON_POS
toggleButton.BackgroundColor3 = BACKGROUND_COLOR
toggleButton.TextColor3 = GOLD_COLOR
toggleButton.TextSize = 28
toggleButton.Text = "🏆"
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = GOLD_COLOR
toggleStroke.Thickness = 2
toggleStroke.Parent = toggleButton

----- Créer le panneau Leaderboard -----

local leaderboardPanel = Instance.new("Frame")
leaderboardPanel.Name = "LeaderboardPanel"
leaderboardPanel.Size = PANEL_SIZE
leaderboardPanel.Position = PANEL_POS
leaderboardPanel.BackgroundColor3 = BACKGROUND_COLOR
leaderboardPanel.Visible = false
leaderboardPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = leaderboardPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = GOLD_COLOR
panelStroke.Thickness = 1.5
panelStroke.Parent = leaderboardPanel

----- Titre du leaderboard -----

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -10, 0, 35)
titleLabel.Position = UDim2.new(0, 5, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = GOLD_COLOR
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "🏆 Top Joueurs"
titleLabel.Parent = leaderboardPanel

----- Container pour les lignes du classement -----

local linesContainer = Instance.new("Frame")
linesContainer.Name = "LinesContainer"
linesContainer.Size = UDim2.new(1, -10, 1, -45)
linesContainer.Position = UDim2.new(0, 5, 0, 40)
linesContainer.BackgroundTransparency = 1
linesContainer.Parent = leaderboardPanel

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = linesContainer

----- Fonction pour créer une ligne de classement -----

local function createLeaderboardLine(rank, playerName, pieces, niveau, isLocalPlayer)
	local lineFrame = Instance.new("Frame")
	lineFrame.Name = "Line" .. rank
	lineFrame.Size = UDim2.new(1, 0, 0, 32)
	lineFrame.BackgroundColor3 = LINE_COLORS[((rank - 1) % 2) + 1]
	lineFrame.Parent = linesContainer

	local lineCorner = Instance.new("UICorner")
	lineCorner.CornerRadius = UDim.new(0, 6)
	lineCorner.Parent = lineFrame

	-- Surligner le joueur local
	if isLocalPlayer then
		lineFrame.BackgroundColor3 = HIGHLIGHT_GOLD
	end

	----- Médaille + Nom -----

	local medalLabel = Instance.new("TextLabel")
	medalLabel.Name = "Medal"
	medalLabel.Size = UDim2.new(0, 30, 1, 0)
	medalLabel.Position = UDim2.new(0, 2, 0, 0)
	medalLabel.BackgroundTransparency = 1
	medalLabel.TextColor3 = TEXT_WHITE
	medalLabel.TextSize = 16
	medalLabel.Font = Enum.Font.GothamBold
	medalLabel.Text = MEDALS[rank]
	medalLabel.Parent = lineFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(0, 100, 1, 0)
	nameLabel.Position = UDim2.new(0, 35, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = TEXT_WHITE
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = playerName
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = lineFrame

	----- Pièces (🪙 X) -----

	local piecesLabel = Instance.new("TextLabel")
	piecesLabel.Name = "Pieces"
	piecesLabel.Size = UDim2.new(0, 60, 1, 0)
	piecesLabel.Position = UDim2.new(0, 140, 0, 0)
	piecesLabel.BackgroundTransparency = 1
	piecesLabel.TextColor3 = GOLD_COLOR
	piecesLabel.TextSize = 12
	piecesLabel.Font = Enum.Font.Gotham
	piecesLabel.Text = "🪙 " .. tostring(pieces)
	piecesLabel.TextXAlignment = Enum.TextXAlignment.Right
	piecesLabel.Parent = lineFrame

	----- Niveau (Niv.X) -----

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "Level"
	levelLabel.Size = UDim2.new(0, 50, 1, 0)
	levelLabel.Position = UDim2.new(0, 205, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.TextColor3 = TEXT_WHITE
	levelLabel.TextSize = 12
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.Text = "Niv." .. tostring(niveau)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Right
	levelLabel.Parent = lineFrame
end

----- Fonction pour reconstruire l'UI avec les nouvelles données -----

local function updateLeaderboard(top5Table)
	-- Vider les lignes précédentes
	for _, child in pairs(linesContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Line") then
			child:Destroy()
		end
	end

	-- Créer les nouvelles lignes
	for rank, playerData in ipairs(top5Table) do
		local isLocalPlayer = (playerData.name == localPlayer.Name)
		createLeaderboardLine(rank, playerData.name, playerData.pieces, playerData.niveau, isLocalPlayer)
	end
end

----- Animations TweenService pour Slide in/out -----

local function slideIn()
	local tweenInfo = TweenInfo.new(
		0.3,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(leaderboardPanel, tweenInfo, { Position = PANEL_POS })
	tween:Play()
end

local function slideOut()
	local tweenInfo = TweenInfo.new(
		0.3,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)
	local targetPos = UDim2.new(0, 12, 0, -250) -- Hors de l'écran vers le haut
	local tween = TweenService:Create(leaderboardPanel, tweenInfo, { Position = targetPos })
	tween:Play()
end

----- État du panel -----

local isPanelOpen = false

toggleButton.MouseButton1Click:Connect(function()
	isPanelOpen = not isPanelOpen

	if isPanelOpen then
		leaderboardPanel.Visible = true
		slideIn()
	else
		slideOut()
		task.wait(0.3)
		leaderboardPanel.Visible = false
	end
end)

----- Écouter les mises à jour du leaderboard -----

leaderboardUpdatedEvent.OnClientEvent:Connect(function(top5Table)
	updateLeaderboard(top5Table)
	print("[LeaderboardController] ✅ Leaderboard mis à jour avec", #top5Table, "joueurs")
end)

print("✅ [LeaderboardController] Contrôleur leaderboard initialisé")
