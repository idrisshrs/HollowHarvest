local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local dailyRewardClaimedEvent = ReplicatedStorage:WaitForChild("DailyRewardClaimed")

local popup

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════

-- Crée les confettis dorés à la position du joueur
local function spawnConfetti()
	-- Proteger contre les erreurs : le joueur doit avoir un Character
	if not player.Character or not player.Character:FindFirstChild("Head") then
		print("⚠️ Character pas trouvé pour les confettis")
		return
	end

	local spawnPos = player.Character.Head.Position + Vector3.new(0, 2, 0)
	
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = spawnPos
	part.Parent = workspace

	local att = Instance.new("Attachment")
	att.Parent = part

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Gold
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Speed = NumberRange.new(15, 25)
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.RotSpeed = NumberRange.new(-120, 120)
	emitter.Rate = 0
	emitter.Parent = att
	emitter:Emit(20)

	task.delay(3.5, function()
		if part and part.Parent then
			part:Destroy()
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- UI CREATION
-- ═══════════════════════════════════════════════════════════

local function createPopup()
	popup = Instance.new("ScreenGui")
	popup.Name = "DailyRewardPopup"
	popup.Parent = playerGui
	popup.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(0.6, 0, 0.7, 0)
	background.Position = UDim2.new(0.5, 0, 0.5, 0)
	background.AnchorPoint = Vector2.new(0.5, 0.5)
	background.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	background.BackgroundTransparency = 0.2
	background.BorderSizePixel = 0
	background.Parent = popup

	-- UIScale for elastic animation
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0.5 -- Start smaller for animation
	uiScale.Parent = background

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = background

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(212, 175, 55) -- Gold color
	stroke.Thickness = 3
	stroke.Parent = background

	-- Icon (Coin emoji 🪙)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0.3, 0, 0.2, 0)
	iconLabel.Position = UDim2.new(0.5, 0, 0.12, 0)
	iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "🪙"
	iconLabel.TextScaled = true
	iconLabel.TextWrapped = true
	iconLabel.Font = Enum.Font.Gotham
	iconLabel.Parent = background

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.9, 0, 0.1, 0)
	title.Position = UDim2.new(0.5, 0, 0.22, 0)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.BackgroundTransparency = 1
	title.Text = "Récompense Journalière !"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextWrapped = true
	title.Parent = background

	-- Description container for better text hierarchy
	local descriptionContainer = Instance.new("Frame")
	descriptionContainer.Name = "DescriptionContainer"
	descriptionContainer.Size = UDim2.new(0.85, 0, 0.35, 0)
	descriptionContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
	descriptionContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	descriptionContainer.BackgroundTransparency = 1
	descriptionContainer.Parent = background

	local receivedLabel = Instance.new("TextLabel")
	receivedLabel.Name = "ReceivedLabel"
	receivedLabel.Size = UDim2.new(1, 0, 0.4, 0)
	receivedLabel.Position = UDim2.new(0, 0, 0, 0)
	receivedLabel.AnchorPoint = Vector2.new(0, 0)
	receivedLabel.BackgroundTransparency = 1
	receivedLabel.Text = "Vous avez reçu"
	receivedLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	receivedLabel.Font = Enum.Font.Gotham
	receivedLabel.TextSize = 16
	receivedLabel.TextWrapped = true
	receivedLabel.Parent = descriptionContainer

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Name = "RewardLabel"
	rewardLabel.Size = UDim2.new(1, 0, 0.5, 0)
	rewardLabel.Position = UDim2.new(0, 0, 0.45, 0)
	rewardLabel.AnchorPoint = Vector2.new(0, 0)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = ""
	rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.TextScaled = true
	rewardLabel.TextWrapped = true
	rewardLabel.Parent = descriptionContainer

	local itemsLabel = Instance.new("TextLabel")
	itemsLabel.Name = "ItemsLabel"
	itemsLabel.Size = UDim2.new(1, 0, 0.4, 0)
	itemsLabel.Position = UDim2.new(0, 0, 0.5, 0)
	itemsLabel.AnchorPoint = Vector2.new(0, 0)
	itemsLabel.BackgroundTransparency = 1
	itemsLabel.Text = ""
	itemsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	itemsLabel.Font = Enum.Font.Gotham
	itemsLabel.TextSize = 14
	itemsLabel.TextWrapped = true
	itemsLabel.Parent = descriptionContainer

	local claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0.4, 0, 0.1, 0)
	claimButton.Position = UDim2.new(0.5, 0, 0.85, 0)
	claimButton.AnchorPoint = Vector2.new(0.5, 0.5)
	claimButton.BackgroundColor3 = Color3.fromRGB(85, 170, 0)
	claimButton.Text = "Récupérer !"
	claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimButton.Font = Enum.Font.GothamBold
	claimButton.TextScaled = true
	claimButton.TextWrapped = true
	claimButton.Parent = background

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = claimButton

	-- Shine effect frame (invisible, will be animated)
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.new(0.2, 0, 2, 0)
	shine.Position = UDim2.new(-0.1, 0, -0.5, 0)
	shine.AnchorPoint = Vector2.new(0, 0.5)
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.7
	shine.BorderSizePixel = 0
	shine.Rotation = 20
	shine.Parent = claimButton

	local shineCorner = Instance.new("UICorner")
	shineCorner.CornerRadius = UDim.new(0, 5)
	shineCorner.Parent = shine

	return background, rewardLabel, itemsLabel, claimButton, shine, iconLabel, receivedLabel, uiScale, stroke, title, descriptionContainer
end

local function animateShine(shineFrame)
	while shineFrame and shineFrame.Parent do
		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		local tween = TweenService:Create(shineFrame, tweenInfo, {Position = UDim2.new(1.1, 0, -0.5, 0)})
		tween:Play()
		tween.Completed:Wait()
		if shineFrame and shineFrame.Parent then
			shineFrame.Position = UDim2.new(-0.1, 0, -0.5, 0)
		end
	end
end

-- ═══════════════════════════════════════════════════════════

local function showPopup(streak, pieces, items)
	local background, rewardLabel, itemsLabel, claimButton, shine, iconLabel, receivedLabel, uiScale, stroke, title, descriptionContainer = createPopup()

	-- Set reward amount (Jour X : Y pièces)
	rewardLabel.Text = string.format("Jour %d : %d pièces", streak, pieces)

	local itemText = ""
	for item, amount in pairs(items) do
		itemText ..= string.format("%s x%d, ", item, amount)
	end
	if #itemText > 0 then
		itemText = itemText:sub(1, #itemText - 2)
		itemsLabel.Text = "Objets : " .. itemText
	end

	-- PARTIE 2 : Animations d'apparition (Elastic/Back)
	local tweenInfo = TweenInfo.new(
		0.7,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(uiScale, tweenInfo, {
		Scale = 1.0
	})
	tween:Play()

	-- PARTIE 3 : Lancer les confettis (robuste avec pcall)
	task.spawn(function()
		pcall(function()
			spawnConfetti()
		end)
	end)

	-- Animation shine en loop
	task.spawn(function()
		animateShine(shine)
	end)

	claimButton.MouseButton1Click:Connect(function()
		print("🎉 Bouton Récupérer cliqué !")
		-- Désactiver le bouton pour éviter les clics multiples
		claimButton.Active = false

		-- Effect "Squish" : compression légère via UIScale
		local squishInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		local squish = TweenService:Create(uiScale, squishInfo, {
			Scale = 0.85
		})
		squish:Play()
		squish.Completed:Wait()

		print("🎉 Squish terminé, lancement du fade...")

		-- Disparition en fondu (transparency)
		local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		
		-- Fade background
		local fadeBackgroundTween = TweenService:Create(background, fadeInfo, {BackgroundTransparency = 1})
		
		-- Fade stroke
		local fadeStrokeTween = TweenService:Create(stroke, fadeInfo, {Transparency = 1})
		
		-- Fade all text labels
		local fadeIconTween = TweenService:Create(iconLabel, fadeInfo, {TextTransparency = 1})
		local fadeTitleTween = TweenService:Create(title, fadeInfo, {TextTransparency = 1})
		local fadeReceivedTween = TweenService:Create(receivedLabel, fadeInfo, {TextTransparency = 1})
		local fadeRewardTween = TweenService:Create(rewardLabel, fadeInfo, {TextTransparency = 1})
		local fadeItemsTween = TweenService:Create(itemsLabel, fadeInfo, {TextTransparency = 1})
		local fadeButtonTween = TweenService:Create(claimButton, fadeInfo, {TextTransparency = 1, BackgroundTransparency = 1})

		fadeBackgroundTween:Play()
		fadeStrokeTween:Play()
		fadeIconTween:Play()
		fadeTitleTween:Play()
		fadeReceivedTween:Play()
		fadeRewardTween:Play()
		fadeItemsTween:Play()
		fadeButtonTween:Play()

		fadeBackgroundTween.Completed:Wait()
		print("🎉 Fade terminé, destruction de la popup...")
		popup:Destroy()
		popup = nil
		print("✅ Popup détruite avec succès !")
	end)
end

dailyRewardClaimedEvent.OnClientEvent:Connect(showPopup)
