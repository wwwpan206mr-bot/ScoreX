# ScoreX: authentication repair and Google Play release
Updated 26 October 2026.

## 1. Fix Firebase settings
Open https://console.firebase.google.com/ and select scorex-c74d4.
Authentication > Sign-in method: enable Google (select support email), Anonymous, and keep Email/Password enabled.
If admin-restricted-operation continues, check Authentication settings / Identity Platform user actions for disabled end-user account creation or administrator restrictions. Do not loosen Firestore rules.

Project settings > General > Android app: verify package com.scorex.app.scorex.
Register SHA-1 and SHA-256 from the exact installed APK.
The existing Optimized Android Release workflow publishes scorex-signing-fingerprints.txt in its artifact and summary. A fingerprint from another run might not match.
Google also needs an Android OAuth client for this package/certificate and a Web OAuth client in the same project. googleWebClientId must be the Web client ID (client_type 3), never the Android client ID.
Download the refreshed google-services.json to check these values. This app initializes Firebase from assets/branding/firebase_config.json and passes serverClientId explicitly; replacing google-services.json alone does not update that asset. If GitHub variable FIREBASE_CONFIG_JSON exists, it overrides the asset and must also be updated.
Google OAuth audience configured as External/Testing may require adding your Google account as a test user.

New guest behavior: try cloud anonymous authentication for up to 12 seconds, then continue with a device-only guest ID if unavailable. The local ID is not a Firebase login and grants no protected backend access. Public scores still need an internet connection. Local guest IDs survive restarting the app but are lost when app data is removed. Signing into a real account clears the local guest ID.

## 2. Create your Play developer account
Use https://play.google.com/console/signup in Chrome (Desktop site if needed).
Choose the correct personal or organization account; pay the USD 25 one-time fee.
Complete the identity, contact and Android device verification requested by Google. Organization accounts may need organization verification/D-U-N-S.
Create app: ScoreX, English, App, Free. Accept declarations.
Do not change package com.scorex.app.scorex after creating the Play listing.

## 3. Create a permanent upload key using your Android phone
If a key was already used for a Play release, reuse it. Never replace it casually.
One Android-only option is Termux with OpenJDK available:
```sh
pkg update
pkg install openjdk-17
keytool -genkeypair -v -keystore scorex-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias scorex-upload
base64 -w 0 scorex-upload.jks > scorex-upload-base64.txt
```
If that Java package is unavailable, use the OpenJDK version currently provided by your Termux repository.
Enter strong passwords at the interactive prompts. Keep an encrypted backup of the JKS, alias and passwords. Do not send them in chat or commit them.
GitHub > ScoreX > Settings > Secrets and variables > Actions > Secrets > New repository secret:
- ANDROID_KEYSTORE_BASE64: content of scorex-upload-base64.txt
- ANDROID_KEYSTORE_PASSWORD: keystore password
- ANDROID_KEY_ALIAS: scorex-upload
- ANDROID_KEY_PASSWORD: private-key password (often the store password)
Keep API_BASE_URL as a repository variable pointing to the working proxy. Never place the cricket provider token in the APK.
The existing default workflows produce development artifacts. For Play use ONLY the Play Store Signed Release workflow added with this fix.

## 4. Build and download
Increment version in pubspec.yaml for each uploaded build; versionCode after + must exceed every previous Play upload. Current repository version must be checked before each release.
GitHub > Actions > Play Store Signed Release > Run workflow > main.
It restores platform files, configures API 36 and the upload key, analyzes/tests, and builds signed APKs plus AAB.
Download scorex-play-signed-release artifact after success. Unzip on Android.
- app-arm64-v8a-release.apk: normal ARM64 phone testing.
- app-release.aab: Play Console upload.
- scorex-signing-fingerprints.txt: register SHA-1/SHA-256 in Firebase for the APK.
Do not upload a debug-signed AAB from the other workflow.
Changing from an old development certificate can require uninstalling the earlier APK; uninstalling clears local app data. Back up anything needed first.

## 5. Internal testing and Play App Signing
Play Console > Test and release > Testing > Internal testing > Create release.
Enroll in Play App Signing; let Google manage the app signing key and use your stable key as upload key.
Upload app-release.aab and add release notes. Review and roll out to internal testing.
Play Console > App integrity / App signing: copy the APP SIGNING certificate SHA-1 and SHA-256 to Firebase Android settings. This certificate differs from the upload certificate.
For direct GitHub APKs register the upload certificate too. Internal App Sharing can use yet another certificate.
Install through the test link and verify Google, email, password reset, guest, restart persistence, sign out and account deletion. Confirm real API scores load and the app does not crash.
Inspect Play pre-launch reports, native 16 KB page-size compatibility checks and all upload warnings.

## 6. Store listing
App name: ScoreX
Short description: Cricket scores, fixtures and match scorecards in one simple app.
Describe only working features. Do not promise verified AI predictions, licensed video, notifications or ball-by-ball coverage unless actually working and supported by your feed.
Category: Sports. Support email: inf.scorex@gmail.com.
Supply an app icon (512 x 512 PNG), feature graphic (1024 x 500), and at least two genuine phone screenshots without errors or floating overlays.
Host a public privacy-policy page and account-deletion request page. In-app legal text and a private Markdown document alone do not provide the required public URLs.

## 7. App content declarations
Complete Privacy policy, App access, Ads, Content rating, Target audience, Data safety and any other forms Play Console requests.
App access: explain guest access; if reviewers need an account to test restricted features, provide a working dedicated reviewer account.
Ads: answer based on SDKs and ads actually included in this release.
Data safety: audit Firebase Auth, API/proxy logs and any analytics/ad SDKs. Assess name, email, user IDs, profile photo, diagnostics and device identifiers against actual behavior; do not select "no data collected" without checking.
Account deletion: verify the in-app delete flow and provide a public web pathway to request account AND associated data deletion. Deleting Firebase Auth alone does not remove any separately stored backend data.
Confirm rights to cricket data, team artwork and other media. Select the real intended age audience.

## 8. Closed testing and production
Personal accounts created after 13 November 2023 generally need at least 12 testers continuously opted into a closed test for 14 days before applying for production access.
Internal testing does not replace this requirement. Keep testers engaged and record issues and fixes.
After meeting the requirement, Dashboard > Apply for production; answer testing/readiness questions honestly.
When approved, create a Production release using your tested signed AAB, choose countries and pricing, complete pending dashboard tasks and submit for review.
For subsequent updates: increase versionCode, reuse upload key, test, upload AAB, and use staged rollout where available.
Never promise an approval date.

## Official references
- Firebase anonymous: https://firebase.google.com/docs/auth/flutter/anonymous-auth
- Google authentication: https://firebase.google.com/docs/auth/flutter/federated-auth
- Play registration: https://support.google.com/googleplay/android-developer/answer/6112435
- Target API: https://developer.android.com/google/play/requirements/target-sdk (API 36 for new phone apps/updates from 31 August 2026)
- Testing: https://support.google.com/googleplay/android-developer/answer/14151465
- Store assets: https://support.google.com/googleplay/android-developer/answer/9866151
- Account deletion: https://support.google.com/googleplay/android-developer/answer/13327111

Status: code and workflow preparation are separate from a successful build and on-device verification. Provider enablement, certificate registration, upload secrets, developer verification, policies and Play submission require the owner to complete console steps.
