# ScoreX AdMob setup

The Android match centre has a native medium card after player figures and an anchored adaptive banner at the bottom, outside the score content. Both are labelled. Failed/no-fill ads collapse. Unsupported platforms show no ads. Existing installed APKs need a new build to receive this feature.

## Current configuration: publisher banner

All three Android workflows run `scripts/configure_ads.py` after platform generation. The committed config now includes the owner's App ID and confirmed Banner unit. Release builds use this banner by default. Native is disabled until a separate Native advanced unit is supplied. Debug builds always substitute Google test units for configured placements. Explicit ADMOB_TEST_MODE=true also creates release test builds. Test ads do not earn money. Never click your own production ads to test them.

## Enable publisher ads

1. In https://admob.google.com create/add the Android app ScoreX, package `com.scorex.app.scorex`. Choose its actual Play listing state.
2. Copy the **App ID** (contains `~`). Create one **Banner** unit and one **Native advanced** unit, and copy their unit IDs (contain `/`). These publisher IDs are not secret API keys.
3. In GitHub repository Settings → Secrets and variables → Actions → Variables add:

| Variable | Value |
|---|---|
| `ADMOB_APP_ID` | Your Android AdMob App ID |
| `ADMOB_BANNER_ID` | Banner ad unit ID |
| `ADMOB_NATIVE_ID` | Native advanced ad unit ID |
| `ADMOB_TEST_MODE` | `false` for publisher ads; `true` while testing |

4. Configure and publish applicable messages in AdMob Privacy & messaging. The app checks UMP consent on launch and only requests ads when `canRequestAds` permits it. Where required, Settings and the legal pages expose Ad privacy choices. A consent/configuration failure may leave the app ad-free.
5. Configure AdMob blocking controls to match the app's audience, including gambling/betting and other unsuitable categories. The SDK requests G-rated ad content; account-level blocking is separate. Screenshot advertisers are not bundled or guaranteed.
6. Publish the updated privacy policy at your public privacy-policy URL. Review Google Play's Contains ads, Data safety and target audience declarations against the actual SDKs/configuration. Complete app readiness/store linking and app-ads.txt verification as requested in your AdMob account.
7. Run **Play Store Signed Release** for a stable signed production build, or **Optimized Android Release** for test APKs. Download and install the new ARM64 APK on the phone. AAB is for Play Console.

For local builds run `python3 scripts/configure_ads.py` before `flutter build`. Production mode requires an App ID and at least one ad unit; unused formats remain disabled. It rejects malformed IDs, Google's test publisher ID, different publishers, and reuse of one unit across formats. Blank Actions variables preserve the committed configuration.

## Verify on an Android device

- First use a build with `ADMOB_TEST_MODE=true`. Open a match → Live and scroll below player figures: confirm the bottom test banner (native is hidden until configured), including ad attribution/AdChoices.
- Test narrow screens, landscape, large fonts, dark/light themes and navigation. Scores and controls must remain usable without overlap.
- Test offline/no-fill and consent error: score access must still work and no blank ad block should remain.
- Where a consent message applies, test it using UMP's documented debug geography/test-device settings in a development build; do not ship consent debug settings. Review privacy choices and check old ads are removed before any new consent-based requests.
- Do not judge revenue or production fill from test units. AdMob decides which eligible ad is served; banner and native formats match the reference placement, not a specific advertiser.

References:
- https://developers.google.com/admob/flutter/quick-start
- https://developers.google.com/admob/flutter/banner
- https://developers.google.com/admob/flutter/native/templates
- https://developers.google.com/admob/flutter/privacy
