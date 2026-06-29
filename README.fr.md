# Le Vestiaire (iOS)

Application iOS native pour gérer des équipes de football amateur : effectif, matchs, disponibilités, compositions, événements live, statistiques et quiz post-match.

**Langues :** [English](README.md) · [Français](README.fr.md)

---

## Aperçu

Le Vestiaire aide les joueurs et le staff au quotidien :

- **Matchs** — créer, préparer, démarrer et terminer les rencontres ; score et fil d’événements
- **Disponibilités** — réponse des joueurs ; gestion du effectif par le staff avant le coup d’envoi
- **Compositions** — feuilles de match à partir de modèles d’équipe (formations, remplaçants, alternatives)
- **Équipe** — membres, invités, invitations, stats de saison, classements et compositions enregistrées
- **Quiz** — jeux « trouvez les fausses affirmations » après match, avec classement
- **Profil** — profil sportif, stats personnelles, réglages et gestion du compte

L’app communique avec l’API REST Squad Locker et s’appuie sur Firebase pour les réglages distants, le crash reporting et la messagerie push.

---

## Stack technique

| Couche | Technologie |
|--------|-------------|
| UI | SwiftUI |
| Architecture | MVVM (`ObservableObject`) |
| Réseau | `URLSession`, endpoints typés, client authentifié |
| Auth | JWT (Keychain), déverrouillage biométrique |
| Backend | API Squad Locker (`api.squad-locker.com`) |
| Firebase | Core, Crashlytics, Realtime Database (réglages distants), Messaging |
| Localisation | Français & anglais (`Localizable.xcstrings`, `L10n`) |
| Déploiement min. | iOS 26.5 |

---

## Prérequis

- macOS avec **Xcode** (SDK iOS aligné sur le projet)
- Compte Apple Developer (déploiement sur appareil)
- Accès à l’API Squad Locker (dev ou production)
- Projet Firebase avec `GoogleService-Info-dev.plist` et `GoogleService-Info-prd.plist` (présents dans le dépôt ; copiés à la compilation)

---

## Démarrage rapide

1. Cloner le dépôt :

   ```bash
   git clone <url-du-depot>
   cd LeVestaire
   ```

2. Ouvrir le projet dans Xcode :

   ```bash
   open LeVestiaire.xcodeproj
   ```

3. Laisser Swift Package Manager résoudre les dépendances (Firebase iOS SDK).

4. Sélectionner le schéma **LeVestiaire** et un simulateur ou un appareil.

5. Compiler et lancer (`⌘R`).

En **Debug**, l’API par défaut est **dev** (`https://api.dev.squad-locker.com`).  
En **Release**, c’est la **production** (`https://api.squad-locker.com`).

---

## Structure du projet

```
LeVestiaire/
├── LeVestiaireApp.swift      # Point d’entrée, Firebase, localisation
├── ContentView.swift         # Routage auth (landing, login, onglets)
├── Components/               # UI réutilisable (boutons, cartes, champs…)
├── View/                     # Écrans & sections SwiftUI
│   ├── Navigation/           # Onglets : Matchs, Équipe, Profil
│   ├── Match/                # Liste, détail, éditeurs
│   ├── Team/                 # Gestion d’équipe
│   ├── Login/ & Register/
│   └── Developer/            # Menu développeur masqué
├── ViewModel/                # View models MVVM (+ sous-VM par domaine)
├── Models/                   # Structs Codable & types métier
├── Services/                 # Services API (auth, match, team, stats…)
├── Networking/               # Client HTTP, endpoints, config API
├── Localization/             # Helpers L10n
├── Theme/                    # AppPalette, AppInfo
├── Resources/                # Chaînes, JSON de référence
└── Preview/                  # Données pour previews SwiftUI
```

### Organisation des view models

Les écrans complexes utilisent un view model **coordinateur** et des sous-view models par domaine :

| Écran | Coordinateur | Sous-view models |
|--------|--------------|------------------|
| Détail match | `MatchDetailViewModel` | Quiz, Events, Statistics, Composition, Availability |
| Équipe | `TeamViewModel` | Stats, Invitations, Compositions, Roster |

---

## Configuration

### Environnement API

Modifiable à l’exécution via le **menu développeur** (5 appuis sur l’écran de connexion, protégé par mot de passe en production) :

- Production — `https://api.squad-locker.com`
- Dev — `https://api.dev.squad-locker.com`
- Personnalisé — URL de base libre

Les réglages sont persistés dans `UserDefaults` (`APIConfiguration`).

### Firebase

La phase de build **« Copy Firebase plist »** sélectionne :

- `GoogleService-Info-dev.plist` en Debug
- `GoogleService-Info-prd.plist` en Release

Les symboles Crashlytics sont envoyés via le script **« Upload Crashlytics dSYM »**.

### Réglages distants

`RemoteSettingsService` lit Firebase Realtime Database pour le mode maintenance et les mises à jour forcées affichés dans `ContentView`.

---

## Localisation

L’application est disponible en **français** et en **anglais**. La langue est gérée par `LocalizationManager` et appliquée à la racine via `environment(\.locale)`.

Sources des chaînes :

- `Resources/Localizable.xcstrings`
- `Resources/Localization/fr.arb.json` / `en.arb.json`

---

## Parcours utilisateur principaux

1. **Onboarding** → carrousel d’accueil → connexion / inscription → vérification e-mail → profil sportif
2. **Onglet Matchs** → liste avec filtres → détail (onglets préparation / live / terminé)
3. **Onglet Équipe** → choix de l’équipe → effectif, stats, classements, compositions
4. **Onglet Profil** → réglages, documents légaux, stats de saison, déconnexion

---

## Compilation en ligne de commande

```bash
./Scripts/ci_build.sh
```

Variables optionnelles : `CONFIGURATION=Release`, `DESTINATION='generic/platform=iOS Simulator'`.

Équivalent manuel :

```bash
xcodebuild -scheme LeVestiaire \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

---

## CI / CD (GitHub Actions)

### CI — build automatique

Le workflow `.github/workflows/ios-ci.yml` tourne sur chaque **push** et **pull request** vers `main` ou `develop` :

- Runner `macos-26` + Xcode **26.5**
- Résolution des packages Swift (Firebase)
- Build **Debug** et **Release** pour simulateur (sans certificat)

Badge à ajouter dans le README une fois activé :

`![iOS CI](https://github.com/CorentinROBERT/LeVestiaireiOS/actions/workflows/ios-ci.yml/badge.svg)`

### CD — TestFlight (manuel)

Le workflow `.github/workflows/ios-release.yml` se lance à la main (**Actions → iOS Release → Run workflow**).

Secrets GitHub à configurer (Settings → Secrets and variables → Actions) :

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_KEY_ID` | Key ID de la clé API App Store Connect |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_KEY_CONTENT` | Contenu du fichier `.p8` encodé en base64 |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Certificat Distribution `.p12` en base64 |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Mot de passe du `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Profil App Store du bundle `com.corentin.robert.LeVestaire` |
| `IOS_PROVISIONING_PROFILE_NAME` | Nom exact du profil (ex. `Le Vestiaire App Store`) |
| `KEYCHAIN_PASSWORD` | Mot de passe temporaire du trousseau CI |

Configuration assistée :

```bash
cp Scripts/ci-secrets.env.example Scripts/ci-secrets.local.env
# Remplir ci-secrets.local.env puis :
./Scripts/configure_github_secrets.sh
```

Le script encode les fichiers en base64 et pousse les secrets via `gh secret set` (ou affiche les instructions si `gh` n'est pas installé : `brew install gh && gh auth login`).

En local :

```bash
bundle install
bundle exec fastlane ci      # même build que la CI
bundle exec fastlane beta    # build Release + upload TestFlight
```

---

## Licence

Propriétaire — © Corentin Robert. Tous droits réservés sauf mention contraire dans le dépôt.
