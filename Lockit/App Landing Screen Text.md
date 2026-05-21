# Product Requirements Document: Lockit

**Project Title:** Lockit
**Version:** 1.0 (MVP)
**Status:** Draft
**Vibe:** Melancholic, respectful, calm, and protective.

## 1. Executive Summary & Problem Statement

### The Problem
When navigating a difficult separation, digital memories on a smartphone become significant sources of emotional distress. Users often face a painful choice: permanently delete cherished history to reclaim their emotional peace today, or endure constant, painful reminders in their daily camera roll. Existing hidden folder solutions are either too easily accessible or lack the protective friction required for emotional healing.

### The Solution: Lockit
Lockit provides a gentle, secure boundary between a user's daily life and their painful digital memories. It is a strictly local iOS application that stores imported media in a secure, sandboxed vault. The app utilizes a unique "Accountability Partner" mechanism. Access is granted only via a dynamic PIN which is sent exclusively to a trusted guardian via email. The user has no record of the PIN, enforcing space until the time is truly right to look back. We are passionate about creating a safe space for users, focused on smooth UI and a seamless protective experience.

## 2. Goals & Scope

### Primary Goals
1. **Guaranteed Privacy (100% Local):** All media must live entirely on the iOS device's local file system. No cloud syncing, no external databases. If the app is deleted, the data is lost.
2. **Emotional Friction (PIN Handoff):** Implement a stateless, serverless email relay mechanism to send the vault PIN exclusively to the user's chosen Guardian, removing the temptation for the user to relock immediately.
3. **Digital Decluttering (Auto-Deletion):** Automatically remove imported media from the iOS Camera Roll to ensure the daily feed is clean.
4. **Vibe Alignment:** The UI/UX must maintain a somber, respectful, and calm aesthetic.

### Scope (MVP)
* iOS native application (Swift/SwiftUI).
* Handling of high-resolution images and videos.
* Stateless PIN relay via Email only.
* Automatic deletion of original media from iOS Camera Roll.

### Out of Scope (V2+)
* Multi-guardian support.
* Biometric unlock (FaceID/TouchID).
* Panic Mode rapid close gesture.

## 3. User Flow & Feature Requirements

### 3.1 Initial Deployment: Direct Photo Selection
**Description:** The app opens directly into the core action, bypassing any philosophical onboarding. The user is immediately presented with the native iOS photo picker.
* **Action:** App start immediately triggers the native iOS `PHPickerViewController` (filtered for images and video).
* **Requirements:**
    * App must explicitly request "Full Access" to Photos on the very first open.
    * A subtle, non-intrusive system alert or persistent banner on the picker screen must notify the user: "Selected photos will be hidden and removed from your camera roll."

### 3.2 Selection Confirmation & Preview
**Description:** Review chosen media and initiate the locking process.
* **Preview:** Display a desaturated/blurred thumbnail of the last selected item.
* **Status:** Text indicating the count, e.g., "46 pictures selected."
* **Button:** "Place them in safekeeping."

### 3.3 Define Guardian
**Description:** Define who holds the key.
* **Headline:** "Choose your guardian" (in script font).
* **Input Fields:**
    * `Name of safekeeper`
    * `Email`
    * `Message` (Optional, default message included: "Hey, [MyName] is using Lockit to find some space. Please keep this safe.")
* **Action:** Tap-to-edit instructions are included.
* **Final CTA Button:** "Place them in safekeeping." (Tapping this button triggers the back-end handoff flow).

### 3.4 The Handoff (Back-end)
**Description:** This is the stateless process that occurs immediately upon tapping "Lock."
1. **PIN Generation:** iOS app locally generates a random 4 or 6-digit numeric PIN.
2. **Stateful Warning:** App must show a final, explicit warning: "LOCKIT IS SERVERLESS. If you delete this app, you delete the photos forever. Proceed?"
3. **Email Relay (POST Request):** App sends a POST request containing:
    * `GuardianEmail`
    * `GeneratedPIN`
    * `OptionalMessage`
    to a Stateless Serverless Function.
4. **Stateless Server Function:** The function uses an email API to send the PIN to the friend. The function immediately terminates and stores NO data.
5. **Device Sanitization:**
    * App immediately purges the PIN from device memory/UserDefaults.
    * App copies media to sandboxed storage directory.
    * App invokes `PHAssetChangeRequest.deleteAssets` to purge originals from Camera Roll (user confirms system prompt).
6. **App State:** App shifts to the Locked State.

### 3.5 App Lock Screen
**Description:** The screen shown upon subsequent opens or relocking.
* **Context:** Displayed information about the Guardian (e.g., "Guardian: Casey Starbird").
* **Input:** Blank entry lines for the PIN.
* **Button:** "Open the Vault."
* **Condition:** PIN is valid only until the next lock cycle. A new PIN is generated every time the vault is securely closed.

## 4. Technical Requirements (Architecture & Security)

### 4.1 Storage Strategy (100% Database-less, Local-only)
* **Media Storage:** Store imported assets directly in the iOS device's sandboxed `DocumentDirectory`.
* **Metadata:** Use native `plist` files or `UserDefaults` for simple non-media storage.
* **Backup Security:** Critical Requirement: The app must explicitly mark the sandboxed media directory as "Exclude from iCloud/iTunes Backups" via `NSURLIsExcludedFromBackupKey`. This ensures the painful memories do not inadvertently sync to iCloud Photos or appear on new devices during restores.

### 4.2 Security & Data Deletion
* **Dynamic PIN Management:** The PIN is generated locally on-device and transmitted via email. Once sent, the PIN must not sit in `UserDefaults`. It should be compared against a hashed value in the Keychain for verification, but the plaintext must never be stored. A new PIN is generated every time the app is started from a locked state.
* **Auto-Deletion Confirmation:** App MUST wait for a successful callback from `PHAssetChangeRequest.deleteAssets` BEFORE the native app officially transitions to the "Locked" state.

### 4.3 Serverless Stateless Email Relay (Technical Details)
To ensure the user cannot find the PIN in their own sent box, the app must not use `MFMailComposeViewController`. It must use an API relay.
* **Server Function:** A lightweight, stateless serverless function.
* **Email API:** Use Resend, SendGrid, or Mailgun API keys stored only on the serverless function environment variables (NEVER in the iOS app binary).
* **Data Integrity:** The function accepts JSON via POST. Once the email is passed to the API provider, the function terminates. NO logs of PINs or guardian emails may be kept.

## 5. Non-Functional Requirements (UI/UX Guidelines)

### 5.1 Aesthetic (The Vibe)
* **Palette:** Muted, low-contrast somber tones. Deep midnight blue, desaturated charcoal grays, muted lavender/light gray for buttons.
* **Typography:** The script font used for headers must look formal, respectful, and slightly melancholic, not playful or rustic.
* **Motion:** Any animations must be slow, subtle, and empathetic. No snappy transitions that break the melancholic mood.

## 6. Risks, Warnings, & Mitigation

### 6.1 Critical App Deletion Warning
The serverless, local nature creates a severe risk. If the user deletes the Lockit app, the media is gone.
* **Mitigation:** MVP must include prominent warnings on every import confirmation screen: "LOCKIT IS LOCAL. If you delete this app, you delete your safely kept photos forever. This is non-recoverable."

### 6.2 Lost Guardian
The Guardian mechanism is strict. If the Guardian loses the text with the PIN, the user is functionally locked out.
* **Mitigation (MVP):** V1 is strict. A true boundary means accepting the risk of a lost key.
