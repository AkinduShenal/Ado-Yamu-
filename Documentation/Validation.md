# Validation record

Validation was performed on 28 October 2026 using Xcode 27.1 (27A9275), Apple Swift 6.4, the iPhoneSimulator27.1 SDK and installed iOS 18.1 Simulator runtimes. The app’s deployment target is iOS 17.0; no iOS 17 runtime is installed on this machine.

## Build and tests

The project builds without dependency installation or signing for Simulator. The following actual build command completed successfully after implementation fixes:

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=F9376E65-95F9-4ADD-9DE5-996160AFD250' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build-for-testing
```

A full iPhone SE (3rd generation) run passed all 12 tests (8 unit/integration, 4 UI):

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=1E92BFE1-F4FA-4D88-96EA-D3262CACB18B' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/Validation-iPhoneSE.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO test
```

After correcting finding-screen text compression and expanding the no-match sheet, both affected UI flows were retested on iPhone SE and passed:

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=1E92BFE1-F4FA-4D88-96EA-D3262CACB18B' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/Validation-SmallScreenFinal.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testNoMatchCanBeRelaxedExplicitly \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testPlannerFindsLocalMatchAndMapOpens \
  CODE_SIGNING_ALLOWED=NO test
```

**Final iPhone 16 Pro result: TEST SUCCEEDED — all 12 tests passed (8 unit/integration + 4 UI), 0 failures.** Command:

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=F9376E65-95F9-4ADD-9DE5-996160AFD250' \
  -derivedDataPath build/ProFinalDerivedData \
  -resultBundlePath build/Validation-Complete.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO test
```

The separate final build directory avoids concurrent reuse of products while reviewing two simulator devices.

## What the tests verify

- Catalog IDs are unique; all 16 actual destination images exist; coordinates are within Sri Lanka’s geographic range; key districts are correct.
- Mood OR selection, budget ceilings, duration ceilings and calculated geographic radius apply together.
- No-match cases return an empty set, without quietly changing preferences.
- Empty mood selection and half-day boundaries work.
- Seeded random selection avoids recent suggestions and immediate repeats, and handles empty/single-item pools.
- Search trims whitespace, ignores case and combines district/name/category matching.
- A real on-disk SwiftData store is closed and reopened: onboarding, name, city, moods, favourites, visits, saved ideas and suggestion history persist.
- Duplicate visit and trip actions do not duplicate records; profile counts use distinct visited districts.
- Suggestions/favourites/saved trips do not award visits.
- UI onboarding, tabs, category filtering, search and empty results, saving a place, details, manual visit celebration, profile stats, passport, planner matching and native map screen work.
- An impossible city/mood/budget/time combination shows the no-match state; explicitly opening up the options produces a valid result.

## Visual inspection and fixes

Screenshots were exported from actual Simulator UI tests. See `Screenshots/index.html`. Reviewed welcome, Home, planner, finding, details, map, passport, Explore, Saved, Profile, stamp celebration and empty states on a Dynamic Island iPhone and a 4.7-inch iPhone SE.

The inspection led to full-bleed background corrections, white status-bar styling on immersive screens, a persistent planner CTA, tighter Home spacing so the Surprise card is visible, alternating passport stamps, non-compressed small-phone transition text and a scrollable no-match explanation.

Tests also caught and fixed two functional issues: SwiftData’s container needed an explicit retained lifetime, and the touch region of scaled portrait imagery needed clipping with `contentShape` so it could not intercept the search field. The city-picker UI test now scrolls the control fully above the fixed footer; iOS accessibility could otherwise report the clipped control as hittable.

Xcode may emit its informational “Metadata extraction skipped, no AppIntents.framework dependency found” warning. This app does not use App Intents. Initial failed runs are retained under `build/` for diagnosis; only the passing/final results are described as successful.

## Practical limits of validation

- Physical-device signing, real GPS fixes and permission changes, Apple Maps handoff/route calculation, notification delivery at the scheduled time and photo import from a personal library still need device QA.
- Native map rendering was observed in Simulator; no travel time or distance is invented. There is no offline map-tile package.
- The deployment target compiles for iOS 17, but runtime testing here used iOS 18.1.
- Semantic Dynamic Type and accessibility labels/traits are implemented; a full VoiceOver audit and all accessibility text sizes have not been completed.
- English is complete; reviewed Sinhala/Tamil translations are not bundled.
- Photos are one memory per visited place. No accounts, app cloud sync, camera capture, reservations, live pricing or live conditions are implemented.

The online planning checks added later are recorded at the end of this document; the original statements above describe the initial bundled-data version.

## Recurring splash update — 28 October 2026

The scenic splash now appears without a Get Started button on every cold launch and after returning from the background. It dismisses automatically after 1.6 seconds. First-time onboarding still uses Get Started once; returning users keep their completed onboarding and current navigation. Permission alerts and other inactive-only interruptions do not restart the splash. Reduced Motion removes entrance/exit movement.

Build and selected tests: **TEST SUCCEEDED, 10 tests passed** (8 existing unit/integration tests, the onboarding/favourites/visit/passport UI flow, and a new background/reopen regression test). The reopen test completes onboarding, selects Saved, backgrounds and reactivates the app, verifies the button-free splash, then verifies Saved returns without another Get Started prompt. Screenshot: `Screenshots/iPhone16Pro/Launch-splash-without-button.png`.

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=F9376E65-95F9-4ADD-9DE5-996160AFD250' \
  -derivedDataPath build/ProFinalDerivedData \
  -resultBundlePath build/Validation-RecurringSplash-Final.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuTests \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testSplashReturnsWhenReopeningAfterOnboarding \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testWelcomeHomeExploreFavoritesVisitAndPassport \
  CODE_SIGNING_ALLOWED=NO test
```

## Native iOS Launch Screen update — 28 October 2026

The green frame before SwiftUI started came from `Info.plist`'s plain-colour `UILaunchScreen` configuration. It was replaced with `UILaunchStoryboardName = LaunchScreen` and a compiled native storyboard. Its image view uses the same bundled `welcome` scenic asset, fills the entire display with aspect-fill and clips to the screen edges. The native scene contains no buttons or extra delay; the existing SwiftUI branding/splash then runs normally. Project registration was patched without regenerating or replacing Xcode signing settings. The optional project generator also includes this resource.

`xcodebuild` compiled and linked `LaunchScreen.storyboard` successfully, and the built app contains `LaunchScreen.storyboardc` with the matching Info.plist entry. Simulator installation updated the app in place, preserving its data.

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=F9376E65-95F9-4ADD-9DE5-996160AFD250' \
  -derivedDataPath build/ProFinalDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Result: **BUILD SUCCEEDED**.

## Faster branded launch — 28 October 2026

The native launch storyboard now includes the app name, pin, underline and tagline, so branding is visible while iOS initializes the app. The SwiftUI splash renders its brand at full opacity on its first frame instead of waiting for an entrance animation. Its hold was reduced from 1.6 seconds to 0.9 seconds, with a 0.15-second exit. The first-use welcome entrance was shortened to 0.2 seconds. The 0.9-second hold is app-controlled; system startup time varies by device and debugger state.

Result: **TEST SUCCEEDED — both selected UI regressions passed**, including onboarding → reopen → button-free splash → preserved Saved tab, and the full welcome/favourites/visit/passport flow. The native storyboard also compiled successfully.

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=F9376E65-95F9-4ADD-9DE5-996160AFD250' \
  -derivedDataPath build/ProFinalDerivedData \
  -resultBundlePath build/Validation-FastBrandedLaunch.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testSplashReturnsWhenReopeningAfterOnboarding \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testWelcomeHomeExploreFavoritesVisitAndPassport \
  CODE_SIGNING_ALLOWED=NO test
```

## Online nearby discovery and whole-trip planning — 28 October 2026

**Final result: TEST SUCCEEDED — 19 unit/integration tests and the online budget UI flow passed on iPhone SE (3rd generation), iOS 18.1.** This includes real disk persistence and migration from the previous four-model journal, cost/time boundaries, unknown prices/fares/routes, Colombo radius exclusion, CSV-safe recent IDs and explicit offline fallback. The final build includes the new location usage text and privacy manifest.

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=1E92BFE1-F4FA-4D88-96EA-D3262CACB18B' \
  -derivedDataPath build/OnlineDiscoveryDerivedData \
  -resultBundlePath build/Validation-OnlinePlanning-Final.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuTests \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testOnlineTripBudgetUnknownCostsAndSavedPlace \
  CODE_SIGNING_ALLOWED=NO test
```

The earlier full suite on iPhone 16 Pro passed **18 unit/integration + 6 UI tests**, with the opt-in live test skipped. The six UI tests cover the original screen gallery, no-match flow, saved ideas, recurring splash, favorite/visit/passport flow and the new online-budget flow. Result: `build/Validation-OnlineDiscovery-r1.xcresult`.

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=F9376E65-95F9-4ADD-9DE5-996160AFD250' \
  -derivedDataPath build/OnlineDiscoveryDerivedData \
  -resultBundlePath build/Validation-OnlineDiscovery-r1.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO test
```

**Real network smoke test: TEST SUCCEEDED — Colombo Apple Maps search completed inside the app**, without `--discovery-fixtures`. A real Colombo result with source/date was captured and inspected. This verifies online place retrieval, not current venue fees or route availability for every result.

```sh
TEST_RUNNER_ADO_LIVE_DISCOVERY=1 xcodebuild \
  -project AdoYamu.xcodeproj -scheme AdoYamu -configuration Debug \
  -destination 'platform=iOS Simulator,id=F9376E65-95F9-4ADD-9DE5-996160AFD250' \
  -derivedDataPath build/OnlineDiscoveryDerivedData \
  -resultBundlePath build/Validation-LiveColomboDiscovery.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testLiveColomboOnlineSearchWhenRequested \
  CODE_SIGNING_ALLOWED=NO test
```

A separate HTTPS routing probe near Colombo returned HTTP 200 and a genuine FOSSGIS/OSRM foot-route duration/distance. The app does not fabricate an ETA when either provider fails. Transit coverage and actual physical-device navigation remain unverified; the manual return-time path covers unsupported journeys.

UI screenshots were exported from XCTest and inspected on both phone sizes. The final SE captures show automatic scrolling to the newly eligible result after saving its estimates. The [gallery](Screenshots/index.html#onlineplanning) separates **Live Colombo** from **deterministic UI fixtures**. Source provenance and limits are documented in [OnlinePlanning.md](OnlinePlanning.md).

`plutil -lint` passed for the Xcode project, Info.plist and PrivacyInfo.xcprivacy. The build emits Xcode's App Intents metadata-skip message and an SDK record diagnostic about the host OS build number; neither is a source compilation or test failure. Physical GPS/permission changes, live fees/fares, venue availability and Apple Maps handoff on a real phone are not claimed as validated.


## Online flow matching the supplied offline design — 28 October 2026

The online planner now uses the same mood tiles, budget/time pills, location control and prominent Surprise Me button as Offline ideas. Detailed allowances/mode/visit length moved into Travel & spending. Both flows share `AdventureFindingScene`; online stages reflect requests rather than a timer, with Cancel and early reveal. Complete matches open Details; unresolved costs/time lead to photographic result cards with compact summaries and expandable breakdowns.

Apple Maps venues are enriched with matching reusable Wikimedia photos. The photo lookup also supplies image-backed nearby parks, lakes and cultural landmarks with their own Wikipedia source labels, filtered by the selected radius/mood. Photos are prioritized before proximity in the bounded 12-place result set. Source links, author/license credits, labelled missing-photo maps, photo enlargement, cache limits and photo handoff during navigation are implemented. No live price is fabricated.

**Final feature run: TEST SUCCEEDED — 25 unit/integration tests and 2 UI tests passed on iPhone SE (27 total, zero failures).** This includes a real Wikipedia/Commons lookup, HTTP image download and UIKit image decode for Viharamahadevi Park; live Colombo place discovery; fixture-based cost editing/favorites/detail navigation; source/identity matching; photo metadata backward compatibility and persistence; and preserving photo lookup when Details opens.

```sh
TEST_RUNNER_ADO_LIVE_PHOTOS=1 TEST_RUNNER_ADO_LIVE_DISCOVERY=1 \
  xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=1E92BFE1-F4FA-4D88-96EA-D3262CACB18B' \
  -derivedDataPath build/OnlineDiscoveryDerivedData \
  -resultBundlePath build/Validation-PhotoLandmarks-Final.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuTests \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testOnlineTripBudgetUnknownCostsAndSavedPlace \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testLiveColomboOnlineSearchWhenRequested \
  CODE_SIGNING_ALLOWED=NO test
```

Earlier checks of this redesign also passed: `Validation-OnlinePhotoFlow-Pro.xcresult` (23 unit/integration + 3 UI, including offline planner → finding → details → Map and online finding cancellation), and `Validation-OnlinePhotoFlow-SE-Final.xcresult` (24 unit/integration + 3 UI, including real Colombo search and cancellation). The added institution/event classification test accounts for the later unit-count increase.

The [gallery](Screenshots/index.html#onlinephotoflow) separates fixture screens from real network results. Native planner, shared finding and photographic cards were visually inspected on iPhone 16 Pro and iPhone SE. Fixture Park/Café use the existing bundled Galle Face photo only in opted-in DEBUG UI tests; normal discovery uses matched real venues and attributed images. The standalone real Wikimedia test image is retained in the xcresult/build attachments, not shipped as an app asset.

`plutil -lint` passed for the project, Info.plist and privacy manifest. Source compilation has no errors; Xcode still prints its App Intents metadata-skip and host SDK build-record diagnostics. Real-device GPS changes, actual venue availability/fees, live transit fares, full VoiceOver coverage and production-scale public-service capacity remain unverified. A place without a matching reusable image retains a map preview. No signing configuration was regenerated.


A final additional **live rendered-photo UI check passed** in `Validation-LivePhotoRendering.xcresult`. It starts the actual Colombo search, scrolls into the discovery cards and waits for a downloaded photo's loaded accessibility state (not merely metadata or a placeholder). The exported screenshot visibly shows the real landmark photo; it is in `Screenshots/OnlinePhotoFlowSE/Live-Colombo-discovery.png`.

```sh
TEST_RUNNER_ADO_LIVE_DISCOVERY=1 xcodebuild \
  -project AdoYamu.xcodeproj -scheme AdoYamu -configuration Debug \
  -destination 'platform=iOS Simulator,id=1E92BFE1-F4FA-4D88-96EA-D3262CACB18B' \
  -derivedDataPath build/OnlineDiscoveryDerivedData \
  -resultBundlePath build/Validation-LivePhotoRendering.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testLiveColomboOnlineSearchWhenRequested \
  CODE_SIGNING_ALLOWED=NO test
```


## Personal feelings and per-feeling preferences — 29–30 October 2026

Added the optional six-face feeling selector, per-feeling experience preferences, explainable personal matches, matching in both planners and personalized Home picks. Added two credited offline temple photographs and explicit experience metadata; the bundled catalog now has 18 places. Feeling data remains local and current-day-only, while remembered preferences can be recalled or reset. No SwiftData entities or schema fields changed: an optional Codable value extends the existing stored trip plan.

**Unit/integration result: 34 passed, 1 opt-in live photo test skipped, zero failures**, on both iPhone 16 Pro and iPhone SE. The ten new personalization tests cover different choices for the same feeling, neutral/skip behavior, remembered choices per feeling, calendar-day expiry, semantic temple matching, ranking/repeat avoidance, hard constraints, private cache keys, backward decoding and actual on-disk persistence/reset without losing favorites or onboarding.

**Personalization UI flows passed on iPhone 16 Pro.** The offline test switches Sad → Temple, Happy → Sea, back to Sad, skips/reselects and verifies a genuine bundled temple and its match explanation. The online test verifies only the chosen temple experience appears, unknown fees cannot qualify, and explicitly adding a test estimate enables Surprise Me. These online UI tests use opted-in deterministic fixtures, not live venue prices.

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=F9376E65-95F9-4ADD-9DE5-996160AFD250' \
  -derivedDataPath build/OnlineDiscoveryDerivedData \
  -resultBundlePath build/Validation-PersonalFeelings-Pro-Fixed.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuTests \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testPersonalFeelingChoicesAreRememberedAndOfflineTempleMatchWorks \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testOnlinePersonalPreferenceFiltersResultsAndKeepsUnknownCosts \
  CODE_SIGNING_ALLOWED=NO test
```

Result: **TEST SUCCEEDED — 36 passed, 1 skipped** (34 unit/integration + 2 UI passed).

On iPhone SE, the unit/integration tests and offline preference/temple UI flow passed in `Validation-PersonalFeelings-SE-Final.xcresult`. The online test in that run failed because the automation required an unnecessary footer clearance inside the estimate sheet. After using the sheet's actual scroll area, the online flow also passed in the separate result below. The app's estimate save action was functional; the test's scroll-bound assertion was corrected.

```sh
xcodebuild -project AdoYamu.xcodeproj -scheme AdoYamu \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=1E92BFE1-F4FA-4D88-96EA-D3262CACB18B' \
  -derivedDataPath build/OnlineDiscoveryDerivedData \
  -resultBundlePath build/Validation-PersonalFeelings-SE-Online-Verified.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:AdoYamuUITests/AdventureFlowTests/testOnlinePersonalPreferenceFiltersResultsAndKeepsUnknownCosts \
  CODE_SIGNING_ALLOWED=NO test
```

Result: **TEST SUCCEEDED — 1 UI test passed**. The complete small-screen offline and online flows are verified across the recorded runs. Their screenshots, including all six expression faces, selected Temple preference and result explanation, were visually inspected and added to the [gallery](Screenshots/index.html#personalfeelings).

An earlier full Pro suite also passed the existing onboarding/favorites/visits/passport, offline planner/map, no-match relaxation, splash reopening, search/category and online budget flows; the two new tests initially exposed inherited container identifiers, corrected before the passing Pro run above. The earlier suite itself is retained as a failed run, not described as fully passing.

The source-registration script was updated for Xcode's reformatted project syntax after the original script failed to register the new files. Registration now validates parsed object references and asserts that all existing build configurations remain unchanged. A second run registered zero files, confirming idempotence. `plutil -lint` passed for the project, Info.plist and privacy manifest.

No live temple-search availability, actual entrance fees, physical-device GPS or full VoiceOver audit is claimed for this feature. Existing provider/route limitations still apply; preference filtering never replaces budget/time checks. No screenshots are used as native app screens.
