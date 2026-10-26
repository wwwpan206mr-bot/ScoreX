# ScoreX 1.0.6 — automatic scores

Rounded, fully tappable match boxes include series headings, team badges, innings scores and LIVE / SAVED state. A selected card's received score appears immediately while details connect. Changed totals animate for 200 ms; reduced motion disables animations.

The match list waits 10 seconds between completed requests when live fixtures exist, otherwise 30 seconds. The match centre waits 8 seconds for a live match, otherwise 30 seconds. Failures retain scores and back off. Both loops pause in the background and reconnect on resume; the home loop pauses while a match is open. Slow requests never stack. Previous-match responses are ignored.

Identical summaries skip score rebuilds, storage writes and probability calculation. Statistical estimates run outside the Android UI isolate. Totals and optional deliveries load independently in parallel. A missing delivery provider is retried once per minute.

## Source freshness and deployment

HTTP polling cannot make the provider publish data sooner. Ball-by-ball and player figures require the existing authorised LIVE_FEED_URL adapter. No missing deliveries, player figures or prediction inputs are invented.

The Worker adds optional cache settings:

| Variable | Default | Allowed seconds |
| --- | --- | --- |
| MATCH_CACHE_SECONDS | 60 | 10–300 |
| LIVE_CACHE_SECONDS | 20 | 5–60 |

Keep defaults for limited free quota. Lower TTL increases provider requests. Errors use no-store and upstream requests have timeouts.

Deploy cloudflare/worker.js to the existing Cloudflare Worker to apply server changes. GitHub commits alone do not deploy the Worker. Android layout and automatic polling work with the existing API, subject to its cache and coverage.

## Verification

Node tests cover pagination, feed identity, bounded cache settings and non-cached failures. Flutter tests cover request coalescing, pause/resume, immediate scores, parallel endpoints and late responses from a previous match. Existing narrow-screen, large-text and reduced-motion tests remain.

Android CI runs Dart analysis and Flutter tests. Optimized release is also gated by these checks before packaging. Physical-device profile traces are needed to measure actual frame latency, memory and power usage; zero lag or provider latency is not guaranteed.

App update publication metadata stays unchanged until a downloadable release exists.
