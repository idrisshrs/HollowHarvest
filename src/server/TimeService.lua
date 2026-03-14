-- ============================================================
-- TimeService.lua — src/server/
-- ============================================================

local TimeService = {}

local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFXService        = require(script.Parent.VFXService)

local DAY_DURATION   = 45
local NIGHT_DURATION = 45

function TimeService.start()

	-- RemoteEvent jour/nuit (pour DungeonGate etc.)
	local event = ReplicatedStorage:FindFirstChild("DayNightChanged")
	if not event then
		event        = Instance.new("RemoteEvent")
		event.Name   = "DayNightChanged"
		event.Parent = ReplicatedStorage
	end

	task.spawn(function()
		while true do

			-- ☀️ JOUR
			Lighting.ClockTime  = 14
			Lighting.Brightness = 2
			Lighting.FogEnd     = 10000
			event:FireAllClients(true)
			VFXService.dayStart()  -- 🔊 Son + bandeau "Le jour se lève"
			print("☀️ [TimeService] Le jour se lève.")
			task.wait(DAY_DURATION)

			-- 🌑 NUIT
			Lighting.ClockTime  = 0
			Lighting.Brightness = 0.2
			Lighting.FogEnd     = 300
			event:FireAllClients(false)
			VFXService.nightStart()  -- 🔊 Son + bandeau "La nuit tombe"
			print("🌑 [TimeService] La nuit tombe sur Hollow Harvest...")
			task.wait(NIGHT_DURATION)
		end
	end)
end

return TimeService
