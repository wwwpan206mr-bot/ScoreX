import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from create_update_manifest import create

class ManifestTest(unittest.TestCase):
    def test_hash_size_and_actual_apk_version_code(self):
        with tempfile.TemporaryDirectory() as directory:
            for abi in ['arm64-v8a', 'armeabi-v7a', 'x86_64']:
                Path(directory, f'app-github-{abi}-release.apk').write_bytes(b'abc')
            with patch('subprocess.check_output', return_value="package: name='com.scorex.app.scorex' versionCode='2012' versionName='1.0.8'"):
                manifest = create(directory, 'github-v1.0.8-build12', 'wwwpan206mr-bot/ScoreX', 'aapt', 'Changes')
            asset = manifest['assets']['arm64-v8a']
            self.assertEqual(asset['size'], 3)
            self.assertEqual(asset['versionCode'], 2012)
            self.assertEqual(asset['sha256'], 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
            self.assertTrue(asset['url'].endswith('.apk'))
    def test_rejects_wrong_repository(self):
        with self.assertRaises(ValueError): create('.', 'github-v1.0.8-build12', 'other/repo', 'aapt', '')

if __name__ == '__main__': unittest.main()
