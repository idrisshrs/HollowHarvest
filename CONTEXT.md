# HOLLOW HARVEST — Contexte Projet Agent IA
> Lis ce fichier EN PREMIER à chaque session.
> Met à jour "État du développement" quand une feature est terminée.

---

## 🎮 Concept
Farming sim de jour (style Grow a Garden) + donjon crawler la nuit.
- **De jour** : planter, récolter, vendre au shop pour gagner des pièces
- **De nuit** : monstres agressifs, donjon ouvert, loot rare
- **Boucle** : Cultiver → Vendre → Acheter graines → Récolte rare → Risquer la nuit → Loot → Recommencer

**Tagline :** "Farm by day. Survive by night."

---

## 🏗️ Infrastructure

| Outil | Usage |
|---|---|
| VSCode / Cursor | IDE principal |
| Rojo 7.4.4 | Sync fichiers ↔ Roblox Studio |
| Foreman | Gestionnaire outils (C:\foreman dans PATH) |
| Git + GitHub | Versioning (idrisshrs/HollowHarvest) |
| `rojo serve` | Commande de lancement |

### Convention Rojo
| Fichier | Type Studio |
|---|---|
| `Module.lua` | ModuleScript |
| `Script.server.lua` | Script serveur |
| `Script.client.lua` | LocalScript |

---

## 📁 Architecture complète

```
src/
├── client/
│   ├── HUDController.client.lua         ✅ Pills top-droite (Pièces + Niveau + XP bar)
│   ├── VFXController.client.lua         ✅ Sons natifs + particules + bandeaux
│   ├── UnarmedCombat.client.lua         ✅ Clic gauche = 17 dégâts (GetMouse)
│   ├── DailyController.client.lua       ✅ Popup récompense journalière Glassmorphism
│   ├── LeaderboardController.client.lua ✅ Bouton 🏆 + panel top 5
│   └── PrestigeController.client.lua    ✅ Banneau animé notification prestige
│
├── server/
│   ├── Main.server.lua               ✅ Point d'entrée — ordre de démarrage strict
│   ├── DataService.lua               ✅ ProfileService — sauvegarde complète
│   ├── XPService.lua                 ✅ XP + level up automatique (×1.4 par niveau)
│   ├── DailyService.lua              ✅ Récompenses journalières (streak 7 jours + graines)
│   ├── LeaderboardService.lua        ✅ Top 5 joueurs, refresh 15s
│   ├── WorkerService.lua             ✅ PNJ ouvrier — récolte auto toutes les 8s (max 3)
│   ├── PrestigeService.lua           ✅ Rebirth — reset + ×1.15 gains par prestige
│   ├── VFXService.lua                ✅ 7 RemoteEvents VFX créés au démarrage
│   ├── TimeService.lua               ✅ Cycle Jour/Nuit (45s dev / 120s prod)
│   ├── GrowthService.lua             ✅ 4 graines, multi-plots, PlantConfig
│   ├── DungeonGate.lua               ✅ Porte solide jour / fantôme nuit
│   ├── MonsterService.lua            ✅ Vagues, 3 types, loot table
│   ├── ShopService.lua               ✅ Boutique à onglets (Améliorations/Graines/Armes)
│   └── SwordServer.server.lua        ✅ Dégâts épée (34) + poing (17) anti-cheat
│
└── shared/
    ├── ProfileService.lua            ✅ Lib sauvegarde (standard industrie)
    └── PlantConfig.lua               ✅ Config centrale des 4 graines
```

### Workspace Studio
| Nom | Type | Rôle |
|---|---|---|
| `Plots` | Folder | Contient les 6 plots de ferme |
| `Plot` (×6) | Part + ProximityPrompt | Terrains de culture indépendants |
| `DungeonGate` | Part Anchored | Porte donjon |
| `SpawnArea` | Part invisible Anchored | Spawn monstres |
| `ShopPart` | Part + ProximityPrompt | Marchand |

### StarterPack
| Nom | Type | Rôle |
|---|---|---|
| `Epee` | Tool + Handle | Arme principale |
| `Epee/DamageScript` | **LocalScript** ⚠️ | Hitbox GetPartBoundsInBox |

---

## 💾 DataService — Profil joueur complet

```lua
local profileTemplate = {
    -- Économie
    Pieces           = 100,
    Niveau           = 1,

    -- XP
    XP               = 0,
    XPMax            = 100,
    NiveauTotal      = 1,

    -- Inventaire graines
    InventaireGraines = {
        Ble     = 5,
        Carotte = 0,
        Tomate  = 0,
        Magique = 0,
    },

    -- Daily login
    LastLoginDay     = 0,
    LoginStreak      = 0,
    TotalDaysPlayed  = 0,

    -- Ouvriers
    WorkerCount      = 0,

    -- Prestige
    Prestiges        = 0,
    PieceMultiplier  = 1.0,
}
```

### API DataService
```lua
DataService.getData(player)            -- Retourne la table Data ou nil
DataService.replicateToClient(player)  -- Met à jour HUD + XP + inventaire
```
> ⚠️ Toujours appeler `replicateToClient` après CHAQUE modification de données

---

## 🔗 RemoteEvents dans ReplicatedStorage

| Event | Créé par | Direction | Contenu |
|---|---|---|---|
| `PlayerDataUpdated` | DataService | S→C | pieces, niveau, xp, xpMax, niveauTotal |
| `PlayerLevelUp` | XPService | S→C | newLevel |
| `SeedInventoryUpdated` | DataService | S→C | { Ble, Carotte, Tomate, Magique } |
| `DailyRewardClaimed` | DailyService | S→C | { streak, pieces, label, graines } |
| `LeaderboardUpdated` | LeaderboardService | S→C | [ {name, pieces, niveau} ×5 ] |
| `WorkerStatusUpdated` | WorkerService | S→C | workerCount, harvestedCount |
| `PlayerPrestiged` | PrestigeService | S→C (tous) | { name, prestiges, multiplier } |
| `DayNightChanged` | TimeService | S→C | bool (true=jour) |
| `SwordHitRequest` | SwordServer | C→S | humanoid, position, attackType |
| `VFX_EnemyHit` | VFXService | S→C | position |
| `VFX_Harvest` | VFXService | S→C | position |
| `VFX_MonsterDeath` | VFXService | S→C | position |
| `VFX_PlantGrow` | VFXService | S→C | position |
| `VFX_DayStart` | VFXService | S→C | — |
| `VFX_NightStart` | VFXService | S→C | — |
| `VFX_SwordHit` | VFXService | S→C | position |

---

## 🌾 PlantConfig — 4 graines

```lua
return {
    Ble     = { Time=8,   Price=10,  Gain=15,   XPReward=5,   Emoji="🌾" },
    Carotte = { Time=20,  Price=30,  Gain=50,   XPReward=15,  Emoji="🥕" },
    Tomate  = { Time=45,  Price=100, Gain=200,  XPReward=40,  Emoji="🍅" },
    Magique = { Time=120, Price=500, Gain=1500, XPReward=150, Emoji="✨" },
}
```

### États plot
```
"vide" → [E] → "planted" → [timer] → "ready" → [E] → "vide"
```
- `plot:GetAttribute("PlotState")` → "vide" / "planted" / "ready"
- `plot:GetAttribute("PlantType")` → "Ble" / "Carotte" / "Tomate" / "Magique"
- 6 plots dans `workspace.Plots` (Folder), chacun indépendant

---

## ⭐ XPService

```lua
-- Gains XP par action
Récolte Blé     → +5 XP
Récolte Carotte → +15 XP
Récolte Tomate  → +40 XP
Récolte Magique → +150 XP
Kill monstre    → +20 XP

-- Level up
XP >= XPMax → XP -= XPMax, NiveauTotal += 1, XPMax = floor(XPMax * 1.4)
→ FireClient "PlayerLevelUp" avec newLevel
```

---

## 🎁 DailyService

```lua
-- Timing (fenêtre permissive)
diff < 72000s (20h)      → déjà réclamé, stop
diff 72000s–172800s      → streak += 1 (max 7)
diff > 172800s (48h)     → streak = 1 (cassé)

-- Récompenses
J1 : 50🪙
J2 : 75🪙 + 1 Blé
J3 : 100🪙
J4 : 150🪙 + 1 Carotte
J5 : 200🪙
J6 : 250🪙 + 1 Tomate
J7 : 500🪙 + 1 Magique 👑
```

---

## 🏆 LeaderboardService

- Refresh toutes les **15 secondes**
- Top 5 joueurs du serveur triés par Pieces
- Bouton 🏆 toggle top-gauche
- Joueur local surligné en or

---

## 👷 WorkerService

```lua
WorkerCount max  = 3
Cycle récolte    = 8 secondes
Prix             = 500 pièces / ouvrier
Détection plot   = plot:GetAttribute("PlotState") == "ready"
Type plante      = plot:GetAttribute("PlantType")
Gain             = PlantConfig[plantType].Gain * (data.PieceMultiplier or 1.0)
XP               = PlantConfig[plantType].XPReward
Visuel           = Cube(1×1.5×1) + Sphère(0.8) + WeldConstraint + BillboardGui
Stockage         = Folder "Workers_<UserId>" dans Workspace (cleanup déco)
```

---

## ✨ PrestigeService

```lua
-- Condition
NiveauTotal >= 10

-- Effet
Prestiges += 1
PieceMultiplier = 1.0 + (Prestiges * 0.15)  -- ex: Prestige 3 → ×1.45

-- Reset (hard)
Pieces=0, XP=0, NiveauTotal=1, Niveau=1, XPMax=100

-- Conservation (pas de reset)
WorkerCount, InventaireGraines

-- Broadcast
FireAllClients("PlayerPrestiged", {name, prestiges, multiplier})
```

### Intégration GrowthService
```lua
local multiplier = data.PieceMultiplier or 1.0
data.Pieces += math.floor(config.Gain * multiplier)
```

---

## ⚔️ Combat

| Attaque | Dégâts | Portée | Cooldown | Méthode |
|---|---|---|---|---|
| Épée | 34 | Box 6×6×6 devant joueur | 0.55s | GetPartBoundsInBox |
| Poings | 17 | 7 studs rayon | 0.7s | GetDescendants scan |

### Validations SwordServer (ordre strict)
1. attacker + character existent
2. Humanoid vivant (Health > 0)
3. Anti-spam 0.5s par joueur
4. Distance ≤ 25 studs
5. Pas de PvP

---

## 👹 MonsterService

```lua
HP    = 5 + (vague * 2)
SPEED = 18 + (vague * 0.5)   -- joueur = 16
DAMAGE = 20, COOLDOWN = 1.0s
UPDATE_RATE = 0.1s

-- 3 types de monstres
Normal  : Speed=18, HP×1.0, gris,   Scale=1.0   (60%)
Rapide  : Speed=24, HP×0.5, jaune,  Scale=0.8   (20%)
Tank    : Speed=12, HP×2.5, rouge,  Scale=1.3   (20%)

-- Loot table
{ chance=0.05, pieces=300 }  -- Graine Épique
{ chance=0.25, pieces=100 }  -- Graine Rare
{ chance=0.70, pieces=50  }  -- Pièces
```

### Points critiques
- `body.Anchored = false` — obligatoire
- `humanoid.HipHeight = 3` — évite enfoncement sol
- `body:SetNetworkOwner(nil)` — stabilité réseau
- Variable `alive` locale dans `spawnMonster()` — pas globale
- Protection double spawn en haut de la fonction

---

## 🏪 ShopService — Boutique à onglets

| Item | Onglet | Prix | Effet |
|---|---|---|---|
| Niveau | Améliorations | 50🪙 | +1 Niveau |
| Ouvrier | Améliorations | 500🪙 | +1 worker (max 3) |
| Prestige | Améliorations | Gratuit | Reset + ×1.15 (Niv.10+) |
| Blé | Graines | 10🪙 | +1 Blé inventaire |
| Carotte | Graines | 30🪙 | +1 Carotte inventaire |
| Tomate | Graines | 100🪙 | +1 Tomate inventaire |
| Magique | Graines | 500🪙 | +1 Magique inventaire |
| Armes | Armes | — | Bientôt disponible |

---

## 🎨 VFX — Sons garantis Roblox

```lua
swordHit     = "rbxassetid://199149263"
swordSlash   = "rbxassetid://154965962"
harvest      = "rbxassetid://259300357"
plantReady   = "rbxassetid://265466152"
explosion    = "rbxassetid://131070686"
dayAmbient   = "rbxassetid://154556686"
nightAmbient = "rbxassetid://2865227271"
```

### Règle Attachment (bug corrigé)
```lua
local att  = Instance.new("Attachment")
att.Parent = part              -- ⚠️ AVANT le ParticleEmitter
local e    = Instance.new("ParticleEmitter")
e.Parent   = att
```

### Règle Sons (bug corrigé)
```lua
sound.Ended:Connect(function() part:Destroy() end)
task.delay(4, function()
    if part and part.Parent then part:Destroy() end
end)
```

---

## 📐 Règles de code

```lua
wait(1)       -- ❌ INTERDIT
task.wait(1)  -- ✅ OBLIGATOIRE

local maVariable  = 0           -- camelCase
local MonModule   = require(...) -- PascalCase

-- Sécurité serveur toujours en premier
event.OnServerEvent:Connect(function(player, ...)
    if not player or not player.Character then return end
    -- valider AVANT toute action
end)
```

---

## 🚀 Ordre démarrage Main.server.lua

```lua
-- ORDRE STRICT — ne jamais modifier
local VFXService          = require(script.Parent.VFXService)
VFXService.start()         -- 1er : crée tous les RemoteEvents VFX

local DataService         = require(script.Parent.DataService)
-- s'initialise au require via PlayerAdded

local XPService           = require(script.Parent.XPService)
local DailyService        = require(script.Parent.DailyService)
local LeaderboardService  = require(script.Parent.LeaderboardService)
local WorkerService       = require(script.Parent.WorkerService)
local PrestigeService     = require(script.Parent.PrestigeService)

local TimeService         = require(script.Parent.TimeService)
TimeService.start()

local GrowthService       = require(script.Parent.GrowthService)
GrowthService.start()

local DungeonGate         = require(script.Parent.DungeonGate)
DungeonGate.start()

local MonsterService      = require(script.Parent.MonsterService)
MonsterService.start()

local ShopService         = require(script.Parent.ShopService)
ShopService.start()

LeaderboardService.start()
WorkerService.start()

-- SwordServer.server.lua se lance seul (Script autonome)
```

---

## ✅ État du développement

### Phase 0 — ✅ Terminée
- [x] Environnement dev (VSCode + Rojo + Foreman + Git)
- [x] DataService + ProfileService
- [x] HUD Pièces + Niveau (pills top-droite)
- [x] Cycle Jour/Nuit (Lighting + effets)
- [x] GrowthService (plots + récolte)
- [x] DungeonGate
- [x] ShopService initial
- [x] MonsterService (IA + loot)
- [x] VFXService + VFXController (sons natifs + particules)
- [x] SwordServer anti-cheat (épée 34 + poing 17)
- [x] DamageScript LocalScript (hitbox GetPartBoundsInBox)
- [x] UnarmedCombat (GetMouse)

### Phase 1 — ✅ Terminée
- [x] PlantConfig.lua (4 graines : Blé/Carotte/Tomate/Magique)
- [x] Multi-plots (6 terrains dans workspace.Plots)
- [x] Boutique à onglets (Améliorations / Graines / Armes)
- [x] Inventaire graines affiché (SeedInventoryUpdated)
- [x] Vagues de monstres (2-3 par nuit)
- [x] 3 types de monstres (Normal / Rapide / Tank)
- [x] Hitbox épée précise (GetPartBoundsInBox)
- [x] VFX combat complets

### Phase 2 — ✅ Terminée
- [x] XPService (barre HUD, level up, gains par action)
- [x] DailyService (streak 7 jours, graines en récompense J2/J4/J6/J7)
- [x] LeaderboardService (top 5, refresh 15s, bouton 🏆)
- [x] WorkerService (PNJ ouvrier, récolte auto 8s, max 3)
- [x] PrestigeService (rebirth ×1.15, UI confirmation, banneau broadcast)

### Phase 3 — À faire 🔜
- [ ] Gamepass Farmer VIP (299 Robux — +slots ferme + serre +20%)
- [ ] Gamepass Dungeon VIP (449 Robux — revie + minimap donjon)
- [ ] Starter Bundle (99 Robux — 3 graines + 500p, achat unique)
- [ ] Boost x2 récolte (49 Robux / 1h, répétable)
- [ ] Gacha graines rares (75 Robux / tirage)

### Phase 4 — Polish & Lancement
- [ ] Map complète (ferme + donjon + hub)
- [ ] Tutoriel onboarding visuel (flèches, 0 texte long)
- [ ] Optimisation réseau (test 10+ joueurs)
- [ ] Événements saisonniers (Halloween / Noël)
- [ ] Thumbnail accrocheuse + description Roblox
- [ ] Analytics D1/D7 rétention post-lancement
