import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionTile extends StatefulWidget {
  const AppVersionTile({super.key});
  @override
  State<AppVersionTile> createState() => _AppVersionTileState();
}

class _AppVersionTileState extends State<AppVersionTile> {
  String _version = 'Cricket, in focus.';
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'Version ${info.version} • Build ${info.buildNumber}');
    } catch (_) { /* Version metadata is optional on unsupported hosts. */ }
  }
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(
      'assets/branding/scorex_logo.png', width: 44, height: 44, fit: BoxFit.cover)),
    title: const Text('ScoreX Cricket'), subtitle: Text(_version),
  ));
}
