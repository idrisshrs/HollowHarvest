-- ============================================================
-- Main.server.lua → src/server/
-- CHANGEMENT : VFXService chargé EN PREMIER (crée les events)
-- SwordServer est un Script autonome, pas besoin de le require
-- ============================================================

local XPService      = require(script.Parent.XPService)
local VFXService     = require(script.Parent.VFXService)
VFXService.start()   -- ⚠️ Doit être avant tout le reste

local DataService      = require(script.Parent.DataService)
local TimeService      = require(script.Parent.TimeService)
local GrowthService    = require(script.Parent.GrowthService)
local DungeonGate      = require(script.Parent.DungeonGate)
local MonsterService   = require(script.Parent.MonsterService)
local ShopService      = require(script.Parent.ShopService)
local DailyService     = require(script.Parent.DailyService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local WorkerService    = require(script.Parent.WorkerService)
local PrestigeService  = require(script.Parent.PrestigeService)
 
TimeService.start()
GrowthService.start()
DungeonGate.start()
MonsterService.start()
ShopService.start()
LeaderboardService.start()
WorkerService.start()

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
		-- Wait 2 seconds for profile to load, as requested by the user
		task.wait(2)
		DailyService.checkAndGive(player)
end)

print("✅ [Main] Tous les systèmes sont opérationnels !")
print("☀️  Cycle Jour/Nuit : OK")
print("🌾 Système de Ferme : OK")
print("🧱 Portes du Donjon : OK")
print("👹 Monstre : OK")
print("🏪 Shop : OK")
print("📅 DailyService : OK")
print("🏆 Leaderboard : OK")
print("👷 Ouvriers (Workers) : OK")
print("✨ Prestige System : OK")