local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local VFXService = require(script.Parent.VFXService)

local REMOTE_NAME = "SwordHitRequest"
local MAX_DISTANCE = 25
local HIT_COOLDOWN = 0.5

local hitEvent = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not hitEvent then
	hitEvent = Instance.new("RemoteEvent")
	hitEvent.Name = REMOTE_NAME
	hitEvent.Parent = ReplicatedStorage
end

local lastHit = {} -- [player] = lastTick

local function getCharacterRoot(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")
end

local function getTargetRootFromHumanoid(humanoid)
	if not humanoid or not humanoid.Parent then
		return nil
	end

	return humanoid.RootPart
		or humanoid.Parent:FindFirstChild("HumanoidRootPart")
		or humanoid.Parent:FindFirstChild("Torso")
		or humanoid.Parent:FindFirstChild("UpperTorso")
end

local function isAliveHumanoid(h)
	return typeof(h) == "Instance"
		and h:IsA("Humanoid")
		and h.Health > 0
end

hitEvent.OnServerEvent:Connect(function(attacker, targetHumanoid, hitPosition, attackType)
	-- 3.a attacker et attacker.Character existent
	if not attacker or not attacker.Character then
		return
	end

	-- 3.b targetHumanoid est un Humanoid avec Health > 0
	if not isAliveHumanoid(targetHumanoid) then
		return
	end

	-- 3.c Anti-spam : cooldown 0.5s par joueur
	local now = tick()
	local last = lastHit[attacker]
	if last and now - last < HIT_COOLDOWN then
		return
	end
	lastHit[attacker] = now

	-- 3.d Vérifier distance entre attacker et cible <= 25 studs
	local attackerRoot = getCharacterRoot(attacker.Character)
	local targetRoot = getTargetRootFromHumanoid(targetHumanoid)
	if not attackerRoot or not targetRoot then
		return
	end

	local distance = (attackerRoot.Position - targetRoot.Position).Magnitude
	if distance > MAX_DISTANCE then
		return
	end

	-- 3.e Ne jamais frapper un autre joueur (pas de PvP)
	local targetPlayer = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	if targetPlayer then
		return
	end

	-- 4. Dégâts selon attackType
	local damage
	if attackType == "punch" then
		damage = 17
	else
		damage = 34
	end

	-- 5. VFX enemyHit si position fournie
	if hitPosition and typeof(hitPosition) == "Vector3" then
		VFXService.enemyHit(hitPosition, attacker)
	end

	-- Application des dégâts
	targetHumanoid:TakeDamage(damage)

	-- 6. Récompense si monstre tué
	if targetHumanoid.Health <= 0 then
		local data = DataService.getData(attacker)
		if data then
			data.Pieces = (data.Pieces or 0) + 25
			DataService.replicateToClient(attacker)
		end
	end

	-- 7. Logs
	if attackType == "punch" then
		print("👊 Punch de", attacker.Name, "sur", targetHumanoid.Parent.Name, string.format("(%.1f studs)", distance))
	else
		print("⚔️ Épée de", attacker.Name, "sur", targetHumanoid.Parent.Name, string.format("(%.1f studs)", distance))
	end
end)

-- ============================================================
-- SwordServer.server.lua → src/server/
-- CHANGEMENT : gère maintenant 2 types de dégâts
--   - Épée : 34 dégâts
--   - Poing : 17 dégâts (argument "punch" envoyé par le client)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local DataService       = require(script.Parent.DataService)
local VFXService        = require(script.Parent.VFXService)

local SWORD_DAMAGE = 34
local PUNCH_DAMAGE = 17   -- moitié de l'épée
local COOLDOWN     = 0.5
local lastHit      = {}

local hitEvent      = Instance.new("RemoteEvent")
hitEvent.Name       = "SwordHitRequest"
hitEvent.Parent     = ReplicatedStorage
print("✅ [SwordServer] Prêt — Épée 34 dmg / Poing 17 dmg")

hitEvent.OnServerEvent:Connect(function(attacker, targetHumanoid, hitPos, attackType)
	-- Validations
	if not attacker or not attacker.Character then return end
	if not targetHumanoid or not targetHumanoid:IsA("Humanoid") then return end
	if targetHumanoid.Health <= 0 then return end

	-- Anti-spam
	local now = tick()
	if (now - (lastHit[attacker] or 0)) < COOLDOWN then return end
	lastHit[attacker] = now

	-- Anti-hack portée
	local aRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
	local tRoot = targetHumanoid.Parent and targetHumanoid.Parent:FindFirstChild("HumanoidRootPart")
	if aRoot and tRoot then
		if (aRoot.Position - tRoot.Position).Magnitude > 25 then return end
	end

	-- Pas de PvP
	if Players:GetPlayerFromCharacter(targetHumanoid.Parent) then return end

	-- Dégâts selon le type d'attaque
	local damage = (attackType == "punch") and PUNCH_DAMAGE or SWORD_DAMAGE
	targetHumanoid:TakeDamage(damage)

	local icon = (attackType == "punch") and "👊" or "⚔️"
	print(string.format("%s %s → %s : -%d PV (reste %.0f)",
		icon, attacker.Name, targetHumanoid.Parent.Name, damage, targetHumanoid.Health))

	-- VFX différent selon l'attaque
	if hitPos then
		VFXService.enemyHit(hitPos, attacker)
	end

	-- Récompense si monstre tué
	if targetHumanoid.Health <= 0 then
		local data = DataService.getData(attacker)
		if data then
			data.Pieces = data.Pieces + 25
			DataService.replicateToClient(attacker)
		end
	end
end)