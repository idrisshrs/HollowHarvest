--[[
	PrestigeController.client.lua — Affiche la notification globale quand un joueur atteint un prestige.
	Animation : Slide du haut vers le bas (0.5s), reste 4s, puis repart.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Attendre le RemoteEvent
local playerPrestigedEvent = ReplicatedStorage:WaitForChild("PlayerPrestiged")

----- Fonction pour afficher la notification -----

local function showPrestigeNotification(data)
	if not data or not data.name then
		return
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PrestigeNotification"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Banneau (Frame) — commence hors écran en haut
	local banner = Instance.new("Frame")
	banner.Name = "PrestigeBanner"
	banner.Size = UDim2.new(1, 0, 0, 80)
	banner.Position = UDim2.new(0, 0, 0, -80)  -- Hors écran vers le haut
	banner.BackgroundColor3 = Color3.fromRGB(150, 100, 180)  -- Violet
	banner.BorderSizePixel = 0
	banner.ZIndex = 100
	banner.Parent = screenGui

	-- Dégradé (UIGradient) : violet → violet foncé
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 120, 220)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 80, 160)),
	})
	gradient.Rotation = 90
	gradient.Parent = banner

	-- Texte du banneau
	local text = Instance.new("TextLabel")
	text.Name = "PrestigeText"
	text.Size = UDim2.new(1, -24, 1, 0)
	text.Position = UDim2.new(0, 12, 0, 0)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextSize = 28
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextScaled = false
	text.Text = "✨ " .. data.name .. " a atteint le Prestige #" .. data.prestiges .. " ! ✨"
	text.Parent = banner

	-- Animation : Slide du haut vers le bas (0.5s)
	local slideDownInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	local slideDownTween = TweenService:Create(banner, slideDownInfo, {
		Position = UDim2.new(0, 0, 0, 0)  -- Position finale (dans l'écran)
	})
	slideDownTween:Play()

	-- Rester 4 secondes
	task.wait(4)

	-- Animation : Slide vers le haut (0.5s)
	local slideUpInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)
	local slideUpTween = TweenService:Create(banner, slideUpInfo, {
		Position = UDim2.new(0, 0, 0, -80)  -- Hors écran vers le haut
	})
	slideUpTween:Play()

	-- Attendre la fin de l'animation et détruire
	slideUpTween.Completed:Connect(function()
		screenGui:Destroy()
	end)
end

----- Écouter l'événement PlayerPrestiged -----

playerPrestigedEvent.OnClientEvent:Connect(function(data)
	showPrestigeNotification(data)
end)

print("[PrestigeController] Service de notification de prestige activé")
