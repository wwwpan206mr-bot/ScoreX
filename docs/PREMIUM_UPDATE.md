# ScoreX 1.1.0

A coordinated visual and usability update that preserves existing cricket data integration, authentication, account deletion, favourites, legal pages, update checks and configured banner placement.

- Consistent emerald, mint and gold Material 3 theme across light/dark modes, with readable scores and larger touch controls.
- Match overview with actionable Live, Upcoming and Following counts. Search and status filters remain available. Home highlights four matches; Matches contains the entire filtered feed.
- Match cards include status, team monograms, tabular score figures, local fixture date/time, favourites and the provider's result.
- Lazily built match rows and a two-column layout on larger screens; compact navigation on narrow screens/large fonts. Motion respects the device's reduce-animation setting.
- Last received public match snapshot stored locally. Failed refresh retains scores with a Saved label and the original receipt timestamp. It does not turn past values into live data. Settings can clear the snapshot independently of favourites.
- Compact date navigation in Fixtures & Series, calendar picker, Today shortcut and a correction so manually refreshed fixtures replace the initial feed.
- Account form spacing and autofill grouping; authentication logic unchanged. Settings switches now update immediately and the installed app version is read from package metadata.

Validation includes existing tests and additional cache, failed-refresh, small-screen/large-text and settings-state regression tests. Real-device ad fill and sign-in depend on provider configuration and cannot be verified by widget tests.

The app continues to use the supported stable Flutter channel. Compatible dependency updates resolve within the existing constraints; authentication major versions are retained to preserve working Google/email/guest login. Social, licensed videos, push delivery and richer cricket fields remain dependent on their respective services and are not simulated.
