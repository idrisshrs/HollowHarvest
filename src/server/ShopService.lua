local ShopService = {}
local DataService = require(script.Parent.DataService)

function ShopService.start()
    local shopPart = workspace:WaitForChild("ShopPart", 10)
    if not shopPart then return end

    local prompt = shopPart:WaitForChild("ProximityPrompt")
    prompt.Triggered:Connect(function(player)
        ShopService.openShop(player)
    end)
end

function ShopService.openShop(player)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui or playerGui:FindFirstChild("ShopGUI") then return end

    -- Création du Menu
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopGUI"
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 320) -- J'ai agrandi le menu
    frame.Position = UDim2.new(0.5, -175, 0.5, -160)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Text = "🏪 BOUTIQUE SECRÈTE"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Parent = frame

    -- BOUTON 1 : NIVEAU
    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(0.8, 0, 0, 50)
    buyButton.Position = UDim2.new(0.1, 0, 0.25, 0)
    buyButton.Text = "Acheter un Niveau (50 Pièces)"
    buyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.Font = Enum.Font.GothamBold
    buyButton.TextSize = 18
    buyButton.Parent = frame

    -- BOUTON 2 : GRAINE RARE (NOUVEAU)
    local seedButton = Instance.new("TextButton")
    seedButton.Size = UDim2.new(0.8, 0, 0, 50)
    seedButton.Position = UDim2.new(0.1, 0, 0.50, 0)
    seedButton.Text = "Graine Rare (100 Pièces)"
    seedButton.BackgroundColor3 = Color3.fromRGB(150, 50, 200) -- Violet Épique
    seedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    seedButton.Font = Enum.Font.GothamBold
    seedButton.TextSize = 18
    seedButton.Parent = frame

    -- BOUTON FERMER
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.8, 0, 0, 40)
    closeButton.Position = UDim2.new(0.1, 0, 0.75, 0)
    closeButton.Text = "Fermer"
    closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.Parent = frame

    -- LOGIQUE FERMETURE
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- LOGIQUE NIVEAU
    buyButton.MouseButton1Click:Connect(function()
        local data = DataService.getData(player)
        if data and data.Pieces >= 50 then
            data.Pieces = data.Pieces - 50
            data.Niveau = data.Niveau + 1
            DataService.replicateToClient(player)
            buyButton.Text = "✅ Niveau Supérieur !"
            task.wait(1)
            buyButton.Text = "Acheter un Niveau (50 Pièces)"
        end
    end)

    -- LOGIQUE GRAINE RARE (NOUVEAU)
    seedButton.MouseButton1Click:Connect(function()
        local data = DataService.getData(player)
        if data and data.Pieces >= 100 then
            data.Pieces = data.Pieces - 100
            
            -- On stocke la graine dans les "poches" du joueur (Attribut)
            local currentSeeds = player:GetAttribute("GrainesRares") or 0
            player:SetAttribute("GrainesRares", currentSeeds + 1)
            
            DataService.replicateToClient(player)
            seedButton.Text = "✅ Graine obtenue !"
            seedButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            task.wait(1)
            seedButton.Text = "Graine Rare (100 Pièces)"
            seedButton.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
        end
    end)
end

return ShopService