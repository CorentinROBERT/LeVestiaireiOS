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
xcodebuild -scheme LeVestiaire \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build
```

Remplacer `Debug` par `Release` pour une build de configuration production.

---

## Licence

Propriétaire — © Corentin Robert. Tous droits réservés sauf mention contraire dans le dépôt.
