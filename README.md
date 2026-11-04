# ScoreX — Premium Cricket Companion

ScoreX is an original Flutter cricket app with Android as the first target and an architecture that can support iOS later. The visual identity uses premium dark green and gold.

## Development status

This is an active Flutter app with a Cloudflare Worker-backed CricAPI match feed. Match lists and match-centre totals refresh automatically; delivery commentary, scorecards, squads and other details are shown only when the provider returns verifiable data. No fictional scores or player statistics are generated.

### App screens and navigation prepared

- Premium home screen with search field and All / Live / Upcoming / Results filters
- Matches and locally saved Favorites navigation
- Feature pages for Live Score, Ball-by-ball Commentary, Scorecard and Statistics
- Fixtures & Series, News & Videos, Teams & Players, Rankings & Compare
- Mini score widget feature specification/screen
- Match alerts and notification preferences
- Match Centre preview with Overview, Commentary, Scorecard, Squads and Stats tabs
- Light and dark themes with locally persisted preference
- Local notification preference (this does not send push notifications yet)
- Honest empty states until a verified provider is connected
- API-neutral CricketMatch model and MatchRepository boundary
- Widget tests, Dart analyzer and GitHub Actions Android build workflow

### Provider-dependent / planned

Coverage depends on the connected cricket provider and the selected match. Delivery commentary, full scorecards, squads, player profiles, schedules, rankings, news/video feeds and provider-supplied win probability may be unavailable for some matches. The experimental chasing-side estimate is a transparent Monte Carlo model, not a trained AI model. Push notifications and a system-wide floating overlay still require additional backend/platform work. Search and status filters operate on matches returned by the feed.

## Build APK / AAB

1. Open [ScoreX GitHub Actions](https://github.com/wwwpan206mr-bot/ScoreX/actions).
2. Open the latest **ScoreX Android Build** workflow run.
3. Wait for flutter analyze, flutter test, APK build and App Bundle build to finish.
4. Download the scorex-android-builds artifact from a successful run. It contains a debug APK and a release-mode AAB.

**Play Store signing note:** The CI-generated AAB is a build artifact, not yet a Play Store publishing package. Before publishing, configure a private release keystore and signing credentials securely in GitHub Actions. Never commit the keystore or passwords to GitHub.

## Project structure

- lib/main.dart — app entry point, theme, home, settings and navigation
- lib/screens/feature_pages.dart — feature screens and API-pending states
- lib/models/cricket_match.dart — API-neutral cricket match model
- lib/data/match_repository.dart — repository boundary and empty, unconfigured implementation
- test/widget_test.dart — widget tests
- .github/workflows/android-build.yml — analyze, test, APK and AAB workflow
- cloudflare/worker.js — existing API proxy starter; not connected to the app in this phase
- cloudflare/README.md — future API proxy notes

## Later API phase

After the app UI and builds pass, connect a verified cricket provider through a Cloudflare Worker. Store provider credentials only in Cloudflare Worker Secrets; do not embed keys in Flutter or commit them to GitHub. Verify free-tier quotas, commentary/scorecard availability and provider terms before release.
