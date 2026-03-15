local DungeonGate = {}
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local playerDebounce = {} -- Track last error message time per player

function DungeonGate.start()
    local gate = workspace:WaitForChild("DungeonGate")
    local DataService = require(script.Parent.DataService)
    local VFXService = require(script.Parent.VFXService)
    
    local lastState = nil -- Pour se souvenir si c'était le jour ou la nuit

    task.spawn(function()
        while true do
            -- On calcule si c'est le jour (entre 6h et 18h)
            local isDay = (Lighting.ClockTime >= 6 and Lighting.ClockTime < 18)

            -- On n'agit QUE si l'état a changé depuis la dernière vérification
            if isDay ~= lastState then
                lastState = isDay
                
                if isDay then
                    gate.Transparency = 0
                    gate.CanCollide = true
                    print("🧱 [DungeonGate] Le soleil brille, le donjon est scellé.")
                else
                    gate.Transparency = 0.8
                    gate.CanCollide = false
                    print("🌌 [DungeonGate] La nuit est là... le donjon s'ouvre !")
                end
            end
            task.wait(1) -- On vérifie chaque seconde, c'est suffisant
        end
    end)

    -- ✨ Prestige Check for Dungeon Entry (with debounce)
    gate.Touched:Connect(function(hit)
        local char = hit.Parent
        if not char then return end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local player = Players:FindFirstChild(char.Name)
        if not player then return end
        
        local data = DataService.getData(player)
        if not data then return end
        
        -- If player has no prestige and touching gate during day
        if data.Prestiges < 1 then
            local now = tick()
            local lastTime = playerDebounce[player.UserId] or 0
            
            -- Only show error message if 2+ seconds have passed since last message
            if now - lastTime >= 2 then
                playerDebounce[player.UserId] = now
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    VFXService.error(root.Position, "✨ Seuls les héros de Prestige 1 peuvent entrer...", player)
                    print(string.format("🚫 [DungeonGate] %s tentative d'entrée sans prestige", player.Name))
                end
            end
        end
    end)
end

return DungeonGate