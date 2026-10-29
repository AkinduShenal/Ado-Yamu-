# Ado Yamu! 🌴

A native iOS 17+ SwiftUI exploration app, reconstructed from the supplied ten-screen reference pack. Online discovery combines Apple Maps venues and photo-backed Wikipedia landmarks with return-trip budget/time checks. The bundled 18-place collection remains available offline. No app-operated backend, paid APIs, API keys or third-party dependencies.

## Open and run

1. Open `AdoYamu.xcodeproj` in Xcode.
2. Select the **AdoYamu** scheme and an iPhone simulator running iOS 17 or later.
3. Press **⌘R**. Tap **Get Started** on the first launch.
4. For a physical iPhone, select your development team under **Signing & Capabilities** and choose a unique bundle identifier if needed.
5. Press **⌘U** to run unit and UI tests. UI tests deliberately use a fresh in-memory journal via `--uitesting`; normal launches store data on disk.

No XcodeGen, package installation, API key, `.env` file or setup script is required. The shared scheme is included with the project. `Scripts/sync_project_sources.py` registers newly added Swift files without replacing signing settings. `Scripts/create_project.py` is an optional full project regenerator; running it can replace signing configuration and is not needed to build.

## Online nearby planning

Both planners now include an optional **How are you feeling?** face selector. Pair Sad, Happy or another feeling with the experience you personally want: sea, temple, greenery, a walk, food or an active escape. Choices are remembered separately for each feeling, remain on device and can be skipped/reset. Each active check-in applies today; budget, time and location limits still apply. See [Personalization.md](Documentation/Personalization.md).

Open **Home → Surprise Me → Online nearby**. The planner follows the supplied offline design: mood tiles, budget pills, time pills and location. **Travel & spending** opens the detailed budget, transport, food and visit-time controls. Tap **Surprise Me!** for the same scenic Finding Adventure design while real requests run. You can cancel or reveal discoveries early. A complete eligible match opens Details; otherwise photographic discovery cards show places needing costs/time checks. Results show the number that fit your estimates, need information, or exceed your plan.

The budget includes **return transport + entry/activity + food/extras**. Time includes **both journeys + your selected visit length**. Walking has zero transport cost; other modes need your own return fare or fuel/parking/toll estimate. Apple Maps does not supply admission prices or fares. Use **Edit cost / time** to enter checked amounts or personal estimates; unknown amounts never count as free. **Surprise Me** selects only complete, eligible results and avoids recent suggestions while alternatives exist. “Fits your estimates” is a planning result, not a guaranteed price.

Online searches return up to 12 nearby places and check up to 8 return routes. Apple Maps routing falls back to OpenStreetMap/FOSSGIS for walking/driving where available; unsupported transit journeys require a checked manual time. Motorbike times use driving routes. See [OnlinePlanning.md](Documentation/OnlinePlanning.md) for provider limits, privacy and implementation details.

## Complete screen flow

- **Splash / Welcome:** the native Launch Screen already displays the app name over the scenic image. The button-free SwiftUI splash shows its brand immediately and stays for 0.9 seconds on each launch and when returning from the background. First-time explorers then see Get Started; completion persists. Returning explorers continue directly to the app, preserving their current tab and navigation when resuming. Brief interruptions such as permission alerts do not restart the splash.
- **Home:** personalized greeting, working search, mood shortcuts, locally curated nearby cards, favourites, Surprise entry.
- **Planner:** adventure mood plus optional personal feeling/experience choices, whole-trip costs, travel/visit time, editable missing information, radius and optional current location/fallback city. Offline ideas retains the bundled catalog matcher with the same personal choices.
- **Finding:** online and offline flows share the scenic gradient, map/pin illustration and status layout. Online progress reflects actual cancellable requests with no artificial hold. Offline ideas use a cancellable 960 ms presentation of an already-computed local match; skip with “Show my match”. Reduced Motion removes movement.
- **Details:** real destination facts, planning labels, tags, photo enlargement, favourite, system share sheet, saved trip idea, manual visit, directions and another suggestion.
- **Map:** native MapKit, real destination marker, standard/satellite toggle, optional location marker, fit controls and Apple Maps handoff.
- **Passport:** forest design, earned/locked stamps, visit dates, derived progress and a spring stamp celebration.
- **Explore:** immediate text search across bundled and cached online places, real category and nearby filtering.
- **Saved:** persisted favourites and trip ideas, detail links, unfavourite/delete and empty states.
- **Profile:** derived visits/distinct districts/earned badges, passport, achievements, device-local photo memories, editable name/city, optional weekly notifications and About/credits.

## Architecture

```
AdoYamu/
  App/                         App startup, typed routes, shared navigation
  Core/DesignSystem/           Theme, buttons, chips, cards, empty states
  Models/                     Immutable destinations; SwiftData journal models
  Data/                       16-place catalog; pure search and matching
  Services/                   Journal, online search, routing, location, notifications
  Features/                   Ten screens plus supporting settings/memories/about
  Resources/                  Bundled photos, icon, privacy info and string catalog
AdoYamuTests/                  Filtering, whole-trip checks, persistence and migration
AdoYamuUITests/                End-to-end navigation, journal actions and screenshots
DesignReference/              Original supplied reference files, preserved
Documentation/                Asset audit and validation record
Scripts/                      Optional project, icon and asset preparation tools
```

`ExplorerStore` performs explicit SwiftData saves and presents a recoverable error when saving fails. Opening details, saving a favourite or generating a suggestion never awards a visit. Unique destination IDs prevent duplicate visits/favourites. Profile statistics come from visit records. Photos are downsampled before being saved as external SwiftData storage.

Online matching applies mood OR, a strict origin radius, whole-trip budget and total time. Missing fees, fares or routes remain incomplete. Offline ideas match the bundled mood, illustrative destination budget tier and visit duration; their labels explicitly exclude transport. An empty mood selection accepts all moods. Recent suggestions are avoided while alternatives exist, with immediate-repeat protection after the recent pool is exhausted. No constraints are silently relaxed.

Location is requested only on a location-button tap. Denied/unavailable location leaves the fallback city usable. Notifications are requested only when the optional reminder is enabled. Route checks begin after a user starts an online search. Travel times are sourced or manually entered, and no visits or favourites are prefilled.

## Offline and privacy

Bundled data, photography, local search/selection and the journal work without internet. Online search failures show an explicit fallback using saved or bundled places in the chosen area. Place/photo metadata and user estimates persist; routes are cached in memory for 15 minutes. Maps, online search, photo downloads, routes and external links require connectivity. Online results reuse bundled photos only for matching venues; otherwise they load identity/coordinate-matched free Wikimedia photos with author/license/source links. A labelled map preview remains when no matching photo is available. Downloaded photos use a bounded cache.

No accounts, analytics, tracking SDKs or app-operated servers. The journal stays on this installation and may be part of an iOS device backup; there is no app cloud-sync implementation. Online discovery sends your selected starting area to Apple and Wikimedia, and fallback routing sends origin/destination coordinates to FOSSGIS. FOSSGIS states that routing requests are logged; the app links its provider/privacy information. A city centre can be used instead of GPS. The privacy manifest declares unlinked location for app functionality. The system photo picker grants access only to the selected photo.

## Design, accessibility and localization

The shared design system uses warm white, violet gradients, orange accents, soft mood colours, rounded cards and a forest-green passport. Layouts use safe areas and scroll when content grows. Text uses semantic system styles, controls have accessibility labels, selection traits and Reduced Motion alternatives. English is the initial language. `Localizable.xcstrings`, English development region and Swift string extraction are configured; add reviewed Sinhala/Tamil translations and localize catalog prose before shipping those languages.

See `Documentation/AssetReview.md` for the original crop audit, generated artwork prompt and photo licenses. All bundled images have source attribution inside About. The design reference is illustrative, so the app uses accurate district names and actual destination photography instead of copying erroneous map/price labels.

## Validation

See `Documentation/Validation.md` for actual commands, results and remaining device checks.

Before an App Store submission: select the final signing team/bundle identifier, complete physical-device permission and memory-photo checks, have local reviewers verify destination access and pins, and add production translations if required. The project includes no backend, live weather, reservations, live fees or offline map tile download.
