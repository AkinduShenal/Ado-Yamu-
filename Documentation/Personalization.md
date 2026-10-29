# Personal feeling check-ins

Added 29 October 2026. Online nearby and Offline ideas share an optional **How are you feeling?** selector after the adventure mood tiles.

1. Choose the adventure type, such as Chill.
2. Select a face: Happy, Calm, Sad, Stressed, Tired or Excited.
3. Choose one or more experiences: By the sea, A temple, Green spaces, A little walk, Food & cafés or An active escape.
4. Set budget, duration and starting location, then tap Surprise Me.

Someone choosing **Sad + By the sea** receives different matches from someone choosing **Sad + A temple**. The feeling alone does not prescribe an experience. With no experience selected, the original matching remains available. **Skip** disables personal filtering; selecting that feeling later recalls its saved choices. **Reset choices**, or the Settings reset control, clears all remembered feeling/experience choices without deleting favorites, visits, onboarding or other trip preferences.

The active check-in applies only on its device-local calendar date. A new day has no active feeling until another check-in. The app keeps each feeling's explicitly selected experience preferences so they can be recalled. It does not build an emotion history or infer a person's feelings from behavior.

## Matching

- Adventure moods, budget, duration and location remain mandatory constraints. Personal experience choices add an OR filter: a place must match at least one selected experience. Constraints are never silently relaxed.
- Eligible places matching more selected experiences rank higher. Surprise Me chooses among the best matching non-recent candidates, retaining repeat avoidance. The neutral path avoids extra ranking work; scoring is computed once per candidate in the ranked list.
- Online filtering applies before result caps, photos and route checks. An explicit temple preference adds a region-bounded MapKit temple search; only place interests, not feeling labels, enter external queries. Photo-backed Wikipedia landmarks use the same local experience filter.
- Culture is not treated as synonymous with temple. Known catalog entries have explicit experience tags. Online fallback classification uses venue name and category, not descriptions mentioning nearby temples. A temple museum, a café on Temple Road and the Pidurangala hike do not qualify as temple visits.
- Missing prices and journey times remain incomplete. Feeling preferences cannot make an unverified online place qualify for a budget match.
- Home's Picked for You section uses the active choices, with proximity breaking preference ties. Result cards and Details explain matching choices with “Matches your pick”.

## Storage and privacy

`PersonalizationPreferences` is optional Codable data inside `TripPlan`, already stored in the SwiftData `DiscoveryJournal`. Existing model entities and schema are unchanged. Older plans and destination records decode without the new optional properties. Changes are saved through `ExplorerStore`, with the existing recoverable save-error alert.

Feelings and per-feeling choices stay in the device journal, subject to the iOS backup behavior already explained in Settings. Feeling labels are not included in Apple Maps requests, Wikimedia requests, journey keys, sharing or notifications. Online providers receive the selected starting area and the kind of place explicitly requested. There is no backend, analytics, psychological inference or claim that a destination changes a person's mood.

## Offline temple choices and credits

The bundled collection now has 18 destinations, including Gangaramaya Temple in Colombo and Sri Dalada Maligawa in Kandy, each with a real locally bundled photograph. Planning bands and visit lengths remain illustrative; current fees/access are not invented.

- Gangaramaya location: [official temple contact page](https://gangaramaya.com/contact/). Photo: [AKS.9955, Gangaramaya Temple](https://commons.wikimedia.org/wiki/File:Gangaramaya_Temple.JPG), [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
- Sri Dalada Maligawa location: [official temple site](https://sridaladamaligawa.lk/) and [Sri Lanka Tourism](https://srilanka.travel/buddhist-places/attractions.php). Photo: [A.Savin, Sacred Tooth Temple](https://commons.wikimedia.org/wiki/File:SL_Kandy_asv2020-01_img33_Sacred_Tooth_Temple.jpg), [Free Art License](http://artlibre.org/licence/lal/en).

Images were inspected, downsampled to 1,600 pixels and crop to fit native cards. Source, photographer, license and modification notes are bundled in PhotoCredits.json and displayed in About. Temple detail screens provide the venue website to check access.

## Main files

`Models/Personalization.swift`, shared `FeelingCheckInView`, matcher/query integration, ExplorerStore persistence helpers, online search, Home, both planners, result/detail explanations and Settings. `PersonalizationTests.swift` covers different users with the same feeling, remembering each feeling separately, expiration, skipping, experience semantics, ranking/repeats, hard constraints, legacy data and actual disk persistence. UI tests cover both planners and missing online costs. Actual commands and results are recorded in [Validation.md](Validation.md); screenshots are in [the local gallery](Screenshots/index.html#personalfeelings).
