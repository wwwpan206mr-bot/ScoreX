"""Configure test ads by default; production requires all publisher IDs."""
import json
import os
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
test_mode = os.environ.get('ADMOB_TEST_MODE', 'true').strip().lower() != 'false'
app_id = 'ca-app-pub-3940256099942544~3347511713'
banner_id = 'ca-app-pub-3940256099942544/9214589741'
native_id = 'ca-app-pub-3940256099942544/2247696110'
if not test_mode:
    app_id = os.environ.get('ADMOB_APP_ID', '').strip()
    banner_id = os.environ.get('ADMOB_BANNER_ID', '').strip()
    native_id = os.environ.get('ADMOB_NATIVE_ID', '').strip()
    for name, value, separator in [('ADMOB_APP_ID', app_id, '~'), ('ADMOB_BANNER_ID', banner_id, '/'), ('ADMOB_NATIVE_ID', native_id, '/')]:
        if not re.fullmatch(r'ca-app-pub-\d{16}' + re.escape(separator) + r'\d{10}', value):
            raise SystemExit(f'{name} is missing or invalid; keep ADMOB_TEST_MODE=true until configured')
        if '3940256099942544' in value:
            raise SystemExit(f'{name} must use your publisher ID in production')
    if len({v.split('/')[0].split('~')[0] for v in [app_id, banner_id, native_id]}) != 1:
        raise SystemExit('AdMob IDs must belong to the same publisher')
(root / 'assets/ads').mkdir(parents=True, exist_ok=True)
(root / 'assets/ads/config.json').write_text(json.dumps({'testMode': test_mode, 'bannerId': banner_id, 'nativeId': native_id}) + '\n')
resource = root / 'android/app/src/main/res/values/ads.xml'
resource.parent.mkdir(parents=True, exist_ok=True)
resource.write_text(f'<resources>\n    <string name="admob_app_id" translatable="false">{app_id}</string>\n</resources>\n')
print('AdMob: test ads configured' if test_mode else 'AdMob: publisher placements configured')
