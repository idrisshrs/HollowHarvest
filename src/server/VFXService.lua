-- ============================================================
-- VFXService.lua → src/server/
-- CHANGEMENTS :
--   - Ajout fonction start() appelée dans Main
--   - Ajout event VFX_SwordHit
--   - Events créés dans start() pour garantir l'ordre
-- ============================================================

local VFXService        = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = {}

local function getOrCreate(name)
	local e = ReplicatedStorage:FindFirstChild(name)
	if not e then
		e        = Instance.new("RemoteEvent")
		e.Name   = name
		e.Parent = ReplicatedStorage
	end
	return e
end

function VFXService.start()
	Events.EnemyHit     = getOrCreate("VFX_EnemyHit")
	Events.Harvest      = getOrCreate("VFX_Harvest")
	Events.MonsterDeath = getOrCreate("VFX_MonsterDeath")
	Events.PlantGrow    = getOrCreate("VFX_PlantGrow")
	Events.DayStart     = getOrCreate("VFX_DayStart")
	Events.NightStart   = getOrCreate("VFX_NightStart")
	Events.SwordHit     = getOrCreate("VFX_SwordHit")
	print("✅ [VFXService] 7 events créés")
end

local function fire(event, ...)
	if event then event:FireAllClients(...) end
end
local function fireOne(event, player, ...)
	if event then event:FireClient(player, ...) end
end

function VFXService.enemyHit(pos, player)
	if player then fireOne(Events.EnemyHit, player, pos)
	else fire(Events.EnemyHit, pos) end
end

function VFXService.swordHit(pos, player)
	if player then fireOne(Events.SwordHit, player, pos)
	else fire(Events.SwordHit, pos) end
end

function VFXService.harvest(pos, player)
	if player then fireOne(Events.Harvest, player, pos)
	else fire(Events.Harvest, pos) end
end

function VFXService.monsterDeath(pos)
	fire(Events.MonsterDeath, pos)
end

function VFXService.plantGrow(pos)
	fire(Events.PlantGrow, pos)
end

function VFXService.dayStart()
	fire(Events.DayStart)
end

function VFXService.nightStart()
	fire(Events.NightStart)
end

return VFXService