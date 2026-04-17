# CMS Local - Gestion d'Affichage Dynamique

Application mobile (Android & iOS) pour la gestion de players d'affichage dynamique via réseau local (LAN).

## Fonctionnalités

### Gestion des Players
- Ajouter des players via leur adresse IP
- Découverte automatique des players sur le réseau
- Vérification du statut en temps réel (en ligne/hors ligne)
- Synchronisation manuelle des planifications
- Redémarrage à distance

### Planifications
- Créer des planifications avec dates de début/fin
- Récurrence : unique, quotidienne, semaine, week-end, hebdomadaire
- Sélection de médias avec ordre personnalisable
- Configuration de la durée et des transitions (fondu, glisser, zoom)
- Activation/désactivation des planifications

### Bibliothèque de Médias
- Import d'images (JPG, PNG, GIF, WebP)
- Import de vidéos (MP4, AVI, MOV)
- Prévisualisation des médias
- Envoi direct aux players
- Gestion des métadonnées (durée, transition)

## Architecture Technique

### Communication LAN
- Protocole HTTP sur le port 8080 (par défaut)
- Endpoints REST pour :
  - `/api/health` - Vérification de disponibilité
  - `/api/status` - Statut du player
  - `/api/schedule` - Envoi des planifications
  - `/api/media` - Transfert des médias
  - `/api/sync` - Synchronisation
  - `/api/play`, `/api/stop`, `/api/reboot` - Contrôles

### Stockage Local
- Hive pour les données structurées (players, planifications, médias)
- SharedPreferences pour les paramètres

## Structure du Projet

```
lib/
├── models/           # Modèles de données
│   ├── player.dart
│   ├── media_item.dart
│   └── schedule.dart
├── services/         # Services métier
│   ├── lan_communication_service.dart
│   └── storage_service.dart
├── providers/        # Gestion d'état (Provider)
│   └── app_provider.dart
├── screens/          # Écrans de l'application
│   ├── home_screen.dart
│   ├── players_screen.dart
│   ├── schedules_screen.dart
│   └── media_screen.dart
└── main.dart         # Point d'entrée
```

## Démarrage

```bash
# Installation des dépendances
flutter pub get

# Exécution en mode debug
flutter run

# Build Android
flutter build apk --release
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

## Configuration du Player

Le player (application sur l'écran d'affichage) doit implémenter les endpoints REST décrits ci-dessus et écouter sur le port 8080.
