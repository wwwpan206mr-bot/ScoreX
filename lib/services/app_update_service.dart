import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_update_dialog.dart';
import 'update_manifest.dart';

class AppUpdateService {
  static const channel = MethodChannel('scorex/updates');
  static final manifest = Uri.parse('https://github.com/wwwpan206mr-bot/ScoreX/releases/latest/download/update.json');
  static bool _checking = false;
  static DateTime? _lastSilentCheck;

  static Future<void> check(BuildContext context, {bool silent = false, bool resumeDownload = false}) async {
    if (_checking) return;
    if (silent && !resumeDownload && _lastSilentCheck != null && DateTime.now().difference(_lastSilentCheck!).inMinutes < 15) return;
    _checking = true;
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) throw StateError('App updates are available on Android.');
      final platform = await channel.invokeMapMethod<String, dynamic>('platform');
      if (platform?['distribution'] == 'play') {
        final update = await channel.invokeMapMethod<String, dynamic>('checkPlay');
        if (!context.mounted) return;
        if (update?['available'] == true) {
          await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
            title: const Text('ScoreX update available'),
            content: const Text('Download and install the latest version through Google Play.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Later')),
              FilledButton(onPressed: () async {
                try {
                  await channel.invokeMethod('startPlay');
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (_) {
                  if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Google Play could not start the update. Please try again.')));
                }
              }, child: const Text('Update now'))],
          ));
        } else if (!silent) {
          _message(context, 'No newer Google Play update is available.');
        }
      } else {
        final response = await http.get(manifest, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 404) {
          if (context.mounted && !silent) _message(context, 'No signed GitHub update has been published yet.');
          return;
        }
        if (response.statusCode != 200 || response.bodyBytes.length > 100000) throw const FormatException('Update metadata unavailable');
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) throw const FormatException('Invalid update metadata');
        final abis = (platform?['abis'] as List? ?? const []).whereType<String>().toList();
        final installed = (platform?['versionCode'] as num?)?.toInt();
        if (installed == null) throw StateError('Installed version could not be verified.');
        final update = ApkUpdate.select(Map<String, dynamic>.from(decoded), abis, installed);
        if (!context.mounted) return;
        if (update == null) {
          if (!silent) _message(context, 'No newer compatible signed APK is available for this device.');
          return;
        }
        await showDialog<void>(context: context, barrierDismissible: !update.mandatory,
          builder: (_) => AppUpdateDialog(update: update, channel: channel));
      }
      if (silent) _lastSilentCheck = DateTime.now();
    } catch (_) {
      if (context.mounted && !silent) _message(context, 'Could not check for updates. Check your connection and try again.');
    } finally { _checking = false; }
  }

  static Future<void> resumePending(BuildContext context) async {
    if (_checking || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final job = await channel.invokeMapMethod<String, dynamic>('progress');
      if (context.mounted && job?['state'] == 'ready') await check(context, silent: true, resumeDownload: true);
    } catch (_) { /* Play builds intentionally expose no APK download channel. */ }
  }

  static void _message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/// Sits above authentication so an update check never depends on login.
class AppUpdateHost extends StatefulWidget {
  const AppUpdateHost({super.key, required this.child});
  final Widget child;
  @override
  State<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends State<AppUpdateHost> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppUpdateService.check(context, silent: true);
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _resume();
  }
  Future<void> _resume() async {
    await AppUpdateService.resumePending(context);
    if (mounted) await AppUpdateService.check(context, silent: true);
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  Widget build(BuildContext context) => widget.child;
}
