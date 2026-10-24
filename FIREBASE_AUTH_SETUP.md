# ScoreX Firebase Authentication setup

ScoreX uses a dedicated Firebase project. Do not reuse another app's Firebase project.

## Android-only Firebase Console steps
1. Open https://console.firebase.google.com/ and create a project named **ScoreX** (project ID may differ if unavailable).
2. In **Build → Authentication → Sign-in method**, enable **Email/Password**.
3. In **Project settings → Your apps**, add an **Android** app. Use the real `applicationId` from `android/app/build.gradle` or `android/app/build.gradle.kts`; do not guess it.
4. Download `google-services.json` and place it at `android/app/google-services.json`. Firebase's Android configuration is not a password, but verify its project ID and package name before committing.
5. Configure FlutterFire using `flutterfire configure` in a trusted Flutter development environment to generate `lib/firebase_options.dart`. Set up the Firebase Gradle plugin per current FlutterFire instructions.
6. Add `firebase_core` and `firebase_auth` compatible with the project's Flutter/Dart SDK. Initialize Firebase before enabling the auth routes.
7. Implement registration, email verification, login, password reset, logout, auth-state routing, and account deletion with reauthentication. Guest access to cricket scores must remain available.
8. Test on Android and verify Firebase Authentication → Users. Configure authorized domains and user-data deletion/privacy disclosures before Play Store release.

**Status:** Firebase project creation, provider activation, Android registration, and credentials have not yet been completed. This file is setup documentation, not proof that authentication is live.

Never commit service-account JSON, private keys, admin SDK credentials, or passwords.
