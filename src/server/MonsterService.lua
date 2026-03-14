-- ============================================================
-- MonsterService.lua → src/server/
--
-- CORRECTIONS :
--   - Suppression ClickDetector (conflit avec SwordServer)
--   - PV via humanoid.HealthChanged → synced avec TakeDamage
--   - Mort via humanoid.Died → plus de doublon de récompense
--   - Barre de vie suit le vrai Humanoid.Health
--   - Monstre ne s'arrête plus après 1 coup
-- ============================================================

local MonsterService = {}

local Players     = game:GetService("Players")
local Lighting    = game:GetService("Lighting")
local DataService = require(script.Parent.DataService)
local VFXService  = require(script.Parent.VFXService)

local MONSTER_TYPES = {
	Normal = {
		Speed = 18,
		HPMultiplier = 1.0,
		Color = Color3.fromRGB(163, 162, 165),
		Scale = 1,
		RewardMult = 1,
	},
	Rapide = {
		Speed = 24,
		HPMultiplier = 0.5,
		Color = Color3.fromRGB(255, 255, 0),
		Scale = 0.8,
		RewardMult = 1.5,
	},
	Tank = {
		Speed = 12,
		HPMultiplier = 2.5,
		Color = Color3.fromRGB(255, 50, 50),
		Scale = 1.3,
		RewardMult = 2,
	},
}

local BASE_CONFIG = {
	HP              = 100,
	SPEED           = 18,
	DAMAGE          = 20,
	DAMAGE_COOLDOWN = 1.0,
	UPDATE_RATE     = 0.1,
	SIZE            = Vector3.new(4, 5, 4),
}

local LOOT_TABLE = {
	{ name = "Graine Épique", chance = 0.05, pieces = 300 },
	{ name = "Graine Rare",   chance = 0.25, pieces = 100 },
	{ name = "Pièces",        chance = 0.70, pieces = 50  },
}

local activeMonsters = {}
local currentWave    = 0

local function rollLoot()
	local roll, cumul = math.random(), 0
	for _, item in ipairs(LOOT_TABLE) do
		cumul += item.chance
		if roll <= cumul then return item end
	end
	return LOOT_TABLE[#LOOT_TABLE]
end

local function getNearestPlayer(pos)
	local nearest, best = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local d = (root.Position - pos).Magnitude
				if d < best then best, nearest = d, p end
			end
		end
	end
	return nearest, best
end

local function deathAnim(body, model)
	task.spawn(function()
		for i = 1, 10 do
			if body and body.Parent then
				body.Transparency = i / 10
				body.Size         = body.Size * 1.08
			end
			task.wait(0.05)
		end
		if model and model.Parent then model:Destroy() end
	end)
end

local function chaseLoop(model, humanoid, isAlive)
	task.spawn(function()
		while isAlive() and model and model.Parent do
			local root = model:FindFirstChild("HumanoidRootPart")
			if not root then break end
			local target, dist = getNearestPlayer(root.Position)
			if target and target.Character then
				local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
				if tRoot then
					humanoid:MoveTo(tRoot.Position)
					if root.Velocity.Magnitude < 1 and dist > 5 then
						humanoid.Jump = true
					end
				end
			end
			task.wait(BASE_CONFIG.UPDATE_RATE)
		end
	end)
end

function MonsterService.spawnMonster(spawnPos)
	local wave = currentWave
	local baseMaxHp = BASE_CONFIG.HP + (wave * 20)

	local roll = math.random()
	local monsterTypeName
	if roll <= 0.6 then
		monsterTypeName = "Normal"
	elseif roll <= 0.8 then
		monsterTypeName = "Rapide"
	else
		monsterTypeName = "Tank"
	end

	local monsterType = MONSTER_TYPES[monsterTypeName]
	local maxHp = math.floor(baseMaxHp * monsterType.HPMultiplier)
	local speed = monsterType.Speed + math.max(wave - 1, 0) * 0.5

	print(string.format("👹 Vague %d — Type:%s PV:%d Vitesse:%.1f", wave, monsterTypeName, maxHp, speed))

	local model       = Instance.new("Model")
	model.Name        = "Enemy"
	model.Parent      = workspace
	model:SetAttribute("MonsterType", monsterTypeName)

	local body            = Instance.new("Part")
	body.Name             = "HumanoidRootPart"
	body.Size             = BASE_CONFIG.SIZE
	body.Position         = spawnPos + Vector3.new(0, 6, 0)
	body.Color            = monsterType.Color
	body.Material         = Enum.Material.Neon
	body.Anchored         = false
	body.CanCollide       = true
	body.Parent           = model
	model.PrimaryPart     = body
	body:SetNetworkOwner(nil)

	local rootPart        = Instance.new("Part")
	rootPart.Name         = "RootPart"
	rootPart.Size         = Vector3.new(1,1,1)
	rootPart.Transparency = 1
	rootPart.CanCollide   = false
	rootPart.Position     = body.Position
	rootPart.Parent       = model

	local weld    = Instance.new("WeldConstraint")
	weld.Part0    = body
	weld.Part1    = rootPart
	weld.Parent   = body

	-- ✅ Humanoid avec vrais PV
	local humanoid        = Instance.new("Humanoid")
	humanoid.MaxHealth    = maxHp
	humanoid.Health       = maxHp
	humanoid.WalkSpeed    = speed
	humanoid.HipHeight    = 3 * monsterType.Scale
	humanoid.Parent       = model

	if monsterType.Scale ~= 1 then
		model:ScaleTo(monsterType.Scale)
	end

	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Color = monsterType.Color
		end
	end

	local light       = Instance.new("PointLight")
	light.Color       = Color3.fromRGB(255, 0, 0)
	light.Range       = 20
	light.Brightness  = 3
	light.Parent      = body

	-- UI
	local bb          = Instance.new("BillboardGui")
	bb.Size           = UDim2.new(0, 200, 0, 55)
	bb.StudsOffset    = Vector3.new(0, 5, 0)
	bb.Parent         = body

	local baseColor = monsterType.Color

	local nameLbl             = Instance.new("TextLabel")
	nameLbl.Size              = UDim2.new(1,0,0.6,0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text              = string.format("Monstre %s - Vague %d | ❤️ %d/%d", monsterTypeName, wave, maxHp, maxHp)
	nameLbl.TextColor3        = Color3.fromRGB(255,80,80)
	nameLbl.TextScaled        = true
	nameLbl.Font              = Enum.Font.GothamBold
	nameLbl.Parent            = bb

	local hpBg                = Instance.new("Frame")
	hpBg.Size                 = UDim2.new(1,0,0.3,0)
	hpBg.Position             = UDim2.new(0,0,0.7,0)
	hpBg.BackgroundColor3     = Color3.fromRGB(60,0,0)
	hpBg.BorderSizePixel      = 0
	hpBg.Parent               = bb

	local hpBar               = Instance.new("Frame")
	hpBar.Size                = UDim2.new(1,0,1,0)
	hpBar.BackgroundColor3    = Color3.fromRGB(255,50,50)
	hpBar.BorderSizePixel     = 0
	hpBar.Parent              = hpBg

	local alive  = true
	local canDmg = true
	local function isAlive() return alive end

	activeMonsters[model] = true

	-- ✅ CORRECTION : HealthChanged au lieu de ClickDetector
	-- SwordServer fait TakeDamage → Humanoid.Health change
	-- → cet event se déclenche → UI se met à jour
	humanoid.HealthChanged:Connect(function(newHp)
		if not alive then return end
		local ratio  = math.max(newHp / maxHp, 0)
		hpBar.Size   = UDim2.new(ratio, 0, 1, 0)
		nameLbl.Text = string.format("Monstre %s - Vague %d | ❤️ %d/%d", monsterTypeName, wave, math.ceil(newHp), maxHp)

		-- Flash blanc = hit confirmé
		if body and body.Parent then
			body.Color = Color3.fromRGB(255, 255, 255)
			task.delay(0.1, function()
				if body and body.Parent then body.Color = baseColor end
			end)
		end
		print(string.format("💥 Monstre : %.0f/%d PV", newHp, maxHp))
	end)

	-- ✅ CORRECTION : Died au lieu de hp <= 0 dans ClickDetector
	humanoid.Died:Connect(function()
		if not alive then return end
		alive = false
		activeMonsters[model] = nil

		local loot  = rollLoot()
		local root2 = model:FindFirstChild("HumanoidRootPart")
		local rewardPieces = math.floor(loot.pieces * monsterType.RewardMult)

		if root2 then
			local winner, _ = getNearestPlayer(root2.Position)
			if winner then
				local data = DataService.getData(winner)
				if data then
					data.Pieces = data.Pieces + rewardPieces
					DataService.replicateToClient(winner)
				end
			end
			VFXService.monsterDeath(root2.Position)
		end

		nameLbl.Text       = "💀 +" .. rewardPieces .. " 🪙"
		nameLbl.TextColor3 = Color3.fromRGB(255,220,0)
		hpBar.Size         = UDim2.new(0,0,1,0)

		print(string.format("💀 Monstre mort ! +%d pièces (%s x%.1f)", rewardPieces, monsterTypeName, monsterType.RewardMult))
		task.wait(0.3)
		if body and body.Parent then deathAnim(body, model) end
	end)

	-- Dégâts monstre → joueur
	body.Touched:Connect(function(hit)
		if not alive then return end
		local char = hit.Parent
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum ~= humanoid and canDmg then
			canDmg = false
			hum:TakeDamage(BASE_CONFIG.DAMAGE)
			if body and body.Parent then
				body.Color = Color3.fromRGB(255,200,0)
				task.delay(0.15, function()
					if body and body.Parent then body.Color = Color3.fromRGB(180,0,0) end
				end)
			end
			task.wait(BASE_CONFIG.DAMAGE_COOLDOWN)
			canDmg = true
		end
	end)

	chaseLoop(model, humanoid, isAlive)
end

function MonsterService.despawnMonster()
	local toClear = {}
	for model in pairs(activeMonsters) do
		table.insert(toClear, model)
	end

	for _, model in ipairs(toClear) do
		activeMonsters[model] = nil
		if model and model.Parent then
			local body = model:FindFirstChild("HumanoidRootPart")
			if body then
				deathAnim(body, model)
			else
				model:Destroy()
			end
		end
	end
end

function MonsterService.start()
	local spawnArea = workspace:WaitForChild("SpawnArea", 10)
	if not spawnArea then
		warn("⚠️ [MonsterService] SpawnArea introuvable !")
		return
	end
	print("✅ [MonsterService] Démarré.")
	local lastState = nil
	task.spawn(function()
		while true do
			local isDay = (Lighting.ClockTime >= 6 and Lighting.ClockTime < 18)
			if isDay ~= lastState then
				lastState = isDay
				if not isDay then
					currentWave += 1
					local monstersToSpawn = 2 + math.floor((currentWave - 1) / 2)
					print(string.format("🌑 Début de la vague %d — %d monstres", currentWave, monstersToSpawn))
					for i = 1, monstersToSpawn do
						MonsterService.spawnMonster(spawnArea.Position)
						if i < monstersToSpawn then
							task.wait(1.5)
						end
					end
				else
					MonsterService.despawnMonster()
				end
			end
			task.wait(1)
		end
	end)
end

return MonsterService