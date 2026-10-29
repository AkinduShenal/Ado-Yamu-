"""One-time preparation of licensed bundled photos; runtime discovery has separate native services."""
import json, pathlib, time, urllib.parse, urllib.request, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'AdoYamu/Resources/Assets.xcassets'
HEADERS = {'User-Agent': 'AdoYamu/1.0 (offline SwiftUI development; photo attribution)'}
PLACES = {
    'pidurangala': 'Pidurangala Rock', 'bridge': 'Nine Arch Bridge',
    'ravana': 'Ravana Falls', 'diyaluma': 'Diyaluma Falls',
    'bambarakanda': 'Bambarakanda Falls', 'dunhinda': 'Dunhinda Falls',
    'hiriketiya': 'Hiriketiya', 'mirissa': 'Mirissa', 'unawatuna': 'Unawatuna',
    'galle': 'Galle Fort', 'kandy': 'Kandy Lake', 'horton': 'Horton Plains National Park',
    'adamspeak': "Little Adam's Peak", 'colombo': 'Galle Face Green',
    'pettah': 'Pettah, Sri Lanka', 'peradeniya': 'Royal Botanical Gardens, Peradeniya',
    'gangaramaya': 'Gangaramaya Temple', 'dalada': 'Temple of the Tooth',
}

def request(url):
    for attempt in range(3):
        try:
            return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=40).read()
        except Exception:
            if attempt == 2: raise
            time.sleep(2)

def api(base, **params):
    return json.loads(request(base + '/w/api.php?' + urllib.parse.urlencode(dict(format='json', **params))))

if '--discover' in sys.argv:
    for query in ['Hiriketiya', 'Pettah market']:
        print(query, api('https://commons.wikimedia.org', action='query', list='search', srnamespace=6, srsearch=query, srlimit=8), flush=True)
    sys.exit(0)

credits = json.loads((ROOT/'AdoYamu/Resources/PhotoCredits.json').read_text()) if (ROOT/'AdoYamu/Resources/PhotoCredits.json').exists() else []
for key, title in PLACES.items():
    if any(c['asset'] == key for c in credits): continue
    time.sleep(1)
    try:
        if key == 'hiriketiya':
            folder = ASSETS / (key + '.imageset'); folder.mkdir(parents=True, exist_ok=True)
            (folder/'photo.jpg').write_bytes(request('https://images.pexels.com/photos/34218745/pexels-photo-34218745.jpeg?auto=compress&cs=tinysrgb&w=1600'))
            (folder/'Contents.json').write_text(json.dumps({'images':[{'filename':'photo.jpg','idiom':'universal'}],'info':{'author':'xcode','version':1}}, indent=2))
            credits.append({'asset':key,'title':'Hiriketiya Beach','file':'pexels-photo-34218745.jpeg','page':'https://www.pexels.com/photo/aerial-view-of-hiriketiya-beach-in-sri-lanka-34218745/','artist':'Malik Cil','license':'Pexels License','licenseURL':'https://www.pexels.com/license/','changes':'Downsampled by Pexels; cropped to fit by SwiftUI.','coordinates':[]})
            print('OK', key, 'Pexels License', flush=True)
            continue
        page = next(iter(api('https://en.wikipedia.org', action='query', titles=title, redirects=1,
                             prop='pageimages|coordinates', pithumbsize=1400, pilicense='free')['query']['pages'].values()))
        overrides = {'pidurangala': 'Sigiriya, taken from Pidurangala Rock.jpg',
                     'adamspeak': "Little Adam's Peak in Ella.jpg",
                     'peradeniya': 'Sri Lanka, Palms in Peradeniya Botanical Gardens.jpg',
                     'pettah': 'Bags of Spices in Market - Pettah District - Colombo - Sri Lanka (13995169756).jpg'}
        if key in overrides:
            page['pageimage'] = overrides[key]
            page['thumbnail'] = {}
        if 'thumbnail' not in page:
            print('NO PHOTO', key, flush=True); continue
        filename = page['pageimage']
        metadata = next(iter(api('https://commons.wikimedia.org', action='query', titles='File:' + filename,
                                prop='imageinfo', iiprop='extmetadata|url')['query']['pages'].values()))['imageinfo'][0]
        ext = metadata['extmetadata']
        folder = ASSETS / (key + '.imageset'); folder.mkdir(parents=True, exist_ok=True)
        (folder / 'photo.jpg').write_bytes(request(metadata['url']))
        subprocess.run(['sips', '-Z', '1600', str(folder/'photo.jpg')], capture_output=True, check=True)
        (folder / 'Contents.json').write_text(json.dumps({'images': [{'filename':'photo.jpg','idiom':'universal'}],
                                                         'info':{'author':'xcode','version':1}}, indent=2))
        credits.append({'asset':key, 'title':title, 'file':filename,
                        'page':metadata['descriptionurl'],
                        'artist':ext.get('Artist',{}).get('value','See source'),
                        'license':ext.get('LicenseShortName',{}).get('value','See source'),
                        'licenseURL':ext.get('LicenseUrl',{}).get('value',''),
                        'changes':'Downsampled to max 1600px; cropped to fit by SwiftUI.',
                        'coordinates':page.get('coordinates',[])})
        print('OK', key, credits[-1]['license'], flush=True)
    except Exception as error:
        print('FAILED', key, str(error), flush=True)

(ROOT/'AdoYamu/Resources/PhotoCredits.json').write_text(json.dumps(credits, indent=2))
print('Downloaded', len(credits), 'photographs')
