# Design pack and bundled imagery

The original ZIP was extracted non-destructively with `unzip -n` into `DesignReference/Ado_Yamu_iOS_UI_Pack/`. The workspace originally contained no project or source files. All ten individual screens, the enlarged versions, original board, HTML gallery and CSV manifest were inspected. The enlarged versions contain the same pixels, not additional source detail.

The native implementation follows the reference palette, rounded surfaces, mood colours, photographic cards, central Surprise action, scenic welcome and green passport. It does not use screen PNGs as app views.

## Reference crop decisions

| Crops | Finding | Runtime use |
| --- | --- | --- |
| 01 Pidurangala hero | Left phone frame, low resolution; the scene is illustrative | Rejected |
| 02–03 home cards | Hearts, badges, rounded UI corners baked in | Rejected |
| 04–05 detail thumbnails | Phone frame, card edges and adjacent content | Rejected |
| 06–07 explore heroes | Prior UI rows, rounded corners, overlay icons | Rejected |
| 08–11 saved thumbnails | Large UI margins, phone border, previous row fragments | Rejected |
| 12 splash landscape excerpt | Clean illustration excerpt, but incomplete and low resolution | Style reference only |
| 13 map excerpt | Flattened fictional map, pins and invented route duration | Replaced with native MapKit |
| 14 passport badge | Flattened frame and forest surround | Reconstructed in SwiftUI |
| 15–17 achievement badges | Adjacent UI text and badge fragments | Reconstructed with SF Symbols |
| 18–21 mood crops | Baked-in backgrounds, low resolution, awkward crop edges | Reconstructed with SF Symbols |

## Final imagery

16 actual destination photographs are bundled in `AdoYamu/Resources/Assets.xcassets`, with source, author, license, changes and source coordinates (where available) in `PhotoCredits.json`. Fifteen are from Wikimedia Commons; Hiriketiya is by Malik Cil on Pexels. Credits and source/license links are also visible in Profile → About. Pidurangala uses a photograph of the view *from* Pidurangala toward Sigiriya, rather than incorrectly representing Sigiriya as Pidurangala itself.

The bundled copies and their screen crops retain their individual stated photo licenses, including applicable share-alike or Free Art License terms. Those image licenses do not constitute a license for the app source. Preserve the attribution manifest when distributing these photographs. Hiriketiya source: https://www.pexels.com/photo/aerial-view-of-hiriketiya-beach-in-sri-lanka-34218745/ ; Pexels license: https://www.pexels.com/license/ .

The welcome landscape was generated with the built-in imagegen tool and saved as `AdoYamu/Resources/Assets.xcassets/welcome.imageset/landscape.png`. The app identifies it as an illustration in About. It is also used at low opacity behind the passport and blurred behind the brief matching transition.

Generation prompt:

> Use case: illustration-story. Asset type: full-bleed portrait scenic background for a premium Sri Lankan exploration app, no UI. Create a gorgeous hand-painted editorial travel illustration of Sri Lanka at sunset, vertical 9:19 framing. Upper half: open deep violet indigo sky gently blending to coral and warm apricot sunset at horizon. Lower half: lush dark teal tropical forest silhouettes, palm trees at left, a winding golden river through layered emerald valleys, a recognizable broad Sigiriya-like rock plateau on the right in middle distance. Rich grainy painterly texture, sophisticated travel poster aesthetic, cinematic atmospheric depth. Dark leafy foreground at bottom. Reserve clear sky in upper 45% for native title overlay. No text, letters, logos, buttons, frames, phones, borders, people or watermark. Single uninterrupted landscape.

The custom map/pin app icon is drawn from vector paths in `Scripts/render_icon.swift`. Native symbols remain crisp at all display scales. No external image request is made by the app at runtime.

## Geographic references

Names, regions and obvious geography were cross-checked against Sri Lanka Tourism and source location pages; map coordinates are approximate destination pins, not surveyed entrances. The supplied mockup’s “Ranwel Ella / Kandy” label was not accepted as reliable; the implementation uses documented Ravana, Diyaluma, Bambarakanda and Dunhinda falls.

- Pidurangala: https://tourism.cp.gov.lk/en/destination/pidurangala-rock and https://www.srilanka.travel/buddhist-places/attractions.php
- Dunhinda: https://srilanka.travel/attraction?attraction_id=177
- Bambarakanda: https://srilanka.travel/attraction?attraction_id=196
- Horton Plains: https://www.srilanka.travel/attraction?attraction_id=158
- Sri Lanka Tourism destination overview: https://www.srilanka.travel/
- Nine Arch Bridge: https://en.wikipedia.org/wiki/Nine_Arch_Bridge
- Individual Wikimedia pages and available coordinates: `PhotoCredits.json`

No entrance fees, opening hours, distances by road or travel times are asserted in the dataset. Budget bands are illustrative and explicitly exclude travel. Durations are suggested time at the destination. Nearby filtering uses a labelled 120 km straight-line radius, calculated using Core Location.
# Temple photographs added 29 October 2026

Gangaramaya Temple and Sri Dalada Maligawa now have clean, locally bundled photographic assets for personal temple preferences. Both were inspected after downloading and resizing; neither contains a UI frame or generated overlay. Credits, licenses, source URLs, modification notes and coordinates are in PhotoCredits.json and About. See [Personalization.md](Personalization.md) for the source/license links.

