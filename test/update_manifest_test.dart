import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/services/update_manifest.dart';

Map<String, dynamic> metadata({int code = 2012, String? url, String? hash, int size = 1000}) => {
  'schemaVersion': 1, 'versionName': '1.0.8', 'forceUpdate': false,
  'assets': {'arm64-v8a': {'versionCode': code, 'size': size,
    'url': url ?? 'https://github.com/wwwpan206mr-bot/ScoreX/releases/download/github-v1.0.8-build12/app-github-arm64-v8a-release.apk',
    'sha256': hash ?? List.filled(64, 'a').join()}}};

void main() {
  test('selects the device ABI and compares actual Android version codes', () {
    final update = ApkUpdate.select(metadata(), ['arm64-v8a', 'armeabi-v7a'], 2011);
    expect(update?.versionCode, 2012);
    expect(ApkUpdate.select(metadata(code: 2011), ['arm64-v8a'], 2011), isNull);
    expect(ApkUpdate.select(metadata(code: 12), ['arm64-v8a'], 2011), isNull);
    expect(ApkUpdate.select(metadata(), ['x86_64'], 11), isNull);
  });
  test('rejects artifacts, foreign repos, malformed hashes and unreasonable sizes', () {
    for (final url in [
      'https://github.com/wwwpan206mr-bot/ScoreX/actions/artifacts/123',
      'https://github.com/other/ScoreX/releases/download/v1/app.apk',
      'http://github.com/wwwpan206mr-bot/ScoreX/releases/download/v1/app.apk',
      'https://github.com/wwwpan206mr-bot/ScoreX/releases/download/v1/app.zip',
      'https://github.com/wwwpan206mr-bot/ScoreX/releases/download/v1/app.apk?redirect=evil',
    ]) { expect(ApkUpdate.select(metadata(url: url), ['arm64-v8a'], 1), isNull); }
    expect(ApkUpdate.select(metadata(hash: 'bad'), ['arm64-v8a'], 1), isNull);
    expect(ApkUpdate.select(metadata(size: 0), ['arm64-v8a'], 1), isNull);
    expect(ApkUpdate.select(metadata(size: 300 * 1024 * 1024), ['arm64-v8a'], 1), isNull);
  });
  test('legacy placeholders and unpublished metadata cannot prompt a fake update', () {
    expect(ApkUpdate.select({'latestVersion': '99.0.0'}, ['arm64-v8a'], 1), isNull);
  });
}
