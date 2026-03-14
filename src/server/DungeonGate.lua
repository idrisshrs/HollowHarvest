local DungeonGate = {}
local Lighting = game:GetService("Lighting")

function DungeonGate.start()
    local gate = workspace:WaitForChild("DungeonGate")
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
end

return DungeonGate