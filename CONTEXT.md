# HOLLOW HARVEST — Contexte Projet Agent IA
> Lis ce fichier EN PREMIER à chaque session.
> Met à jour "État du développement" quand une feature est terminée.

---

## 🎮 Concept
Farming sim de jour (style Grow a Garden) + donjon crawler la nuit.
- **De jour** : planter, arroser, récolter, vendre au shop pour gagner des pièces
- **De nuit** : un monstre agressif apparaît, le donjon s'ouvre, loot rare possible
- Les deux phases se nourrissent : loot donjon → graines rares → plus de pièces → meilleur équipement

**Tagline :** "Farm by day. Survive by night."
**Boucle principale :** Cultiver → Vendre → Acheter graines rares → Récolte rare → Risquer la nuit → Loot → Recommencer

---

## 🏗️ Infrastructure Technique

### Environnement de développement
- **IDE :** Cursor (VS Code avec IA intégrée)
- **Sync :** Rojo 7.4.4 (synchronise fichiers locaux ↔ Roblox Studio automatiquement)
- **Gestionnaire :** Foreman (installé en C:\foreman, dans le PATH Windows)
- **Versioning :** Git + GitHub (repo : idrisshrs/HollowHarvest)
- **Commande de lancement :** `rojo serve` dans le terminal Cursor

### Convention de nommage des fichiers Rojo
| Nom fichier | Type dans Studio |
|---|---|
| `Module.lua` | ModuleScript |
| `Script.server.lua` | Script serveur |
| `Script.client.lua` | LocalScript |

---

## 📁 Architecture des fichiers

```
src/
├── client/
│   ├── HUDController.client.lua     ✅ Affiche Pièces + Niveau en temps réel
│   ├── VFXController.client.lua     ✅ Sons + particules + bandeaux
│   └── UnarmedCombat.client.lua     ✅ Combat mains nues (clic gauche = 17 dégâts)
│
├── server/
│   ├── Main.server.lua              ✅ Point d'entrée — démarre tous les services
│   ├── DataService.lua              ✅ Sauvegarde ProfileService
│   ├── VFXService.lua               ✅ Crée et fire les RemoteEvents VFX
│   ├── TimeService.lua              ✅ Cycle Jour/Nuit (45s/45s dev, 120s prod)
│   ├── GrowthService.lua            ✅ Plantation + récolte + lien DataService
│   ├── DungeonGate.lua              ✅ Porte donjon (solide jour, fantôme nuit)
│   ├── MonsterService.lua           ✅ IA ennemie, loot table, difficulté progressive
│   ├── ShopService.lua              ✅ Boutique (Niveau + Graines Rares)
│   └── SwordServer.server.lua       ✅ Dégâts épée (34) et poing (17) côté serveur
│
└── shared/
    └── ProfileService.lua           ✅ Bibliothèque sauvegarde (standard industrie)
```

### Objets Roblox Studio dans Workspace
| Nom | Type | Rôle |
|---|---|---|
| `Plot` | Part + ProximityPrompt | Terrain de culture |
| `DungeonGate` | Part Anchored | Porte du donjon |
| `SpawnArea` | Part invisible Anchored | Point spawn monstres |
| `ShopPart` | Part + ProximityPrompt | Comptoir marchand |

### Objets StarterPack
| Nom | Type | Rôle |
|---|---|---|
| `Epee` | Tool + Handle | Arme principale |
| `Epee/DamageScript` | **LocalScript** ⚠️ | Détection hits côté client |

---

## 💾 Système de données (DataService)

### Template profil joueur
```lua
local profileTemplate = {
    Pieces = 0,
    Niveau = 1,
}
```

### API DataService
```lua
DataService.getData(player)           -- Retourne {Pieces, Niveau} ou nil
DataService.replicateToClient(player) -- Met à jour HUD
```

> ⚠️ Appeler `replicateToClient` après CHAQUE modification de Pieces ou Niveau

---

## 🔗 RemoteEvents dans ReplicatedStorage

| Event | Créé par | Direction | Usage |
|---|---|---|---|
| `PlayerDataUpdated` | DataService | Serveur → Client | HUD Pieces + Niveau |
| `DayNightChanged` | TimeService | Serveur → Client | Signal jour/nuit |
| `SwordHitRequest` | SwordServer | Client → Serveur | Hit épée ou poing |
| `VFX_EnemyHit` | VFXService | Serveur → Client | Impact épée |
| `VFX_Harvest` | VFXService | Serveur → Client | Récolte |
| `VFX_MonsterDeath` | VFXService | Serveur → Client | Mort monstre |
| `VFX_PlantGrow` | VFXService | Serveur → Client | Plante prête |
| `VFX_DayStart` | VFXService | Serveur → Client | Bandeau jour |
| `VFX_NightStart` | VFXService | Serveur → Client | Bandeau nuit |
| `VFX_SwordHit` | VFXService | Serveur → Client | Son swing |

---

## ⚔️ Système de combat

### Architecture anti-cheat
```
Client LocalScript → détecte ennemis à portée
    ↓ FireServer(humanoid, position, attackType)
SwordServer → valide portée + cooldown → TakeDamage
    ↓
DataService → +25 pièces si monstre tué
```

### Paramètres
| Attaque | Dégâts | Portée | Cooldown |
|---|---|---|---|
| Épée | 34 | 10 studs | 0.55s |
| Poings | 17 | 7 studs | 0.7s |

### Validations serveur obligatoires
1. attacker et character existent
2. Humanoid vivant (Health > 0)
3. Anti-spam cooldown 0.5s
4. Distance ≤ 25 studs
5. Pas de PvP

---

## 🌾 Ferme (GrowthService)

### États du Plot
```
"vide" → [E] → "planted" → [timer] → "ready" → [E] → "vide"
```

### Plantes
| Type | Pousse | Gain | Stockage |
|---|---|---|---|
| Normale | 10s | +10p | — |
| Rare | 20s | +150p | `player:GetAttribute("GrainesRares")` |

---

## 👹 Monstre (MonsterService)

### Config
```lua
HP = 5 + (vague * 2)
SPEED = 18 + (vague * 0.5)
DAMAGE = 20, DAMAGE_COOLDOWN = 1.0
UPDATE_RATE = 0.1
```

### Points techniques critiques
- `body.Anchored = false` — obligatoire pour bouger
- `humanoid.HipHeight = 3` — évite l'enfoncement dans le sol
- `body:SetNetworkOwner(nil)` — stabilité réseau
- Variable `alive` locale dans `spawnMonster()` — pas globale
- Protection double spawn en haut de `spawnMonster()`

### Loot
```lua
{ chance = 0.05, pieces = 300 }  -- Graine Épique
{ chance = 0.25, pieces = 100 }  -- Graine Rare
{ chance = 0.70, pieces = 50  }  -- Pièces
```

---

## 🎨 VFX

### Sons natifs Roblox (IDs garantis)
```lua
swordHit     = "rbxassetid://199149263"
swordSlash   = "rbxassetid://154965962"
harvest      = "rbxassetid://259300357"
plantReady   = "rbxassetid://265466152"
explosion    = "rbxassetid://131070686"
dayAmbient   = "rbxassetid://154556686"
nightAmbient = "rbxassetid://2865227271"
```

### Bug Attachment (corrigé)
```lua
local att    = Instance.new("Attachment")
att.Parent   = part              -- ⚠️ OBLIGATOIRE avant ParticleEmitter
local e      = Instance.new("ParticleEmitter")
e.Parent     = att
```

### Bug Sons (corrigé)
```lua
sound.Ended:Connect(function() part:Destroy() end)
task.delay(4, function()        -- fallback sécurité
    if part and part.Parent then part:Destroy() end
end)
```

---

## 📐 Règles de code

```lua
-- ❌ INTERDIT
wait(1)
-- ✅ OBLIGATOIRE
task.wait(1)

-- Nommage
local maVariable = 0          -- camelCase variables
local MonModule = require(...) -- PascalCase modules

-- Sécurité serveur
event.OnServerEvent:Connect(function(player, ...)
    if not player or not player.Character then return end
    -- valider AVANT toute action
end)
```

---

## 🚀 Ordre démarrage Main.server.lua

```lua
-- NE PAS CHANGER CET ORDRE
local VFXService = require(script.Parent.VFXService)
VFXService.start()     -- 1er : crée les 7 RemoteEvents VFX

local DataService = require(script.Parent.DataService)
-- DataService s'init au require (PlayerAdded)

local TimeService = require(script.Parent.TimeService)
TimeService.start()    -- cycle jour/nuit

local GrowthService = require(script.Parent.GrowthService)
GrowthService.start()  -- plots de ferme

local DungeonGate = require(script.Parent.DungeonGate)
DungeonGate.start()    -- porte donjon

local MonsterService = require(script.Parent.MonsterService)
MonsterService.start() -- IA ennemie

local ShopService = require(script.Parent.ShopService)
ShopService.start()    -- boutique

-- SwordServer.server.lua se lance seul (pas de require)
```

---

## ✅ État du développement

### Phase 0 — Terminée ✅
- [x] Environnement dev (Cursor + Rojo + Foreman + Git)
- [x] DataService + ProfileService
- [x] HUD Pièces + Niveau temps réel
- [x] Cycle Jour/Nuit avec Lighting
- [x] GrowthService (plantes normales + rares)
- [x] DungeonGate
- [x] ShopService (Niveau + Graines)
- [x] MonsterService (IA agressive + loot)
- [x] VFXService + VFXController (sons natifs + particules)
- [x] SwordServer anti-cheat (épée 34 dmg + poing 17 dmg)
- [x] DamageScript (LocalScript, détection par rayon)
- [x] UnarmedCombat (GetMouse, désactivé si outil équipé)

### Phase 1 — En cours 🔄
- [ ] Multi-plots (6 terrains indépendants)
- [x] PlantConfig.lua (config centrale des plantes)
- [x] Vagues de monstres (2-3 par nuit)
- [x] Monstres variés (Rapide / Tank / Chasseur)
- [x] VFX combat complets (tous les effets actifs)

### Phase 2 — À faire
- [ ] Système XP + récompenses journalières
- [ ] Leaderboard serveur (top 5 reset hebdo)
- [ ] Système de prestige (rebirth)
- [ ] PNJ Ouvrier (récolte automatique)
- [ ] Mini-carte donjon (plusieurs salles + boss)

### Phase 3 — Monétisation
- [ ] Gamepass Farmer VIP (299 Robux — +1 slot + serre)
- [ ] Gamepass Dungeon VIP (449 Robux — revie + minimap)
- [ ] Starter Bundle (99 Robux — 3 graines + 500p)
- [ ] Boost x2 récolte (49 Robux / 1h)
- [ ] Gacha graines rares (75 Robux)

### Phase 4 — Polish & Lancement
- [ ] Map complète (ferme + donjon + hub)
- [ ] Tutoriel onboarding visuel (flèches, 0 texte)
- [ ] Optimisation réseau (test 10+ joueurs)
- [ ] Événements saisonniers (Halloween / Noël)
- [ ] Thumbnail + description Roblox
- [ ] Analytics D1/D7 rétention