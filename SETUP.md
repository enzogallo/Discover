# Configuration des clés API

Ce projet nécessite des fichiers de configuration contenant vos clés API personnelles. Ces fichiers ne doivent **jamais** être commités sur git.

## Fichiers à configurer

### 1. GoogleService-Info.plist (Firebase)

1. Copiez le fichier d'exemple :
   ```bash
   cp Discover/GoogleService-Info.plist.example Discover/GoogleService-Info.plist
   ```

2. Ouvrez `Discover/GoogleService-Info.plist` et remplacez toutes les valeurs `VOTRE_*` par vos vraies clés Firebase depuis la console Firebase.

### 2. Config.plist (Spotify)

1. Copiez le fichier d'exemple :
   ```bash
   cp Discover/Config.plist.example Discover/Config.plist
   ```

2. Ouvrez `Discover/Config.plist` et remplacez :
   - `VOTRE_CLIENT_ID_SPOTIFY` par votre Client ID Spotify
   - `VOTRE_CLIENT_SECRET_SPOTIFY` par votre Client Secret Spotify

   Vous pouvez obtenir ces clés sur : https://developer.spotify.com/dashboard

## Vérification

Assurez-vous que les fichiers suivants sont bien ignorés par git :
- `Discover/GoogleService-Info.plist`
- `Discover/Config.plist`

Les fichiers `.example` peuvent être commités car ils ne contiennent pas de vraies clés.

## Important

⚠️ **Ne jamais commiter** les fichiers contenant vos vraies clés API. Ils sont automatiquement ignorés par `.gitignore`.

