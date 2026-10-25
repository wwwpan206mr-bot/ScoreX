# ScoreX API proxy

This Worker keeps the CricketData API key on the server rather than inside the Android app.

## Setup
1. Create a Cloudflare Worker named `scorex-cricket-api`.
2. Paste the contents of `worker.js` into the Worker editor and deploy it.
3. In Worker **Settings → Variables and Secrets**, add a secret named `CRICAPI_KEY` with the key from your CricketData dashboard. Do not commit the key to GitHub or paste it into chat.
4. Deploy again if Cloudflare asks you to.
5. Test `https://YOUR-WORKER.workers.dev/matches`. It should return JSON from CricketData.
6. Add the Worker URL to the GitHub Actions repository variable `API_BASE_URL` (the URL without `/matches`) when building the app.

The free CricketData plan is limited to 100 API hits/day and its terms say use is personal/non-commercial. Confirm permission or a suitable plan before monetized/public commercial release.

## Match coverage update
The Worker now follows up to three current-match pages, instead of always returning offset 0. It deduplicates match IDs and returns `coverage.partial` when a page fails or the bound is reached. `MAX_MATCH_PAGES` can be set from 1 to 4 to control request usage. Additional pages consume provider requests and share the existing 60-second cache.

For an existing Worker, replace its code with `cloudflare/worker.js` and choose **Deploy**. A GitHub commit does not deploy this Worker automatically. Keep the existing `CRICAPI_KEY` secret and Worker URL. Check `/matches` for `coverage.pagesFetched` after deployment. The app update requires installing the APK produced by the new Android build.

The `currentMatches` and `match_info` integration currently provides match summaries; it does not connect a ball-by-ball commentary endpoint. Commentary remains unavailable until a verified delivery source is integrated. Missing live/upcoming matches can also reflect provider coverage. A successful HTTP response alone does not verify freshness or complete coverage.

Run pagination tests with `node --test cloudflare/worker.test.mjs`.

