# HOLLOW HARVEST — Contexte Projet

## Concept
Farming sim de jour (Grow a Garden style) + mini-donjon procédural de nuit avec loot à ramener à la ferme. 
Le joueur alterne entre planter/récolter en sécurité (jour) et prendre des risques pour du loot rare (nuit).

## Statistiques Joueur
- Pièces (Or gagné en vendant des récoltes)
- Niveau (Expérience gagnée en donjon)

## Monétisation (Philosophie "Anti-friction")
- Le joueur ne paie pas pour gagner, il paie pour le confort.
- L'économie est gérée côté SERVEUR uniquement (anti-cheat absolu).

## Architecture & Techniques Obligatoires
- Utiliser le module **ProfileService** pour sauvegarder les données des joueurs (Pièces, Niveau).
- Modèle Client-Serveur autoritaire : le client (jeu) demande, le serveur vérifie et valide.
- Ne jamais utiliser `wait()`, utiliser uniquement `task.wait()`.
- Nommer les variables en `camelCase` et les modules en `PascalCase`.

## État actuel du développement
- [x] Structure de base du projet (Cursor + Rojo connectés)
- [x] Étape 1 : Système de sauvegarde (DataService) avec ProfileService
- [ ] Étape 2 : Boucle Jour/Nuit basique
- [ ] Étape 3 : Système de Farming (Planter/Récolter)