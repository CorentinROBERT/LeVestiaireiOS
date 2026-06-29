# Le Vestiaire (iOS)

Native iOS app for managing amateur football teams: squads, matches, availability, lineups, live events, statistics, and post-match quizzes.

**Languages:** [English](README.md) · [Français](README.fr.md)

---

## Overview

Le Vestiaire helps players and staff run their team day to day:

- **Matches** — create, prepare, start, and finish games; track score and timeline events
- **Availability** — players respond; staff can manage the roster before kickoff
- **Lineups** — build compositions from team templates (formations, substitutes, alternatives)
- **Team hub** — members, guests, invitations, season stats, rankings, and saved compositions
- **Quizzes** — post-match “find the false statements” games with leaderboards
- **Profile** — sport profile, personal stats, settings, and account management

The app talks to the Squad Locker REST API and uses Firebase for remote settings, crash reporting, and push messaging.

---

## Tech stack

| Layer | Technology |
|--------|------------|
| UI | SwiftUI |
| Architecture | MVVM (`ObservableObject` view models) |
| Networking | `URLSession`, typed endpoints, authenticated client |
| Auth | JWT (Keychain), biometric unlock |
| Backend | Squad Locker API (`api.squad-locker.com`) |
| Firebase | Core, Crashlytics, Realtime Database (remote settings), Messaging |
| Localization | French & English (`Localizable.xcstrings`, `L10n`) |
| Min deployment | iOS 26.5 |

---

## Requirements

- macOS with **Xcode** (matching the project’s iOS SDK)
- Apple Developer account (for device deployment)
- Access to the Squad Locker API (dev or production)
- Firebase project with `GoogleService-Info-dev.plist` and `GoogleService-Info-prd.plist` (included in the repo; copied at build time)

---

## Getting started

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd LeVestaire
   ```

2. Open the project in Xcode:

   ```bash
   open LeVestiaire.xcodeproj
   ```

3. Wait for Swift Package Manager to resolve dependencies (Firebase iOS SDK).

4. Select the **LeVestiaire** scheme and a simulator or device.

5. Build and run (`⌘R`).

**Debug** builds default to the **dev** API (`https://api.dev.squad-locker.com`).  
**Release** builds default to **production** (`https://api.squad-locker.com`).

---

## Project structure

```
LeVestiaire/
├── LeVestiaireApp.swift      # App entry, Firebase, localization
├── ContentView.swift         # Auth routing (landing, login, main tabs)
├── Components/               # Reusable UI (buttons, cards, fields…)
├── View/                     # SwiftUI screens & sections
│   ├── Navigation/           # Tabs: Matches, Team, Profile
│   ├── Match/                # Match list, detail, editors
│   ├── Team/                 # Squad management
│   ├── Login/ & Register/
│   └── Developer/            # Hidden developer menu
├── ViewModel/                # MVVM view models (+ domain sub-VMs)
├── Models/                   # Codable structs & domain types
├── Services/                 # API services (auth, match, team, stats…)
├── Networking/               # HTTP client, endpoints, API config
├── Localization/             # L10n helpers
├── Theme/                    # AppPalette, AppInfo
├── Resources/                # Strings, reference JSON
└── Preview/                  # SwiftUI preview data
```

### View model layout

Large screens use a **coordinator** view model plus focused sub-view models:

| Screen | Coordinator | Sub-view models |
|--------|-------------|-----------------|
| Match detail | `MatchDetailViewModel` | Quiz, Events, Statistics, Composition, Availability |
| Team | `TeamViewModel` | Stats, Invitations, Compositions, Roster |

---

## Configuration

### API environment

Switchable at runtime via the **developer menu** (5 taps on the login screen, password-protected in production):

- Production — `https://api.squad-locker.com`
- Dev — `https://api.dev.squad-locker.com`
- Custom — user-defined base URL

Settings are persisted in `UserDefaults` (`APIConfiguration`).

### Firebase

A build phase **“Copy Firebase plist”** selects:

- `GoogleService-Info-dev.plist` for Debug
- `GoogleService-Info-prd.plist` for Release

Crashlytics symbols are uploaded via the **“Upload Crashlytics dSYM”** run script.

### Remote settings

`RemoteSettingsService` reads Firebase Realtime Database for maintenance mode and forced update gates shown in `ContentView`.

---

## Localization

The app supports **French** and **English**. Language is managed by `LocalizationManager` and applied at the root via `environment(\.locale)`.

String sources:

- `Resources/Localizable.xcstrings`
- `Resources/Localization/fr.arb.json` / `en.arb.json`

---

## Main user flows

1. **Onboarding** → landing carousel → login / register → email verification → sport profile
2. **Matches tab** → list with filters → match detail (prepare / live / finished tabs)
3. **Team tab** → select squad → roster, stats, rankings, compositions
4. **Profile tab** → settings, legal documents, season stats, logout

---

## Building from the command line

```bash
./Scripts/ci_build.sh
```

Optional env vars: `CONFIGURATION=Release`, `DESTINATION='generic/platform=iOS Simulator'`.

Manual equivalent:

```bash
xcodebuild -scheme LeVestiaire \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

---

## CI / CD (GitHub Actions)

### CI — automatic build

Workflow `.github/workflows/ios-ci.yml` runs on every **push** and **pull request** to `main` or `develop`:

- `macos-26` runner + Xcode **26.5**
- Swift package resolution (Firebase)
- **Debug** and **Release** simulator builds (no signing required)

Badge (once enabled):

`![iOS CI](https://github.com/CorentinROBERT/LeVestiaireiOS/actions/workflows/ios-ci.yml/badge.svg)`

### CD — TestFlight (manual)

Workflow `.github/workflows/ios-release.yml` is triggered manually (**Actions → iOS Release → Run workflow**).

Required GitHub secrets (Settings → Secrets and variables → Actions):

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_KEY_CONTENT` | `.p8` key content, base64-encoded |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Distribution `.p12` certificate, base64-encoded |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | `.p12` password |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile for `com.corentin.robert.LeVestaire` |
| `IOS_PROVISIONING_PROFILE_NAME` | Exact profile name (e.g. `Le Vestiaire App Store`) |
| `KEYCHAIN_PASSWORD` | Temporary CI keychain password |

Assisted setup:

```bash
cp Scripts/ci-secrets.env.example Scripts/ci-secrets.local.env
# Fill ci-secrets.local.env, then:
./Scripts/configure_github_secrets.sh
```

The script base64-encodes files and pushes secrets via `gh secret set` (or prints manual instructions if `gh` is missing: `brew install gh && gh auth login`).

Locally:

```bash
bundle install
bundle exec fastlane ci      # same build as CI
bundle exec fastlane beta    # Release build + TestFlight upload
```

---

## License

Proprietary — © Corentin Robert. All rights reserved unless stated otherwise in the repository.
