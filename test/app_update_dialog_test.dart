import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/services/update_manifest.dart';
import 'package:scorex/widgets/app_update_dialog.dart';

void main() {
  const channel = MethodChannel('scorex/update-test');
  const update = ApkUpdate(versionName: '1.0.8', versionCode: 2012,
    url: 'https://github.com/wwwpan206mr-bot/ScoreX/releases/download/v1/app.apk',
    sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', size: 1000,
    notes: 'Faster scores', mandatory: false);

  testWidgets('download shows progress and opens the installer after completion', (tester) async {
    var state = 'idle';
    var installs = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'download') { state = 'downloading'; return null; }
      if (call.method == 'install') { installs++; return {'state': 'installer'}; }
      if (call.method == 'progress') return {'state': state, 'url': update.url, 'received': 500, 'total': 1000};
      return null;
    });
    await tester.pumpWidget(const MaterialApp(home: AppUpdateDialog(update: update, channel: channel)));
    await tester.pump();
    await tester.tap(find.text('Update now'));
    await tester.pump();
    expect(find.text('Downloading 50%'), findsOneWidget);
    state = 'ready';
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();
    expect(installs, 1);
    expect(find.text('Install update'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(installs, 1); // No repeated installer popups while returning from Android.
    await tester.pumpWidget(const SizedBox());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('a restored completed download waits for the user to confirm install', (tester) async {
    var installs = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'install') { installs++; return {'state': 'permission'}; }
      if (call.method == 'progress') return {'state': 'ready', 'url': update.url, 'received': 1000, 'total': 1000};
      return null;
    });
    await tester.pumpWidget(const MaterialApp(home: AppUpdateDialog(update: update, channel: channel)));
    await tester.pump();
    expect(installs, 0);
    await tester.tap(find.text('Install update'));
    await tester.pump();
    expect(installs, 1);
    expect(find.text('Allow installation'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
}
