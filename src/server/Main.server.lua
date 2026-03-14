-- ============================================================
-- Main.server.lua → src/server/
-- CHANGEMENT : VFXService chargé EN PREMIER (crée les events)
-- SwordServer est un Script autonome, pas besoin de le require
-- ============================================================
 
local VFXService     = require(script.Parent.VFXService)
VFXService.start()   -- ⚠️ Doit être avant tout le reste
 
local DataService    = require(script.Parent.DataService)
local TimeService    = require(script.Parent.TimeService)
local GrowthService  = require(script.Parent.GrowthService)
local DungeonGate    = require(script.Parent.DungeonGate)
local MonsterService = require(script.Parent.MonsterService)
local ShopService    = require(script.Parent.ShopService)
 
TimeService.start()
GrowthService.start()
DungeonGate.start()
MonsterService.start()
ShopService.start()

print("✅ [Main] Tous les systèmes sont opérationnels !")
print("☀️  Cycle Jour/Nuit : OK")
print("🌾 Système de Ferme : OK")
print("🧱 Portes du Donjon : OK")
print("👹 Monstre : OK")
print("🏪 Shop : OK")