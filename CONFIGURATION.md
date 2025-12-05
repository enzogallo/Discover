# Guide de Configuration - Discover

## Prérequis

1. **Compte Firebase** (gratuit)
   - Créer un projet sur [Firebase Console](https://console.firebase.google.com/)
   - Activer Firestore Database
   - Télécharger le fichier `GoogleService-Info.plist` et l'ajouter au projet Xcode

2. **Compte Spotify Developer** (gratuit)
   - Créer un compte sur [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   - Créer une nouvelle application
   - Récupérer le `Client ID` et le `Client Secret`

## Configuration Firebase

1. **Créer un projet Firebase**
   - Aller sur https://console.firebase.google.com/
   - Cliquer sur "Ajouter un projet"
   - Suivre les étapes de création

2. **Activer Firestore**
   - Dans la console Firebase, aller dans "Firestore Database"
   - Cliquer sur "Créer une base de données"
   - Choisir le mode "Production" ou "Test" (pour le développement)
   - Choisir une région (ex: europe-west)

3. **Configurer les règles de sécurité Firestore**
   - Aller dans l'onglet "Règles"
   - Utiliser les règles suivantes (pour le MVP) :
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /posts/{postId} {
         allow read: if true;
         allow write: if request.auth == null; // Pour le MVP, on autorise les écritures non authentifiées
       }
       match /users/{userId} {
         allow read: if true;
         allow write: if request.auth == null; // Pour le MVP, on autorise les écritures non authentifiées
       }
     }
   }
   ```
   ⚠️ **Note de sécurité** : Ces règles permettent à n'importe qui de lire/écrire. Pour la production, implémentez une authentification Firebase appropriée.

4. **Télécharger GoogleService-Info.plist**
   - Dans la console Firebase, aller dans "Paramètres du projet" (icône d'engrenage)
   - Dans l'onglet "Vos applications", cliquer sur l'icône iOS
   - Télécharger le fichier `GoogleService-Info.plist`
   - L'ajouter au projet Xcode (glisser-déposer dans le dossier Discover)

## Configuration Spotify

1. **Créer une application Spotify**
   - Aller sur https://developer.spotify.com/dashboard
   - Se connecter avec votre compte Spotify (gratuit)
   - Cliquer sur "Créer une application"
   - Remplir le formulaire :
     - Nom de l'application : "Discover"
     - Description : "Application de partage musical"
     - Accepter les conditions d'utilisation

2. **Récupérer les identifiants**
   - Dans le tableau de bord de votre application, vous verrez :
     - **Client ID** : une chaîne de caractères
     - **Client Secret** : cliquer sur "Afficher le secret client" pour le voir

3. **Configurer l'application**
   - Ouvrir `Discover/Services/SpotifyService.swift`
   - Remplacer `YOUR_SPOTIFY_CLIENT_ID` par votre Client ID
   - Remplacer `YOUR_SPOTIFY_CLIENT_SECRET` par votre Client Secret

## Configuration Xcode

1. **Ajouter les dépendances**
   - Ouvrir le projet dans Xcode
   - Aller dans File > Add Packages...
   - Ajouter les packages suivants :
     - `https://github.com/firebase/firebase-ios-sdk` (Firebase iOS SDK)
     - Sélectionner les produits : FirebaseFirestore, FirebaseCore

2. **Vérifier le fichier GoogleService-Info.plist**
   - S'assurer que le fichier est bien ajouté au projet
   - Vérifier qu'il est inclus dans le target "Discover"

3. **Configurer les URL Schemes (pour ouvrir Spotify)**
   - Sélectionner le projet dans le navigateur de projet
   - Aller dans l'onglet "Info"
   - Dans "URL Types", ajouter :
     - Identifier : `spotify`
     - URL Schemes : `spotify`

## Structure des données Firestore

### Collection `posts`
Chaque document contient :
- `id` (String) : ID unique du post
- `userPseudonym` (String) : Pseudonyme de l'auteur
- `userId` (String) : ID unique de l'utilisateur
- `timestamp` (Number) : Timestamp Unix (TimeInterval)
- `musicTitle` (String) : Titre du morceau/album
- `artistName` (String) : Nom de l'artiste
- `spotifyID` (String) : ID Spotify de l'œuvre
- `coverArtURL` (String) : URL de la pochette
- `spotifyURL` (String) : URL Spotify pour le deep linking
- `isAlbum` (Boolean) : true si c'est un album, false si c'est un morceau

### Collection `users`
Chaque document contient :
- `id` (String) : ID unique de l'utilisateur
- `pseudonym` (String) : Pseudonyme unique
- `createdAt` (Timestamp) : Date de création

## Index Firestore requis

Pour optimiser les requêtes, créer les index suivants dans Firestore :

1. **Collection `posts`**
   - Champ : `timestamp` (Ordre décroissant)
   - Champ : `userId` (Ordre décroissant)

2. **Collection `users`**
   - Champ : `pseudonym` (Ordre croissant)

Firestore vous proposera automatiquement de créer ces index lors de la première utilisation.

## Test de l'application

1. Lancer l'application dans le simulateur ou sur un appareil
2. Entrer un pseudonyme (3-15 caractères)
3. Rechercher un morceau ou un album
4. Partager un morceau
5. Vérifier qu'il apparaît dans le feed
6. Vérifier qu'on ne peut pas partager deux fois dans les 24h

## Dépannage

### Erreur "Firebase not configured"
- Vérifier que `GoogleService-Info.plist` est bien ajouté au projet
- Vérifier que Firebase est initialisé dans `DiscoverApp.swift`

### Erreur "Invalid Spotify credentials"
- Vérifier que les identifiants Spotify sont correctement configurés dans `SpotifyService.swift`
- Vérifier que le Client Secret est bien copié (sans espaces)

### Erreur "Permission denied" dans Firestore
- Vérifier les règles de sécurité Firestore
- S'assurer que les règles permettent la lecture/écriture

### L'application ne s'ouvre pas dans Spotify
- Vérifier que Spotify est installé sur l'appareil
- Vérifier que les URL Schemes sont configurés dans Xcode
- L'application ouvrira Spotify dans le navigateur si l'app n'est pas installée
