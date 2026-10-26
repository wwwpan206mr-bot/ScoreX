"""Check the actual merged Play release manifest after building the AAB."""
from pathlib import Path
import xml.etree.ElementTree as ET

manifests = [p for p in Path('build/app/intermediates').rglob('AndroidManifest.xml')
             if 'playRelease' in str(p) and 'merged_manifest' in str(p)]
if not manifests:
    raise SystemExit('No merged Play release manifest found; cannot verify permissions')
name = '{http://schemas.android.com/apk/res/android}name'
for path in manifests:
    root = ET.parse(path).getroot()
    assert not any(node.get(name) == 'android.permission.REQUEST_INSTALL_PACKAGES'
                   for node in root.findall('uses-permission')), f'APK install permission found in {path}'
    assert not any(node.get(name, '').endswith('UpdateFileProvider')
                   for node in root.findall('./application/provider')), f'APK FileProvider found in {path}'
print('PASS: merged Play manifest has no APK install permission or update FileProvider')
