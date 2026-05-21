# Lockit — Build Plan & Task Checklist

## Overview
A SwiftUI "emotional vault" app. Users import photos, lock them behind a PIN sent exclusively to a trusted Guardian via email. 100% local storage. Melancholic, calm UI: warm sun header, lavender-blue gradient, script font titles.

**4 Screens:** Photo Selection → Guardian Setup → Locked (PIN entry) → Vault (gallery)

---

## Phase 1 — Design System

- [x] **T1 · Theme.swift** — Color constants, Font helpers (Snell Roundhand script), gradient definitions
- [x] **T2 · Add appheader.png to Assets.xcassets** — Create `appheader` image set, remove loose file
- [x] **T3 · Components/AppHeaderImage.swift** — Full-width sun image pinned to top, overlaps content
- [x] **T4 · Components/LockitBackground.swift** — Full-screen gradient (cream→lavender) + sun header overlay
- [x] **T5 · Components/LockitCard.swift** — White frosted RoundedRectangle card, generic ViewBuilder wrapper
- [x] **T6 · Components/LockitButton.swift** — Muted lavender capsule pill button, full-width, 56pt height
- [x] **T7 · Components/ScriptTitle.swift** — Snell Roundhand 34pt centered title

---

## Phase 2 — App State & Models

- [x] **T8 · Models/Guardian.swift** — `struct Guardian: Codable { name, email, message }`, UserDefaults persistence
- [x] **T9 · AppState.swift** — `@Observable AppState` with `AppScreen` enum: `.selectPhotos`, `.defineGuardian([PHAsset])`, `.locked(Guardian)`, `.unlocked`. Restores state from UserDefaults on launch.

---

## Phase 3 — Services

- [x] **T10 · Services/VaultManager.swift** — DocumentDirectory/Vault/, iCloud backup exclusion, `importAssets()`, `deleteFromCameraRoll()`, `listVaultItems()`
- [x] **T11 · Services/PINManager.swift** — 6-digit PIN generation, SHA-256+salt hash stored in Keychain (Security framework), `verifyPIN()`, `clearPIN()`. Plaintext never persisted.
- [x] **T12 · Services/EmailService.swift** — POST JSON `{ guardianEmail, pin, message }` to stateless serverless relay URL. PIN discarded after send.

---

## Phase 4 — Screens

- [x] **T13 · Views/PhotoSelectionView.swift** *(Screens 1 & 2)*
- [x] **T14 · Views/GuardianSetupView.swift** *(Screen 3)*
- [x] **T15 · Views/LockScreenView.swift** *(Screen 4)*
- [x] **T16 · Views/VaultView.swift** *(Unlocked gallery)*

---

## Phase 5 — Root Wiring

- [x] **T17 · ContentView.swift** — Switch on `appState.screen`, render correct view with `.animation(.easeInOut(duration: 0.5), value: appState.screen)`
- [x] **T18 · LockitApp.swift** — Instantiate `AppState()`, inject via `.environment()`
- [x] **T19 · pbxproj privacy keys** — Add `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` + `INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription` to both Debug and Release build settings

---

## Phase 6 — Polish

- [x] **T20 · Screen transitions** — `.opacity` transition, 0.5s ease, button press scale spring
- [x] **T21 · PIN shake animation** — Horizontal shake on wrong PIN, "Incorrect PIN" error text
- [x] **T22 · App deletion warning** — Alert on guardian setup confirm: "LOCKIT IS LOCAL. Deleting this app deletes your photos forever. Non-recoverable."

---

## Build Order
`T1–T7` → `T8–T9` → `T10–T12` → `T13–T16` → `T17–T19` → `T20–T22`

## Key Technical Notes
- `PBXFileSystemSynchronizedRootGroup` — any `.swift` in `Lockit/` compiles automatically, **no pbxproj edits needed for Swift files**
- Subdirectories (`Models/`, `Services/`, `Views/`, `Components/`) also auto-included
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types are MainActor by default
- PIN: only SHA-256 hash stored in Keychain, plaintext never touches UserDefaults
- Vault directory marked `isExcludedFromBackup = true` — no iCloud sync
- Serverless relay URL configured as a constant in `EmailService.swift` — must be set before ship
