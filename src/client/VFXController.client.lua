-- ============================================================
-- VFXController.client.lua → src/client/
--
-- CORRECTIONS vs ton fichier actuel :
--   1. BUG PARTICULES : Attachment n'était jamais parented à la Part
--      → les particules n'apparaissaient pas du tout
--   2. BUG SONS : task.delay(sound.TimeLength) = 0 quand le son
--      n'est pas encore chargé → la Part se détruit avant le son
--      → remplacé par task.delay(4, ...) comme fallback
--   3. IDs SONS remplacés par des IDs Roblox natifs garantis
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local localPlayer       = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════
-- SONS — IDs officiels Roblox (évite HTTP 403)
-- Liste : 199149263, 154965962, 259300357, 265466152, 131070686, 154556686, 2865227271
-- ═══════════════════════════════════════════════════════════
local SOUNDS = {
	swordHit     = "rbxassetid://199149263",  -- Impact / combat
	swordSlash   = "rbxassetid://154965962",  -- Swoosh
	harvest      = "rbxassetid://259300357",  -- Positif / collecte / pousse
	plantReady   = "rbxassetid://265466152",  -- Ding plante prête
	explosion    = "rbxassetid://131070686",  -- Explosion
	dayAmbient   = "rbxassetid://154556686",  -- Ambiance jour
	nightAmbient = "rbxassetid://2865227271", -- Ambiance nuit
}

-- ── Attente des events ───────────────────────────────────────
local function waitFor(name)
	local e = ReplicatedStorage:WaitForChild(name, 20)
	if not e then warn("⚠️ [VFX] Event manquant : " .. name) end
	return e
end

local Events = {
	EnemyHit     = waitFor("VFX_EnemyHit"),
	SwordHit     = waitFor("VFX_SwordHit"),
	Harvest      = waitFor("VFX_Harvest"),
	MonsterDeath = waitFor("VFX_MonsterDeath"),
	PlantGrow    = waitFor("VFX_PlantGrow"),
	DayStart     = waitFor("VFX_DayStart"),
	NightStart   = waitFor("VFX_NightStart"),
}

-- ═══════════════════════════════════════════════════════════
-- UTILITAIRES
-- ═══════════════════════════════════════════════════════════

-- Son 3D à une position (CORRIGÉ : fallback delay 4s)
local function playSound(id, pos, vol, pitch)
	local part           = Instance.new("Part")
	part.Anchored        = true
	part.CanCollide      = false
	part.Transparency    = 1
	part.Size            = Vector3.one
	part.Position        = pos or Vector3.new(0, 5, 0)
	part.Parent          = workspace

	local s              = Instance.new("Sound")
	s.SoundId            = id
	s.Volume             = vol   or 0.8
	s.PlaybackSpeed      = pitch or 1
	s.RollOffMaxDistance = 80
	s.Parent             = part

	-- S'assure que le son est chargé avant de le jouer (réduit les erreurs 403/timeout)
	if not s.IsLoaded then
		pcall(function()
			s.Loaded:Wait()
		end)
	end

	-- Protège l'appel Play pour éviter qu'une erreur son ne stoppe le script
	pcall(function()
		s:Play()
	end)

	-- CORRECTION : TimeLength = 0 si pas encore chargé → on utilise 4s
	s.Ended:Connect(function()
		if part and part.Parent then part:Destroy() end
	end)
	task.delay(4, function()
		if part and part.Parent then part:Destroy() end
	end)
end

-- Son global 2D
local function playSoundUI(id, vol, pitch)
	local s              = Instance.new("Sound")
	s.SoundId            = id
	s.Volume             = vol   or 0.6
	s.PlaybackSpeed      = pitch or 1
	s.Parent             = workspace

	if not s.IsLoaded then
		pcall(function()
			s.Loaded:Wait()
		end)
	end

	pcall(function()
		s:Play()
	end)
	s.Ended:Connect(function() s:Destroy() end)
	task.delay(5, function()
		if s and s.Parent then s:Destroy() end
	end)
end

-- Particules (CORRIGÉ : Attachment correctement parented à la Part)
local function burst(pos, c1, c2, count, speed, life)
	local part           = Instance.new("Part")
	part.Anchored        = true
	part.CanCollide      = false
	part.Transparency    = 1
	part.Size            = Vector3.new(0.1, 0.1, 0.1)
	part.Position        = pos
	part.Parent          = workspace

	-- ✅ CORRECTION : Attachment parented à la Part AVANT le ParticleEmitter
	local att            = Instance.new("Attachment")
	att.Parent           = part   -- ← était manquant dans l'ancien code !

	local e              = Instance.new("ParticleEmitter")
	e.Color              = ColorSequence.new(c1, c2)
	e.LightEmission      = 0.6
	e.Size               = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency       = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Speed              = NumberRange.new(speed * 0.5, speed)
	e.Lifetime           = NumberRange.new(life * 0.5, life)
	e.SpreadAngle        = Vector2.new(360, 360)
	e.RotSpeed           = NumberRange.new(-60, 60)
	e.Rate               = 0
	e.Parent             = att
	e:Emit(count)

	task.delay(life + 0.5, function()
		if part and part.Parent then part:Destroy() end
	end)
end

-- Texte flottant
local function floatText(pos, txt, col)
	local anchor         = Instance.new("Part")
	anchor.Anchored      = true
	anchor.CanCollide    = false
	anchor.Transparency  = 1
	anchor.Size          = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position      = pos
	anchor.Parent        = workspace

	local bb             = Instance.new("BillboardGui")
	bb.Size              = UDim2.new(0, 120, 0, 40)
	bb.StudsOffset       = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop       = true
	bb.Parent            = anchor

	local lbl                    = Instance.new("TextLabel")
	lbl.Size                     = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency   = 1
	lbl.Text                     = txt
	lbl.TextColor3               = col or Color3.fromRGB(255, 220, 0)
	lbl.TextScaled               = true
	lbl.Font                     = Enum.Font.GothamBold
	lbl.TextStrokeTransparency   = 0.3
	lbl.Parent                   = bb

	TweenService:Create(lbl, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency       = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(1.6, function()
		if anchor and anchor.Parent then anchor:Destroy() end
	end)
end

-- Bandeau écran
local function banner(txt, bgCol, txtCol)
	local pg             = localPlayer:WaitForChild("PlayerGui")
	local gui            = Instance.new("ScreenGui")
	gui.ResetOnSpawn     = false
	gui.DisplayOrder     = 99
	gui.Parent           = pg

	local frame          = Instance.new("Frame")
	frame.AnchorPoint    = Vector2.new(0.5, 0)
	frame.Position       = UDim2.new(0.5, 0, 0.12, 0)
	frame.Size           = UDim2.new(0, 360, 0, 56)
	frame.BackgroundColor3 = bgCol
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent         = gui

	local corner         = Instance.new("UICorner")
	corner.CornerRadius  = UDim.new(0, 14)
	corner.Parent        = frame

	local lbl            = Instance.new("TextLabel")
	lbl.Size             = UDim2.new(1, -16, 1, 0)
	lbl.Position         = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text             = txt
	lbl.TextColor3       = txtCol
	lbl.TextScaled       = true
	lbl.Font             = Enum.Font.GothamBold
	lbl.Parent           = frame

	task.delay(2.2, function()
		TweenService:Create(frame, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl,   TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		task.delay(0.7, function()
			if gui and gui.Parent then gui:Destroy() end
		end)
	end)
end

-- Screen shake
local function shake(intensity, duration)
	local cam = workspace.CurrentCamera
	if not cam then return end
	task.spawn(function()
		local t = 0
		while t < duration do
			local dt = task.wait()
			t += dt
			local f = 1 - (t / duration)
			cam.CFrame = cam.CFrame * CFrame.new(
				(math.random() - 0.5) * 2 * intensity * f,
				(math.random() - 0.5) * 2 * intensity * f,
				0
			)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- CONNEXIONS AUX ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════

if Events.EnemyHit then
	Events.EnemyHit.OnClientEvent:Connect(function(pos)
		burst(pos, Color3.fromRGB(255,50,50), Color3.fromRGB(255,180,0), 20, 14, 0.4)
		playSound(SOUNDS.swordHit, pos, 0.9, math.random(90,110)/100)
		floatText(pos + Vector3.new(0,2,0), "⚔️ -34", Color3.fromRGB(255,80,80))

		local flash          = Instance.new("Part")
		flash.Anchored       = true
		flash.CanCollide     = false
		flash.Material       = Enum.Material.Neon
		flash.Shape          = Enum.PartType.Ball
		flash.Size           = Vector3.new(1.5,1.5,1.5)
		flash.Color          = Color3.fromRGB(255,255,255)
		flash.Transparency   = 0.2
		flash.CastShadow     = false
		flash.Position       = pos
		flash.Parent         = workspace
		TweenService:Create(flash, TweenInfo.new(0.2), {
			Transparency = 1, Size = Vector3.new(4,4,4)
		}):Play()
		task.delay(0.25, function()
			if flash and flash.Parent then flash:Destroy() end
		end)
	end)
end

if Events.SwordHit then
	Events.SwordHit.OnClientEvent:Connect(function(pos)
		burst(pos, Color3.fromRGB(200,200,255), Color3.fromRGB(255,255,255), 10, 8, 0.3)
		playSound(SOUNDS.swordSlash, pos, 0.8, 1)
	end)
end

if Events.Harvest then
	Events.Harvest.OnClientEvent:Connect(function(pos)
		burst(pos, Color3.fromRGB(100,220,50), Color3.fromRGB(255,215,0), 25, 10, 0.6)
		playSound(SOUNDS.harvest, pos, 0.8, 1)
		floatText(pos + Vector3.new(0,3,0), "+10 🪙", Color3.fromRGB(255,215,0))
	end)
end

if Events.MonsterDeath then
	Events.MonsterDeath.OnClientEvent:Connect(function(pos)
		burst(pos, Color3.fromRGB(255,80,0), Color3.fromRGB(255,0,0), 50, 20, 0.8)
		burst(pos + Vector3.new(0,1,0), Color3.fromRGB(255,215,0), Color3.fromRGB(255,255,150), 25, 8, 1.2)
		playSound(SOUNDS.explosion, pos, 1, 1)
		shake(0.35, 0.5)
		floatText(pos + Vector3.new(0,5,0), "💀 +50 🪙", Color3.fromRGB(255,220,0))
	end)
end

if Events.PlantGrow then
	Events.PlantGrow.OnClientEvent:Connect(function(pos)
		burst(pos + Vector3.new(0,1,0), Color3.fromRGB(80,200,80), Color3.fromRGB(180,255,100), 15, 6, 0.8)
		playSound(SOUNDS.plantReady, pos, 0.7, 1.1)
		floatText(pos + Vector3.new(0,3,0), "🌾 Prêt !", Color3.fromRGB(120,255,80))
	end)
end

if Events.DayStart then
	Events.DayStart.OnClientEvent:Connect(function()
		banner("☀️ Le jour se lève",
			Color3.fromRGB(255, 200, 50), Color3.fromRGB(80, 40, 0))
		playSoundUI(SOUNDS.dayAmbient, 0.45, 1)
	end)
end

if Events.NightStart then
	Events.NightStart.OnClientEvent:Connect(function()
		banner("🌙 La nuit tombe",
			Color3.fromRGB(25, 0, 70), Color3.fromRGB(200, 150, 255))
		playSoundUI(SOUNDS.nightAmbient, 0.45, 1)
	end)
end

print("✅ [VFXController] Actif")