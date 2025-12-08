# Discover - Application de Partage Musical

## Description

Discover est une application iOS native qui permet de partager de la musique de manière curatée et humaine. L'application limite le partage à un seul morceau ou album par jour par utilisateur, encourageant ainsi la qualité plutôt que la quantité.

## Fonctionnalités

### ✅ Authentification Simplifiée
- Connexion par pseudonyme unique (3-15 caractères)
- Vérification d'unicité sur le backend
- Connexion automatique persistante

### ✅ Fil d'Actualité
- Affichage chronologique des partages de tous les utilisateurs
- Informations complètes : pseudonyme, pochette, titre, artiste
- Ouverture directe dans Spotify via deep linking

### ✅ Partage de Musique
- Recherche via l'API Spotify (artistes, albums, morceaux)
- Limite d'un partage par 24 heures
- Validation et publication instantanée

### ✅ Profil Utilisateur
- Affichage du pseudonyme
- Historique complet des partages
- Tri par date décroissante

## Architecture Technique

- **Frontend** : Swift / SwiftUI (iOS natif)
- **Backend** : Firebase Firestore (BaaS)
- **API Musique** : Spotify Web API (gratuit)
- **Deep Linking** : URL Schemes Spotify

## Structure du Projet

```
Discover/
├── Models/
│   ├── User.swift          # Modèle utilisateur
│   ├── Post.swift          # Modèle de partage
│   └── MusicItem.swift     # Modèle d'élément musical
├── Services/
│   ├── AuthService.swift      # Gestion de l'authentification
│   ├── FirebaseService.swift  # Interactions avec Firestore
│   └── SpotifyService.swift  # Intégration API Spotify
├── Views/
│   ├── AuthenticationView.swift  # Écran de connexion
│   ├── FeedView.swift            # Fil d'actualité
│   ├── ShareView.swift           # Partage de musique
│   ├── ProfileView.swift         # Profil utilisateur
│   └── MainTabView.swift         # Navigation principale
└── DiscoverApp.swift             # Point d'entrée de l'application
```

## Modèle de Données

### Post
- `id` : Identifiant unique
- `userPseudonym` : Pseudonyme de l'auteur
- `userId` : ID utilisateur
- `timestamp` : Date de publication
- `musicTitle` : Titre du morceau/album
- `artistName` : Nom de l'artiste
- `spotifyID` : ID Spotify
- `coverArtURL` : URL de la pochette
- `spotifyURL` : URL pour deep linking
- `isAlbum` : Type (album ou morceau)

## Contraintes et Limitations

- **Limite de partage** : 1 partage par utilisateur toutes les 24 heures
- **Pseudonyme unique** : Vérifié côté backend
- **Pas de données mockées** : Toutes les données proviennent de Spotify et Firebase

## Technologies Utilisées

- Swift 5.9+
- SwiftUI
- Firebase Firestore
- Spotify Web API
- Async/Await pour les opérations asynchrones
* : L'API Spotify utilise le flux "Client Credentials" qui ne nécessite pas d'authentification utilisateur, parfait pour la recherche de musique.

## Support

Pour toute question ou problème, consultez le guide de configuration ou vérifiez les logs de l'application.
