"""Create public update metadata from actual, signed APK artifacts."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


def create(apk_dir, tag, repository, aapt, notes, force=False):
    if repository != 'wwwpan206mr-bot/ScoreX' or not re.fullmatch(r'github-v[0-9.]+-build[0-9]+', tag):
        raise ValueError('Unexpected release identity')
    assets = {}
    version_name = None
    for abi in ['arm64-v8a', 'armeabi-v7a', 'x86_64']:
        path = Path(apk_dir) / f'app-{abi}-github-release.apk'
        content = path.read_bytes()
        if not 0 < len(content) <= 250 * 1024 * 1024:
            raise ValueError('APK size is out of range')
        info = subprocess.check_output([aapt, 'dump', 'badging', str(path)], text=True)
        package = re.search(r"package: name='([^']+)' versionCode='([0-9]+)' versionName='([^']+)'", info)
        if not package or package[1] != 'com.scorex.app.scorex':
            raise ValueError('APK package is incorrect')
        if version_name is not None and version_name != package[3]:
            raise ValueError('APK versions disagree')
        version_name = package[3]
        assets[abi] = {'url': f'https://github.com/{repository}/releases/download/{tag}/{path.name}',
                       'versionCode': int(package[2]), 'sha256': hashlib.sha256(content).hexdigest(), 'size': len(content)}
    return {'schemaVersion': 1, 'versionName': version_name, 'forceUpdate': force,
            'releaseNotes': notes, 'assets': assets}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk-dir', required=True)
    parser.add_argument('--aapt', required=True)
    parser.add_argument('--tag', required=True)
    args = parser.parse_args()
    manifest = create(args.apk_dir, args.tag, os.environ['GITHUB_REPOSITORY'], args.aapt,
                      os.environ.get('RELEASE_NOTES', '').strip() or 'ScoreX improvements and fixes.',
                      os.environ.get('FORCE_UPDATE') == 'true')
    Path('update.json').write_text(json.dumps(manifest, indent=2) + '\n')
