# Online nearby planning

Implemented 28 October 2026. The planner opens in **Online nearby**. The original 16-place matcher is retained under **Offline ideas** with its narrower budget/time meaning stated on screen.

## Try it

1. Run the **AdoYamu** scheme in Xcode with **⌘R**. No key or package setup is needed.
2. Open Home’s Surprise Me entry. Select moods; deselect all for any mood.
3. Use the same mood/budget/time layout as Offline ideas. Open **Travel & spending** for an exact total, food/extras allowance, available minutes and visit length, plus Walking, Bus/train, Motorbike or Car.
4. For paid transport, enter a return-cost estimate per person including fares or fuel, parking and tolls. This allowance is applied to each result; it is not a fare quoted for that particular destination.
5. Tap Use current location, or select Colombo/another fallback city and a radius. Without GPS, the starting point is explicitly the city centre.
6. Tap **Surprise Me!**. The shared scenic Finding Adventure screen reflects actual requests and supports Cancel search or Show discoveries. There is no fake minimum wait. After the first route checks, an eligible match opens directly in Details; if costs/time remain unknown, a separate photographic discoveries screen shows counts and editable cards. More route checks and photo enrichment can finish in the background.
7. Use Edit cost / time to supply entry/activity spending. Leave unknown fees blank. Explicitly enter zero only if no entry/activity spending is planned. If no route can be calculated, enter a checked return-journey duration including waiting/transfers.
8. Surprise Me becomes available when at least one complete result fits the plan. Favorites, detail navigation, sharing, saved ideas, manual visits and passport stamps also work for discovered places.

## What a match means

```
return transport + entry/activity + food/extras <= total budget per person
outbound journey + return journey + selected visit time <= available time
```

The result must also be inside the selected straight-line radius and match any selected mood. No constraints are silently loosened. The boundary is inclusive; route seconds round up to minutes. Known over-budget or over-time results are excluded even if another field is missing. Missing amounts/routes never count as zero. “Fits your estimates” uses the user's amounts and sourced or entered travel time; it is not a live price guarantee.

Walking transport defaults to zero. Food/extras initially defaults to zero and is editable. Bus/train fares, fuel costs, tolls, admission, activity charges, opening hours and availability are **not** supplied by these APIs. The app offers venue website/phone/Apple Maps links where returned. It does not scrape search snippets or fabricate prices.

## Sources and limits

- **Apple Maps places:** `MKLocalSearch` with `MKLocalPointsOfInterestRequest`, POI categories derived from moods, followed by local distance/mood/Sri Lanka checks and deduplication. At most 12 returned places are displayed. This is a bounded provider result, not every place in an area or a guaranteed count of affordable venues. Source and fetch date are shown.
- **Photo-backed landmarks:** the same Wikipedia geographic photo lookup also supplies nearby parks, lakes, beaches, waterfalls and cultural landmarks identified by their titles. Historical attack/event articles, schools, hospitals and similar non-visitor institutions are excluded. These are shown only with a verified reusable photo and a Wikipedia source link. No district, price or access claim is inferred. The selected mood/radius still applies. Up to 12 combined results prioritize available photos, then proximity. This improves photographic coverage while keeping unphotographed Apple Maps venues available.
- **Travel time:** separate outbound/return Apple Maps requests. Transit uses the available ETA API. Motorbike uses a driving route and says so. Each leg has a seven-second timeout; cancellation propagates to MapKit.
- **Fallback routes:** HTTPS requests to FOSSGIS's OpenStreetMap/OSRM foot or car service, origin → destination → origin. Durations and distances come from its response; snapped points more than 300 m away are rejected. There is no transit fallback and no live traffic in the driving fallback. Requests use an identifying User-Agent and globally reserved slots at least 1.1 seconds apart per app process. The UI includes attribution, Fix the map and the operator information link, consistent with the [operator usage policy](https://routing.openstreetmap.de/about.html).
- **Bounded work:** at most eight automatic return routes per search, with two concurrent workers. Search and route checks can be cancelled; changing origin/moods/radius/mode discards stale results. Budget, visit time and allowances re-evaluate existing results immediately. Search/route caches last 15 minutes in memory; explicit Refresh bypasses the place-search cache.
- **Availability:** public services can be incomplete, unavailable or rate limited. The public fallback has no app-specific availability guarantee and is suitable only for light usage. Before a public launch at scale, replace it with an appropriately provisioned routing service. Missing journeys have an explicit manual-time path.
- **Images:** matching venue-name/coordinates can reuse existing bundled photos. Other results use free Wikimedia photos only when an article's name and coordinates match the venue. A bounded Wikipedia geosearch (50 articles within 10 km of the chosen start) supplies candidates. Commons file credits are fetched in batches of six. Article locations must be within 1 km of the venue and pass a conservative name-overlap check. Generic nearby images, logos/flags/SVGs, missing authors and unsupported licenses are rejected. Only recognized CC BY/CC BY-SA/CC0/public-domain licenses and Wikimedia HTTPS image hosts are accepted. Missing photos retain a labelled map preview; coverage is partial, especially for small restaurants and places outside that photo-search area.
- **Photo loading:** requests are spaced at least one second apart per process. Photo metadata caches for 24 hours in memory and persists with the destination. Downloads use a bounded 60 MB disk / 12 MB memory cache; downsampled images have a separate 24 MB cache and a 1,200-pixel limit. Detail navigation lets the requested photo lookup finish and update the open place. Results and Details link photographer, license and source; About lists cached online credits. Shared components also display photos in Explore, Saved, maps and visited stamps.

API references: [Apple POI search](https://developer.apple.com/documentation/mapkit/mklocalpointsofinterestrequest), [Apple directions](https://developer.apple.com/documentation/mapkit/mkdirections), [OSRM routing API](https://project-osrm.org/docs/v5.24.0/api/#route-service), [Wikimedia geographic search](https://www.mediawiki.org/wiki/API:Geosearch), [free page images](https://www.mediawiki.org/wiki/API:Pageimages), [file credits](https://www.mediawiki.org/wiki/API:Imageinfo).

## Storage, privacy and offline behavior

`DiscoveryJournal` adds a fifth SwiftData entity. It stores the plan, fetched place metadata and user cost/time estimates as Codable data. Existing four-entity journals migrate without losing onboarding, names or favorites, verified with an actual disk-store migration test. Favorites/visits/saved ideas resolve against both bundled and persisted online places. Cached metadata retains 150 recent unpinned places plus every favorite, visited and saved destination. Profile counts only known canonical districts; a locality or province is not counted as a district.

Manual estimates are keyed by destination, exact origin and mode so journey times cannot carry across unrelated routes. They persist but may become stale; the user must update checked prices. Route estimates and the latest assessment snapshot are session-only. Saved ideas keep their cost/time summary, while fresh planning requires a new route check or a manual time after relaunch.

Location is optional and requested only on a location-control tap. Online search sends the selected area to Apple; geographic photo lookup sends it to Wikipedia and file/credit requests use Wikimedia Commons. Fallback routing sends origin/destination coordinates to FOSSGIS. That operator states routing requests are logged; see its [service information](https://routing.openstreetmap.de/about.html). City-centre planning avoids sending GPS coordinates. The app does not send profile names, favorites or visits in these requests. The usage description, settings and privacy manifest describe location used by online functionality.

When search fails, matching cached places are shown with an explicit failure/fallback message and their source dates; nearby bundled places are used if there is no cache. Unknown fees/routes still do not qualify. Offline ideas always offers the original bundled collection. Map tiles, online discovery, route calculations and external links require connectivity.

## Files

- `Models/TripPlanning.swift`: plan, query, estimate, whole-trip assessment and SwiftData journal.
- `Services/NearbyPlaceService.swift`: Apple search, metadata conversion, country/district handling, deduplication and bounded cache.
- `Services/JourneyService.swift`: real return-trip routing, fallback, timeout, rate limiting and cache.
- `Services/PlacePhotoService.swift`: matched free images, file author/license verification and bounded requests.
- `Core/DesignSystem/AdventureFindingScene.swift`, `PlacePhotoViews.swift`: shared finding design, cached remote images and photo attribution.
- `Services/DiscoveryServices.swift`: normal provider construction; explicitly opted-in DEBUG UI-test fixtures only.
- `Features/NearbyPlanning/`: observable orchestration, planner, cost editor, result cards and attribution.
- Existing store, navigation, details/map, Explore, Saved, Passport, Profile and app schema: online destination integration.
- `Scripts/sync_project_sources.py`: project registration preserving existing signing configuration.
- `AdoYamuTests/TripPlanningTests.swift`, UI flow tests: whole-trip boundaries, unknowns, repeat IDs, disk persistence/migration, offline fallback and online flow.

## Validation

See [Validation.md](Validation.md) for exact commands and results. Screenshots are in [the local gallery](Screenshots/index.html#onlinephotoflow). UI fixture screenshots are explicitly separate from live Colombo discovery; fixtures are enabled only with both `--uitesting` and `--discovery-fixtures` in DEBUG. The photo API test downloads and decodes an actual Viharamahadevi Park photograph, and checks its author/license metadata.

Real GPS permission changes, physical-device route handoff and live transit coverage still need device QA. No claims are made about verified current admission fees or fares. The app has no keys, billing integration or app-operated backend.
