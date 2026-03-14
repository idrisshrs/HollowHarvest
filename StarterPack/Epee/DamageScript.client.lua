local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local tool = script.Parent

local REMOTE_NAME = "SwordHitRequest"
local ATTACK_BOX_SIZE = Vector3.new(6, 6, 6)
local ATTACK_BOX_OFFSET = CFrame.new(0, 0, -4) -- 4 studs devant le joueur (direction -Z)

local hitEvent = ReplicatedStorage:WaitForChild(REMOTE_NAME, 30)
if not hitEvent or not hitEvent:IsA("RemoteEvent") then
	warn("[SwordDamage] RemoteEvent 'SwordHitRequest' introuvable, désactivation du script.")
	script.Disabled = true
	return
end

local isAttacking = false

local function getCharacter()
	return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

local function getHumanoid(model)
	if not model then
		return nil
	end
	return model:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(model)
	if not model then
		return nil
	end

	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
end

local function scanHitbox(character, hitEnemies)
	local rootPart = getRootPart(character)
	if not rootPart then
		return
	end

	-- Centre de la box placé 4 studs devant le joueur
	local boxCFrame = rootPart.CFrame * ATTACK_BOX_OFFSET

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local partsInBox = Workspace:GetPartBoundsInBox(boxCFrame, ATTACK_BOX_SIZE, params)
	if not partsInBox or #partsInBox == 0 then
		return
	end

	for _, part in ipairs(partsInBox) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model then
			local humanoid = getHumanoid(model)
			if humanoid and humanoid.Health > 0 and not hitEnemies[humanoid] then
				-- On ne frappe chaque humanoid qu'une seule fois par clic
				hitEnemies[humanoid] = true

				-- Position envoyée au serveur = centre de la hitbox
				hitEvent:FireServer(humanoid, boxCFrame.Position, "sword")
			end
		end
	end
end

local function onActivated()
	if isAttacking then
		return
	end

	local character = getCharacter()
	local humanoid = getHumanoid(character)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	isAttacking = true

	-- Table locale pour ce clic : on évite les multi-hits
	local hitEnemies = {}

	-- 1) Détection immédiate
	scanHitbox(character, hitEnemies)

	-- 2) Deuxième détection 0.1s plus tard (si le joueur pivote)
	task.delay(0.1, function()
		scanHitbox(character, hitEnemies)
	end)

	-- Laisse le serveur gérer le vrai cooldown (anti-cheat)
	task.delay(0.25, function()
		isAttacking = false
	end)
end

tool.Activated:Connect(onActivated)

