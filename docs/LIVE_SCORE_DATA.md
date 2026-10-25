# ScoreX live match centre

Version 1.0.3 adds a Live dashboard, a separate Commentary tab, recent-delivery markers (including wickets, wides and no-balls), CRR/RRR, runs and balls needed, player tables, delayed-feed handling and an experimental win-probability model.

## What is connected now

The current `/match` route supplies CricAPI `match_info` innings totals. These supply the score, CRR and standard T20/ODI chase requirements. The app does not reconstruct balls or player figures from score changes. Summary polling remains every 30 seconds; the existing summary cache is 60 seconds. This is not a guarantee of one update per delivery.

CricketData's Fantasy documentation at https://cricketdata.org/how-to-use-fantasy-cricket-api.aspx states that Fantasy APIs require a paid plan and that using them under Lifetime Free incurs a usage penalty. No paid Fantasy calls or paid subscriptions are enabled by this change.

## Authorised ball-by-ball feed

`GET /live?id=<CricAPI match ID>` is an optional Worker adapter. With no `LIVE_FEED_URL` it returns `data: null` without contacting another provider. Existing Workers that do not have `/live` remain compatible with the updated app.

To connect delivery data, supply an authorised backend that maps its provider IDs to the requested ScoreX/CricAPI match ID and produces the schema below. Set its HTTPS URL as the Worker's `LIVE_FEED_URL`. If needed, set `LIVE_FEED_TOKEN` as a Cloudflare secret; the Worker sends it in an Authorization Bearer header. Never embed either provider keys or bearer secrets in Flutter. This is an adapter contract, not a claim that a particular provider has been connected.

The adapter appends `id` as a query parameter, uses an 8-second timeout and caches successful responses for 20 seconds. Deploy `cloudflare/worker.js` manually in the existing Worker; this repository does not currently deploy Cloudflare automatically.

### Response contract

Return an object with a `data` object containing:

| Field | Type and meaning |
| --- | --- |
| matchId | The exact requested ScoreX/CricAPI match ID |
| inningsId | Nonempty string for the active innings |
| source | Nonempty name of the authorised data source |
| updatedAt | Provider observation time as UTC ISO 8601 ending in Z; never replace with proxy fetch time |
| deliveries | Array of delivery records; may be empty when no verified delivery data exists |
| batting | Optional current-innings player rows: name, runs, balls, fours, sixes, strikeRate |
| bowling | Optional current-innings player rows: name, overs, maidens, runs, wickets, economy |

Every delivery has a stable nonempty string `id`, an integer `sequence` that increases within the innings, `inningsId`, zero-based integer `over`, ball position `ball` from 1 through 6, integer `runs`, `batterRuns`, `extras`, boolean `isWicket` and boolean `isLegalDelivery`. `runs` must equal `batterRuns + extras`. `commentary` is optional text. `extraType` may be `wide` or `noBall`.

Repeated wides/no-balls can share the same over and ball position; their IDs and sequences must remain distinct. The app deduplicates by ID and orders by sequence. It displays only the active innings and rejects malformed records or a mismatched match ID. Supply the active innings in chronological order, and include all available recent records. All player rows must describe that same active innings. Do not send demo or synthetic events as live data.

An observation older than 120 seconds is labelled delayed; win estimates are paused when delivery refresh fails or the feed is delayed. Missing or invalid source times do not produce delivery markers. The actual field update rate and match coverage depend on the authorised provider.

## Win probability: current limitations

The bundled model is **experimental Monte Carlo**, not trained AI. No OpenAI API or other paid AI API is used. For a standard T20/ODI chase after at least 12 legal balls, it uses current innings runs, wickets, balls remaining and target. Current runs per ball are smoothed with 18 balls of the first innings scoring rate when available. Wicket probability is `(wickets + 1) / (legalBalls + 24)` with bounds; a Poisson model samples runs on non-wicket legal balls. Two thousand deterministic trials produce chasing-win, defending-win and tie percentages that sum to 100. Ties refer to the innings result before any super over.

The model assumes current scoring and wicket rates remain constant. It ignores team strength, players, pitch, weather, field restrictions, tactical changes and pressure. These are model assumptions, not measured match facts. Historical accuracy and calibration have **not** been established. The app labels this beside the percentages and claims no accuracy score.

No estimate is shown for first innings, Tests, unknown teams, a missing target, completed matches, exhausted innings, or a status indicating revised/DLS conditions. Standard targets are inferred as first-innings runs plus one only for two-innings T20/ODI summaries without a revision indicator. A production trained AI model requires a licensed historical dataset, match-level train/test splits, out-of-time evaluation and calibration before its probabilities can be presented as validated predictions.

## Verification

Run `node --test cloudflare/worker.test.mjs`, `flutter analyze --no-fatal-infos`, and `flutter test`. Tests cover pagination, no paid call when unconfigured, feed ID checks, repeated wides, source timestamps, decimal overs, chase arithmetic, model limits and mobile dashboard rendering. Mocked data verifies implementation, not live provider access or forecast accuracy.
