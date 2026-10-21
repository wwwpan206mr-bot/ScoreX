# ScoreX — Cricket Live Score

Flutter-first cricket score app: Android now, with iOS platform generation prepared for later.

## Starter features
- Premium dark-green and gold UI
- All / Live / Upcoming / Finished match filters
- Refresh button and pull-to-refresh
- CricketData current-match API through a secure Cloudflare Worker proxy
- GitHub Actions workflow to analyze, test, build, and upload a debug APK

## Build APK on your phone
1. Open the [Actions page](https://github.com/wwwpan206mr-bot/ScoreX/actions).
2. Select **ScoreX Android Build** and tap **Run workflow** (or open the run created by a push).
3. After it succeeds, open the run and scroll to **Artifacts**.
4. Download **scorex-debug-apk**.

## API setup
Follow [Cloudflare API proxy setup](cloudflare/README.md). The API key must be saved as a Cloudflare Worker secret named `CRICAPI_KEY`, not in source code or in this chat.

The CricketData free tier advertises 100 API hits/day and its terms restrict use to personal, non-commercial purposes. Confirm permission or a suitable plan before a public or monetized release.

## Current status
The starter code and build workflow have been committed. Live scores require a deployed Worker and a GitHub Actions repository variable named `API_BASE_URL` containing the Worker base URL (without `/matches`). A successful APK build alone does not prove API connectivity.
