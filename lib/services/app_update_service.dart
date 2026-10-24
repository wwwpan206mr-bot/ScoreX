import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public release metadata. Only publish links to trusted, signed releases.
/// GitHub commits are NOT releases; update this manifest after publishing a build.
class AppUpdateService {
  static final Uri manifest = Uri.parse(
    'https://raw.githubusercontent.com/wwwpan206mr-bot/ScoreX/main/app-update.json',
  );

  static int _compare(String a, String b) {
    final left = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final right = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final x = i < left.length ? left[i] : 0;
      final y = i < right.length ? right[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  static Future<void> check(BuildContext context, {bool silent = false}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final response = await http.get(manifest).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) throw Exception('Update server unavailable');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = data['latestVersion'] as String? ?? info.version;
      if (_compare(latest, info.version) <= 0) {
        if (context.mounted && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ScoreX is up to date (v${info.version}).')),
          );
        }
        return;
      }
      final urlText = data['downloadUrl'] as String? ?? '';
      final uri = Uri.tryParse(urlText);
      // Allow only HTTPS links to the Play Store or the project's own GitHub releases.
      if (uri == null || uri.scheme != 'https' ||
          !(uri.host == 'play.google.com' ||
            (uri.host == 'github.com' && uri.path.startsWith('/wwwpan206mr-bot/ScoreX/releases/')))) {
        throw Exception('No verified release URL');
      }
      if (!context.mounted) return;
      final mandatory = data['forceUpdate'] == true;
      await showDialog<void>(
        context: context,
        barrierDismissible: !mandatory,
        builder: (dialogContext) => PopScope(
          canPop: !mandatory,
          child: AlertDialog(
            title: const Text('ScoreX update available'),
            content: Text('Version $latest is available.\n\n${data['releaseNotes'] ?? 'Improvements and fixes.'}'),
            actions: [
              if (!mandatory) TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () async {
                  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!opened && dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Could not open the update link.')),
                    );
                  }
                },
                child: const Text('Update now'),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (context.mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check for updates. Try again later.')),
        );
      }
    }
  }
}
