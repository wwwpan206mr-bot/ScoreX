/// Release metadata contains direct APK assets, never Actions ZIP archives.
class ApkUpdate {
  const ApkUpdate({required this.versionName, required this.versionCode,
    required this.url, required this.sha256, required this.size, required this.notes, required this.mandatory});
  final String versionName, url, sha256, notes;
  final int versionCode, size;
  final bool mandatory;

  static ApkUpdate? select(Map<String, dynamic> json, List<String> abis, int installedCode) {
    if (json['schemaVersion'] != 1 || json['assets'] is! Map) return null;
    final assets = json['assets'] as Map;
    Map? selected;
    for (final abi in [...abis, 'universal']) {
      if (assets[abi] is Map) { selected = assets[abi] as Map; break; }
    }
    if (selected == null) return null;
    final code = selected['versionCode'];
    final bytes = selected['size'];
    final url = selected['url'];
    final hash = selected['sha256'];
    if (code is! int || code <= installedCode || bytes is! int || bytes <= 0 || bytes > 250 * 1024 * 1024 ||
        url is! String || hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host != 'github.com' || uri.hasPort ||
        uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
        !RegExp(r'^/wwwpan206mr-bot/ScoreX/releases/download/[^/]+/[^/]+\.apk$').hasMatch(uri.path) ||
        uri.pathSegments.any((segment) => segment == '.' || segment == '..')) return null;
    return ApkUpdate(versionName: '${json['versionName'] ?? 'New release'}', versionCode: code,
      url: url, sha256: hash, size: bytes, notes: '${json['releaseNotes'] ?? 'Improvements and fixes.'}',
      mandatory: json['forceUpdate'] == true);
  }

  Map<String, Object> get arguments => {'url': url, 'sha256': sha256, 'size': size, 'versionCode': versionCode};
}
