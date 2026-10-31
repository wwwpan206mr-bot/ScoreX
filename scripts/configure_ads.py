"""Use committed AdMob placements; optional Actions variables override them."""
import json
import os
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
config_path = root / 'assets/ads/config.json'
config = json.loads(config_path.read_text()) if config_path.exists() else {}

def setting(name, fallback):
    value = os.environ.get(name, '').strip()
    return value if value else fallback

mode = setting('ADMOB_TEST_MODE', str(config.get('testMode', True))).lower()
if mode not in ('true', 'false'):
    raise SystemExit('ADMOB_TEST_MODE must be true or false')
test_mode = mode == 'true'
app_id = setting('ADMOB_APP_ID', config.get('appId', ''))
banner_id = setting('ADMOB_BANNER_ID', config.get('bannerId', ''))
native_id = setting('ADMOB_NATIVE_ID', config.get('nativeId', ''))
interstitial_id = setting('ADMOB_INTERSTITIAL_ID', config.get('interstitialId', ''))
rewarded_id = setting('ADMOB_REWARDED_ID', config.get('rewardedId', ''))
if test_mode:
    app_id = 'ca-app-pub-3940256099942544~3347511713'
    banner_id = 'ca-app-pub-3940256099942544/9214589741'
    # Only enable native if a native placement has been configured.
    native_id = 'ca-app-pub-3940256099942544/2247696110' if native_id else ''
    interstitial_id = 'ca-app-pub-3940256099942544/1033173712' if interstitial_id else ''
    rewarded_id = 'ca-app-pub-3940256099942544/5224354917' if rewarded_id else ''
else:
    if not any([banner_id, native_id, interstitial_id, rewarded_id]):
        raise SystemExit('Configure at least one ad unit')
    for name, value, separator in [('ADMOB_APP_ID', app_id, '~'), ('ADMOB_BANNER_ID', banner_id, '/'), ('ADMOB_NATIVE_ID', native_id, '/'), ('ADMOB_INTERSTITIAL_ID', interstitial_id, '/'), ('ADMOB_REWARDED_ID', rewarded_id, '/')]:
        if name != 'ADMOB_APP_ID' and not value:
            continue
        if not re.fullmatch(r'ca-app-pub-\d{16}' + re.escape(separator) + r'\d{10}', value):
            raise SystemExit(f'{name} is missing or invalid')
        if '3940256099942544' in value:
            raise SystemExit(f'{name} must use your publisher ID in production')
    ids = [value.split('/')[0].split('~')[0] for value in [app_id, banner_id, native_id, interstitial_id, rewarded_id] if value]
    if len(set(ids)) != 1:
        raise SystemExit('AdMob IDs must belong to the same publisher')
    unit_ids = [value for value in [banner_id, native_id, interstitial_id, rewarded_id] if value]
    if len(set(unit_ids)) != len(unit_ids):
        raise SystemExit('Each AdMob format requires a separate ad unit ID')
    if banner_id and banner_id == native_id:
        raise SystemExit('Banner and native require separate ad unit IDs')
config_path.parent.mkdir(parents=True, exist_ok=True)
config_path.write_text(json.dumps({'testMode': test_mode, 'appId': app_id, 'bannerId': banner_id, 'nativeId': native_id, 'interstitialId': interstitial_id, 'rewardedId': rewarded_id}) + '\n')
resource = root / 'android/app/src/main/res/values/ads.xml'
resource.parent.mkdir(parents=True, exist_ok=True)
resource.write_text(f'<resources>\n    <string name="admob_app_id" translatable="false">{app_id}</string>\n</resources>\n')
print('AdMob: test ads configured' if test_mode else 'AdMob: publisher placements configured')
