# ScoreX — Premium Live Cricket Score App

ScoreX is a Flutter-first cricket app project. Android is the first target; the code is structured so iOS can be added later.

## Current development phase

The current phase builds and validates the app interface before connecting a live cricket API.

### Included in the app UI
- Original ScoreX dark-green and gold branding
- Light and dark theme
- Matches and Favorites navigation
- Search field and Live / Upcoming / Results filter controls
- Honest empty state when live data is not connected
- Settings page
- Saved appearance and notification preferences on the device
- Match-centre feature previews for live score, commentary, scorecard and statistics
- Widget tests and GitHub Actions Android debug build workflow

**Important:** Live scores, real ball-by-ball commentary, scorecards, team data and push notifications are not connected yet. ScoreX intentionally does not display invented match data.

## Build a debug APK

1. Open https://github.com/wwwpan206mr-bot/ScoreX/actions.
2. Open the latest ScoreX Android Build run (or manually start the workflow).
3. Wait for dependency installation, flutter analyze, tests and APK build to finish.
4. If successful, open the run and download the scorex-debug-apk artifact.

A successful workflow run is required before treating the APK as build-ready.

## Next phase: live cricket API

Once the UI and Android build are verified, connect a suitable cricket data provider through a Cloudflare Worker. Keep API credentials in Cloudflare Worker Secrets, never in the app or Git history. Confirm the provider's free-tier quotas, available commentary/scorecard endpoints, and permitted use before public release.

## Project layout

- lib/main.dart — app entry point, home screen, settings and feature UI
- test/widget_test.dart — widget tests
- .github/workflows/android-build.yml — automated analyze, test and debug APK build
- cloudflare/worker.js — existing API proxy starter, to be reviewed and connected in the API phase
- cloudflare/README.md — existing API proxy setup notes
