local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

local REMOTE_NAME = "SwordHitRequest"
local PUNCH_COOLDOWN = 0.7
local PUNCH_RANGE = 7

local hitEvent = ReplicatedStorage:WaitForChild(REMOTE_NAME, 30)
if not hitEvent or not hitEvent:IsA("RemoteEvent") then
	warn("[UnarmedCombat] RemoteEvent 'SwordHitRequest' introuvable, désactivation du script.")
	script.Disabled = true
	return
end

local isAttacking = false
local lastPunchTime = 0

local function getCharacter()
	return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

local function getHumanoid(character)
	return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(model)
	if not model then
		return nil
	end

	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
end

local function hasEquippedTool(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return true
		end
	end
	return false
end

local function setupToolAutoDisable(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			script.Disabled = true
		end
	end)
end

do
	local char = localPlayer.Character
	if char then
		setupToolAutoDisable(char)
	end
	localPlayer.CharacterAdded:Connect(setupToolAutoDisable)
end

local function flashEnemyModel(model, color, duration)
	if not model then
		return
	end

	local parts = {}
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			table.insert(parts, {
				part = desc,
				color = desc.Color,
			})
			desc.Color = color
		end
	end

	if #parts == 0 then
		return
	end

	task.delay(duration, function()
		for _, info in ipairs(parts) do
			local part = info.part
			if part and part.Parent then
				part.Color = info.color
			end
		end
	end)
end

local function flashSelfTorso(character, color, duration)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return
	end

	local originalColor = torso.Color
	torso.Color = color

	task.delay(duration, function()
		if torso and torso.Parent then
			torso.Color = originalColor
		end
	end)
end

local function doPunch()
	if isAttacking then
		return
	end

	local now = tick()
	if now - lastPunchTime < PUNCH_COOLDOWN then
		return
	end

	local character = getCharacter()
	local humanoid = getHumanoid(character)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Désactiver si un Tool est équipé
	if hasEquippedTool(character) then
		script.Disabled = true
		return
	end

	local rootPart = getRootPart(character)
	if not rootPart then
		return
	end

	isAttacking = true
	lastPunchTime = now

	local punchColor = Color3.fromRGB(255, 170, 0)

	local myHumanoid = humanoid

	for _, desc in ipairs(workspace:GetDescendants()) do
		local enemyHumanoid = nil
		if desc:IsA("Humanoid") then
			enemyHumanoid = desc
		end

		if enemyHumanoid and enemyHumanoid ~= myHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.Parent then
			local enemyRoot = getRootPart(enemyHumanoid.Parent)
			if enemyRoot then
				local distance = (enemyRoot.Position - rootPart.Position).Magnitude
				if distance <= PUNCH_RANGE then
					hitEvent:FireServer(enemyHumanoid, rootPart.Position, "punch")

					local enemyModel = enemyHumanoid.Parent
					flashEnemyModel(enemyModel, punchColor, 0.12)

					local enemyName = enemyModel.Name
					print(string.format("👊 Poing : %s à %.1f studs", enemyName, distance))
				end
			end
		end
	end

	flashSelfTorso(character, punchColor, 0.15)

	isAttacking = false
end

mouse.Button1Down:Connect(doPunch)

-- ============================================================
-- UnarmedCombat.client.lua → src/client/
-- ⚠️ LOCALSCRIPT
-- Utilise GetMouse().Button1Down — méthode 100% fiable Roblox
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local mouse       = localPlayer:GetMouse()

local hitEvent = ReplicatedStorage:WaitForChild("SwordHitRequest", 30)
if not hitEvent then
	warn("❌ [UnarmedCombat] SwordHitRequest introuvable !")
	return
end
print("✅ [UnarmedCombat] Clic gauche détecté via GetMouse !")

local ATTACK_RANGE = 7
local COOLDOWN     = 0.7
local isAttacking  = false
local lastPunch    = 0

local function hasToolEquipped()
	local char = localPlayer.Character
	if not char then return false end
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Tool") then return true end
	end
	return false
end

local function doPunch()
	if isAttacking then return end
	if (tick() - lastPunch) < COOLDOWN then return end
	if hasToolEquipped() then return end  -- épée équipée = pas de poing

	isAttacking = true
	lastPunch   = tick()

	local char = localPlayer.Character
	if not char then isAttacking = false return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then isAttacking = false return end

	-- Feedback visuel : torse orange
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if torso then
		local ori = torso.Color
		torso.Color = Color3.fromRGB(255, 130, 0)
		task.delay(0.15, function()
			if torso and torso.Parent then torso.Color = ori end
		end)
	end

	-- Scan ennemis dans le rayon
	local hitAny = false
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Health > 0 and obj.Parent ~= char then
			local eRoot = obj.Parent:FindFirstChild("HumanoidRootPart")
				or obj.Parent:FindFirstChildOfClass("BasePart")
			if eRoot then
				local dist = (root.Position - eRoot.Position).Magnitude
				if dist <= ATTACK_RANGE then
					hitEvent:FireServer(obj, eRoot.Position, "punch")
					hitAny = true
					print(string.format("👊 Poing : %s à %.1f studs (-17 PV)", obj.Parent.Name, dist))

					-- Flash orange sur l'ennemi
					for _, p in ipairs(obj.Parent:GetDescendants()) do
						if p:IsA("BasePart") then
							local c = p.Color
							p.Color = Color3.fromRGB(255, 130, 0)
							task.delay(0.12, function()
								if p and p.Parent then p.Color = c end
							end)
						end
					end
				end
			end
		end
	end

	if not hitAny then
		print("👊 Frappe dans le vide (rien à " .. ATTACK_RANGE .. " studs)")
	end

	task.wait(0.3)
	isAttacking = false
end

-- ✅ GetMouse — méthode fiable pour détecter le clic en jeu
mouse.Button1Down:Connect(doPunch)

print("✅ [UnarmedCombat] Prêt — clic gauche = poing (17 dmg)")