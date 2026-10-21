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
