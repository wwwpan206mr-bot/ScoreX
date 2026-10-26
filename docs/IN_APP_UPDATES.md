# ScoreX 1.0.7 — in-app updates

## What is implemented

GitHub builds fetch `https://github.com/wwwpan206mr-bot/ScoreX/releases/latest/download/update.json` asynchronously on app launch, before authentication. Settings → App Updates also checks manually. The app compares the **actual Android versionCode**, including Flutter's ABI split offset, and chooses the first matching device ABI. A plain source commit never advertises an update.

Update now starts Android DownloadManager. Progress, retry and cancel appear in the app. Downloads continue when the app is minimized or the Flutter process is removed, subject to Android/network conditions. Completed downloads are recovered on app launch or resume. An active download opens installation automatically when complete while its prompt is visible; a restored/background download requires tapping Install update.

Android may first ask the user to enable Allow from this source for ScoreX. After returning, the APK is verified on a worker thread and opened using a restricted FileProvider content URI with a temporary read grant. Android's installer asks the user to confirm installation. There is no silent installation, browser redirect, broad storage access, or bypass of signing checks.

The app checks the APK's SHA-256, exact size, application ID, higher version code and current signing certificate. Only this repository's HTTPS release APK assets are accepted. Invalid files cannot be installed by this updater.

The `play` flavor instead uses Google Play Core immediate in-app updates. Its source set has no APK downloader, FileProvider or REQUEST_INSTALL_PACKAGES permission. Play updates require an eligible installation acquired through Google Play, a higher published Play version and a Google account able to receive it.

## Build channels

| Distribution | Build command | Update source |
| --- | --- | --- |
| GitHub | `flutter build apk --flavor github --release --split-per-abi` | Signed GitHub Release APKs |
| Google Play | `flutter build appbundle --flavor play --release` | Google Play Core |

Existing CI and startup APK filenames are updated for these flavors. APKs and AAB use the same application ID, `com.scorex.app.scorex`, but Play App Signing may use a different certificate. Updates must stay within a signing identity/distribution; the app rejects a mismatched APK rather than uninstalling the current app or deleting data.

## Publish the first usable signed update

1. Keep the **same keystore** for every GitHub APK release. Configure repository Actions secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. Use the existing signing key if the installed app was already signed with it. Never paste these values into source, public logs or chat.
2. Increase the version and build in pubspec.yaml for each release. This change starts at `1.0.7+11`.
3. Open GitHub Actions → **Publish Signed GitHub APK Update** → **Run workflow**. Supply public release notes and optionally mark a critical update as required.
4. The workflow runs analysis and Flutter tests, uses the stable signing key, builds the ABI APKs, verifies their APK signatures, and computes metadata using their real version codes, byte sizes and SHA-256 values.
5. It uploads APKs and `update.json` to a draft release, then publishes the complete release as latest. Existing tags are not overwritten. Updating code or running the normal build does not publish a release.
6. Install the first signed GitHub build once. Later higher versions signed with the same key can use the in-app flow.

The configuration-only push job reports whether signing secrets exist without exposing values. Missing secrets prevent signed publication. This repository had no GitHub Releases when this feature was implemented, so users will see no update until the first release is published.

**Important for previous development APKs:** earlier ordinary builds used the runner's temporary debug certificate. A different key cannot update those installations in place. Their original private key is needed for seamless migration; a newly generated key cannot replace that identity. Do not uninstall an old app automatically. Choose a first stable signed installation deliberately and back up anything important before a manual migration.

Optimized CI uses stable signing secrets when available; otherwise its artifacts remain development builds. Only the dedicated signed-release workflow publishes updater assets. Google Play publishing is separate and is never performed by this workflow.

## Verification and limits

Flutter tests cover ABI selection, numeric version comparisons, invalid metadata/URLs, download progress, installer handoff and restored downloads waiting for consent. Kotlin JVM tests cover trusted URLs, signing/package/version compatibility and file checksums. Python tests verify real APK metadata generation. Android CI builds both flavors, runs native tests and checks the merged Play manifest has no installer permission/provider. The startup workflow launches the GitHub release APK.

A two-version physical Android install test with the same stable certificate is still required to prove real installer approval, unknown-source permission and update completion on the target phone. Build success and mocked channel tests alone do not prove that full device flow. Android/OEM background download limits can delay transfer; retries and persisted DownloadManager state handle reconnects.
