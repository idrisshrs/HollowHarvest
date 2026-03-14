--[[
	HUDController — Affiche Pièces et Niveau du joueur (UI créée en script).
	Reçoit les données du serveur via le RemoteEvent PlayerDataUpdated (pas de confiance client).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----- Création du MainHUD (Programmatic UI) -----

local mainHUD = Instance.new("ScreenGui")
mainHUD.Name = "MainHUD"
mainHUD.ResetOnSpawn = false
mainHUD.IgnoreGuiInset = true
mainHUD.Parent = playerGui

----- Couleurs (thème sombre, or pour pièces, violet pour niveau) -----

local colorBgDark = Color3.fromRGB(28, 30, 38)
local colorGold = Color3.fromRGB(245, 200, 80)
local colorBgViolet = Color3.fromRGB(38, 34, 58)
local colorViolet = Color3.fromRGB(180, 160, 255)
local colorWhite = Color3.fromRGB(255, 255, 255)

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createPanel(name, positionX, sizeX, bgColor, labelText, labelColor)
	local frame = Instance.new("Frame")
	frame.Name = name .. "Panel"
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Position = UDim2.new(0, positionX, 1, -24)
	frame.Size = UDim2.new(0, sizeX, 0, 52)
	frame.BackgroundColor3 = bgColor
	frame.BorderSizePixel = 0
	frame.Parent = mainHUD

	addCorner(frame, 10)

	local label = Instance.new("TextLabel")
	label.Name = name .. "Label"
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 14, 0.5, 0)
	label.Size = UDim2.new(0, 80, 0, 24)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = labelText
	label.TextColor3 = labelColor
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = name .. "Value"
	valueLabel.AnchorPoint = Vector2.new(1, 0.5)
	valueLabel.Position = UDim2.new(1, -14, 0.5, 0)
	valueLabel.Size = UDim2.new(0, 100, 0, 28)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = "0"
	valueLabel.TextColor3 = colorWhite
	valueLabel.TextSize = 20
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = frame

	return valueLabel
end

local piecesValueLabel = createPanel("Pieces", 24, 200, colorBgDark, "Pieces", colorGold)
local niveauValueLabel = createPanel("Niveau", 236, 120, colorBgViolet, "Niv.", colorViolet)

----- Valeurs par défaut -----

piecesValueLabel.Text = "0"
niveauValueLabel.Text = "1"

----- Mise à jour de l'affichage -----

local function updateHUD(pieces, niveau)
	piecesValueLabel.Text = tostring(pieces)
	niveauValueLabel.Text = tostring(niveau)
end

----- Écouter les mises à jour envoyées par le serveur -----

local playerDataUpdated = ReplicatedStorage:WaitForChild("PlayerDataUpdated") :: RemoteEvent
playerDataUpdated.OnClientEvent:Connect(function(pieces, niveau)
	updateHUD(pieces, niveau)
end)
