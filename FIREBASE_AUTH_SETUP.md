# ScoreX accounts activation
Code supports email/password registration and login, verification email, password reset,
Firebase anonymous guests, Google sign-in with supplied profile photo, UID copy, logout,
and account deletion with reauthentication.

## Activate from your Android phone
1. Create or choose the dedicated ScoreX Firebase project.
2. Enable Authentication providers: Email/Password, Anonymous, and Google. Set the support email.
3. Register Android package com.scorex.app.scorex (confirm generated applicationId in CI).
4. Add SHA-1 and SHA-256 fingerprints for the certificate signing the APK you distribute.
   CI-generated debug keys differ between runners; use a stable signing key before Google sign-in testing/distribution.
5. Create a Web OAuth client for this Firebase project and use its client ID as googleWebClientId.
6. Set repository Actions variable FIREBASE_CONFIG_JSON with this public client configuration:
   {"apiKey":"...","appId":"...","messagingSenderId":"...","projectId":"...","googleWebClientId":"...apps.googleusercontent.com"}
   Use the Android Firebase app ID, not the Web Firebase app ID.
   No service-account private keys or OAuth client secrets belong here.
7. Run both Android workflows and install the new APK.
8. Test signup, email verification, reset email, login after restart, anonymous guest UID,
   upgrading an anonymous user with a NEW email (same UID), existing-account login,
   Google profile photo and fallback avatar, logout, and deletion with reauthentication.

Explicit FirebaseOptions and an explicit Google serverClientId are used; these flows do not
require adding the google-services Gradle plugin. Google setup must still match the real
Android package and signing certificate.

Without valid Firebase configuration the app offers a device-only guest UID. This is
clearly labelled, does not claim to be a Firebase account, and is lost if app data is cleared.
After configuration, guest access uses Firebase Anonymous Authentication; provider setup
or network failures are shown instead of silently substituting a local identity.

Google photos come from Firebase User.photoURL after Google sign-in. An arbitrary email
address does not grant access to its owner's profile photo; email/password users get a
default avatar. Cloud guest UID survives successful linking to a NEW credential; signing in
to an EXISTING account uses that existing UID. Preferences currently remain device-local.

Status: implementation committed; backend activation and real-device authentication
verification are pending until the actual Firebase client configuration is supplied.
