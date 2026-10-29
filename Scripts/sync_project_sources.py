"""Add Swift sources without changing existing Xcode configuration or formatting."""
import hashlib
import json
import pathlib
import re
import subprocess

root = pathlib.Path(__file__).resolve().parents[1]
project = root / 'AdoYamu.xcodeproj/project.pbxproj'
text = project.read_text()

def parse(value):
    return json.loads(subprocess.run(['plutil', '-convert', 'json', '-o', '-', '--', '-'], input=value, text=True, capture_output=True, check=True).stdout)

def uid(key):
    return hashlib.sha1(key.encode()).hexdigest()[:24].upper()

original = parse(text)
objects = original['objects']
entries = []
additions = {}
added = 0
existing_paths = {obj.get('path') for obj in objects.values() if obj.get('isa') == 'PBXFileReference'}
for name in ['AdoYamu', 'AdoYamuTests', 'AdoYamuUITests']:
    target = next(obj for obj in objects.values() if obj.get('isa') == 'PBXNativeTarget' and obj.get('name') == name)
    phase = next(key for key in target['buildPhases'] if objects[key].get('isa') == 'PBXSourcesBuildPhase')
    group = next(key for key, obj in objects.items() if obj.get('isa') == 'PBXGroup' and obj.get('name', obj.get('path')) == name)
    for file in sorted((root / name).rglob('*.swift')):
        path = file.relative_to(root).as_posix()
        if path in existing_paths:
            continue
        ref, build = uid('file:' + path), uid('build:' + path)
        if ref in objects or build in objects:
            raise RuntimeError('Object ID collision for ' + path)
        entries += [f'\t\t{ref} = {{ isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {json.dumps(path)}; sourceTree = SOURCE_ROOT; }};',
                    f'\t\t{build} = {{ isa = PBXBuildFile; fileRef = {ref}; }};']
        additions.setdefault((group, 'children'), []).append(ref)
        additions.setdefault((phase, 'files'), []).append(build)
        added += 1

for (key, field), values in additions.items():
    pattern = r'(^[\t ]*' + key + r'(?:\s*/\*[^\n]*?\*/)?\s*=\s*\{.*?\b' + field + r'\s*=\s*\()'
    text, count = re.subn(pattern, lambda match: match.group(1) + '\n' + ''.join('\t\t\t\t' + value + ',\n' for value in values), text, count=1, flags=re.M | re.S)
    if count != 1:
        raise RuntimeError('Could not locate ' + field + ' for ' + key)

if entries:
    pattern = r'(^[\t ]*\};[\t ]*(?:\n[\t ]*)?rootObject\s*=)'
    text, count = re.subn(pattern, lambda match: '\n' + '\n'.join(entries) + '\n' + match.group(1), text, count=1, flags=re.M)
    if count != 1:
        raise RuntimeError('Could not locate project objects boundary')
    updated = parse(text)
    for key, obj in objects.items():
        if obj.get('isa') == 'XCBuildConfiguration':
            assert updated['objects'][key] == obj, 'Build settings changed unexpectedly'
    for (key, field), values in additions.items():
        assert all(value in updated['objects'][key][field] for value in values)
        assert all(value in updated['objects'] for value in values)
    project.write_text(text)
print(f'Registered {added} new Swift files; existing build settings preserved.')
