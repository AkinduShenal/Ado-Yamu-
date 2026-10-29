"""Create a local gallery from exported XCTest PNG attachments."""
import json, pathlib, shutil
ROOT = pathlib.Path(__file__).resolve().parents[1]
BASE = ROOT / 'Documentation/Screenshots'
for source, device in [
    ('build/UITestAttachments-Complete', 'iPhone16Pro'),
    ('build/UITestAttachments-SE', 'iPhoneSE'),
    ('build/UITestAttachments-SE-Final', 'iPhoneSE'),
    ('build/OnlinePlanningScreenshots', 'OnlinePlanningFixturePro'),
    ('build/LiveColomboScreenshots', 'LiveColombo'),
    ('build/OnlinePlanningSEAttachments', 'OnlinePlanningFixtureSE'),
    ('build/OnlinePlanningFinalScreenshots', 'OnlinePlanningFixtureSE'),
    ('build/OnlinePhotoFlowProAttachments', 'OnlinePhotoFlowPro'),
    ('build/OnlinePhotoFlowSEAttachments', 'OnlinePhotoFlowSE'),
    ('build/PhotoLandmarksFinalAttachments', 'OnlinePhotoFlowSE'),
    ('build/LivePhotoRenderingAttachments', 'OnlinePhotoFlowSE'),
    ('build/PersonalFeelingsProAttachments', 'PersonalFeelingsPro'),
    ('build/PersonalFeelingsSEAttachments', 'PersonalFeelingsSE'),
    ('build/PersonalFeelingsSEOnlineVerifiedAttachments', 'PersonalFeelingsSE'),
]:
    folder = ROOT/source
    if not (folder/'manifest.json').exists(): continue
    target = BASE/device; target.mkdir(parents=True, exist_ok=True)
    for suite in json.loads((folder/'manifest.json').read_text()):
        for attachment in suite['attachments']:
            if attachment['exportedFileName'].endswith('.png'):
                filename = attachment['suggestedHumanReadableName'].split('_0_')[0]+'.png'
                if filename.startswith('Live-Wikimedia-'): continue
                if device.startswith('PersonalFeelings') and not filename.startswith('Personal-feeling-'): continue
                shutil.copy2(folder/attachment['exportedFileName'], target/filename)

parts = ['''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ado Yamu — Native simulator screenshots</title><style>body{margin:0;background:#faf8f4;color:#151727;font:16px -apple-system,BlinkMacSystemFont,sans-serif}main{max-width:1450px;margin:auto;padding:40px 24px}h1{font-size:36px;margin:0 0 12px}p{color:#6d6d7c;line-height:1.6}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:24px}.card{background:white;padding:14px;border-radius:24px;box-shadow:0 6px 22px #1517270c}.card img{width:100%;border-radius:18px;border:1px solid #eee;display:block}.card b{display:block;margin:14px 0 3px}.tabs a{display:inline-block;margin:5px 10px 25px 0;padding:12px 18px;color:white;background:#643df5;border-radius:30px;text-decoration:none}a{color:#643df5}small{color:#797984}</style></head><body><main><h1>Ado Yamu! 🌴</h1><p>Actual native SwiftUI screens captured in the iOS Simulator.<br>The saved-place and visited-place examples were created by the automated UI tests.</p><div class="tabs"><a href="#iphone16pro">iPhone 16 Pro</a><a href="#iphonese">iPhone SE</a></div>''']
for device, title, anchor in [('iPhone16Pro','iPhone 16 Pro','iphone16pro'), ('iPhoneSE','iPhone SE (3rd generation)','iphonese')]:
    parts.append(f'<h2 id="{anchor}">{title}</h2><div class="grid">')
    for path in sorted((BASE/device).glob('*.png')):
        label = path.stem.replace('-', ' ')
        parts.append(f'<div class="card"><a href="{device}/{path.name}"><img loading="lazy" src="{device}/{path.name}" alt="{label}"></a><b>{label}</b><small>iOS Simulator · native views</small></div>')
    parts.append('</div>')
parts.append('<h2 id="onlineplanning">Online nearby planning</h2><p>The live Colombo capture uses real Apple Maps search. The other captures use explicitly opted-in deterministic UI-test places and routes, not verified venue prices.</p>')
for device, title, caption in [
    ('LiveColombo', 'Real network — Colombo search', 'Apple Maps results · iPhone 16 Pro · prices and route availability not guaranteed'),
    ('OnlinePlanningFixturePro', 'Budget UI — iPhone 16 Pro', 'Deterministic test places/routes · user-entered estimates'),
    ('OnlinePlanningFixtureSE', 'Budget UI — iPhone SE', 'Deterministic test places/routes · user-entered estimates'),
]:
    parts.append(f'<h3>{title}</h3><div class="grid">')
    for path in sorted((BASE/device).glob('*.png')):
        label = path.stem.replace('-', ' ')
        parts.append(f'<div class="card"><a href="{device}/{path.name}"><img loading="lazy" src="{device}/{path.name}" alt="{label}"></a><b>{label}</b><small>{caption}</small></div>')
    parts.append('</div>')
parts.append('<h2 id="onlinephotoflow">Online flow — matching the offline design</h2><p>Planner pills and mood tiles, the shared scenic Finding Adventure screen, and large photographic discovery cards. Fixture Park/Café screenshots use a bundled image for deterministic UI testing. Live Colombo uses real Apple Maps; the standalone Viharamahadevi image is a real Wikimedia download test attachment, not an app screen.</p>')
for device, title in [('OnlinePhotoFlowPro', 'iPhone 16 Pro'), ('OnlinePhotoFlowSE', 'iPhone SE — final')]:
    parts.append(f'<h3>{title}</h3><div class="grid">')
    for path in sorted((BASE/device).glob('*.png')):
        if path.name.startswith('Live-Wikimedia-'): continue
        label = path.stem.replace('-', ' ')
        caption = 'Real Apple Maps / Wikipedia search' if path.name.startswith('Live-Colombo') else 'Native UI test · fixture places/routes where labelled'
        parts.append(f'<div class="card"><a href="{device}/{path.name}"><img loading="lazy" src="{device}/{path.name}" alt="{label}"></a><b>{label}</b><small>{caption}</small></div>')
    parts.append('</div>')
parts.append('<h2 id="personalfeelings">Personal feeling check-ins</h2><p>Optional expression faces and remembered experience choices. A Sad check-in can prefer a temple or the sea according to the user’s own choice. Online Fixture Temple is a deterministic UI-test venue; its amounts are not real admission prices.</p>')
for device, title in [('PersonalFeelingsPro', 'iPhone 16 Pro'), ('PersonalFeelingsSE', 'iPhone SE')]:
    parts.append(f'<h3>{title}</h3><div class="grid">')
    for path in sorted((BASE/device).glob('*.png')):
        label = path.stem.replace('-', ' ')
        parts.append(f'<div class="card"><a href="{device}/{path.name}"><img loading="lazy" src="{device}/{path.name}" alt="{label}"></a><b>{label}</b><small>Native mood UI · explicit preferences · on-device storage</small></div>')
    parts.append('</div>')
parts.append('</main></body></html>')
(BASE/'index.html').write_text(''.join(parts))
print('Gallery saved:', BASE/'index.html')
