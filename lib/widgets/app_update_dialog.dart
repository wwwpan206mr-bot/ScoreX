import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/update_manifest.dart';

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({super.key, required this.update, required this.channel});
  final ApkUpdate update;
  final MethodChannel channel;
  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> with WidgetsBindingObserver {
  Timer? _timer;
  String _state = 'idle';
  String? _error;
  double? _progress;
  bool _busy = false, _querying = false, _authorized = false, _waitingForPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll();
    _startTimer();
  }
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 750), (_) => _poll());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      _poll();
      if (_waitingForPermission) {
        _waitingForPermission = false;
        _install();
      }
    } else { _timer?.cancel(); }
  }
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _poll() async {
    if (_querying || _busy || !mounted) return;
    _querying = true;
    try {
      final data = await widget.channel.invokeMapMethod<String, dynamic>('progress');
      if (!mounted || data == null || data['url'] != widget.update.url) return;
      final state = data['state'] as String? ?? 'idle';
      final received = (data['received'] as num?)?.toDouble() ?? 0;
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : null;
      if (_state != 'permission' && _state != 'installer' && (_state != state || _progress != progress)) {
        setState(() { _state = state; _progress = progress;
          if (state == 'failed') _error = 'Download failed. Check available storage and your connection, then retry.';
        });
      }
      if (state == 'ready' && _authorized && _state != 'permission' && _state != 'installer') {
        _authorized = false;
        await _install();
      }
    } catch (_) { /* A transient progress query should not cancel an OS download. */ }
    finally { _querying = false; }
  }

  Future<void> _download() async {
    setState(() { _busy = true; _error = null; });
    try {
      await widget.channel.invokeMethod('download', widget.update.arguments);
      if (mounted) setState(() { _state = 'downloading'; _authorized = true; });
    } on PlatformException catch (e) {
      if (mounted) setState(() { _state = 'failed'; _error = e.message ?? 'Could not start the download.'; });
    } finally { if (mounted) setState(() => _busy = false); }
    await _poll();
  }

  Future<void> _install() async {
    if (_busy || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      final result = await widget.channel.invokeMapMethod<String, dynamic>('install');
      if (mounted) setState(() => _state = '${result?['state'] ?? 'ready'}');
    } on PlatformException catch (e) {
      if (mounted) setState(() { _state = 'ready'; _error = e.message ?? 'Could not open the Android installer.'; });
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _allow() async {
    _waitingForPermission = true;
    try { await widget.channel.invokeMethod('allowInstalls'); }
    on PlatformException catch (e) {
      _waitingForPermission = false;
      if (mounted) setState(() => _error = e.message ?? 'Could not open installation settings.');
    }
  }

  Future<void> _cancel() async {
    try { await widget.channel.invokeMethod('cancel'); }
    catch (_) { if (mounted) setState(() => _error = 'Could not cancel the download.'); }
    finally { if (mounted) setState(() { _state = 'idle'; _authorized = false; _progress = null; _error = null; }); }
  }

  @override
  Widget build(BuildContext context) {
    final downloading = _state == 'downloading' || _state == 'paused';
    return PopScope(canPop: !widget.update.mandatory && !_busy, child: AlertDialog(
      title: const Text('ScoreX update available'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Version ${widget.update.versionName} • ${(widget.update.size / 1048576).toStringAsFixed(1)} MB'),
        const SizedBox(height: 12), Text(widget.update.notes),
        if (downloading) ...[
          const SizedBox(height: 20), LinearProgressIndicator(value: _progress), const SizedBox(height: 8),
          Text(_state == 'paused' ? 'Waiting for a connection…' : _progress == null ? 'Downloading in the background…' : 'Downloading ${(_progress! * 100).round()}%'),
        ],
        if (_state == 'permission') ...[
          const SizedBox(height: 16),
          const Text('Allow ScoreX to install this update in Android settings, then return here. Android will ask you to confirm installation.'),
        ],
        if (_state == 'ready' || _state == 'installer') ...[
          const SizedBox(height: 12), const Text('Download complete. Android will verify the APK and ask you to confirm the update.'),
        ],
        if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ])),
      actions: [
        if (downloading) TextButton(onPressed: _busy ? null : _cancel, child: const Text('Cancel download')),
        if (!widget.update.mandatory) TextButton(onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(downloading ? 'Continue in background' : 'Later')),
        if (!downloading) FilledButton(onPressed: _busy ? null : _state == 'permission' ? _allow
            : _state == 'ready' || _state == 'installer' ? _install : _download,
          child: Text(_state == 'permission' ? 'Allow installation' : _state == 'ready' || _state == 'installer' ? 'Install update' : _state == 'failed' ? 'Retry download' : 'Update now')),
      ],
    ));
  }
}
