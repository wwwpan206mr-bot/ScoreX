import 'dart:async';

/// Schedules from completion, so slow connections never stack requests.
/// Pausing cancels the next tick; resuming reuses any request still in flight.
class ScoreRefreshLoop {
  ScoreRefreshLoop({required this.load, required this.interval});
  final Future<void> Function() load;
  final Duration Function() interval;
  Timer? _timer;
  Future<void>? _inFlight;
  bool _active = false;
  bool _disposed = false;

  void start({bool immediately = true}) {
    if (_disposed || _active) return;
    _active = true;
    if (immediately) {
      unawaited(refreshNow());
    } else {
      _schedule();
    }
  }

  void pause() {
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refreshNow() {
    if (_disposed) return Future<void>.value();
    if (_inFlight != null) return _inFlight!;
    _timer?.cancel();
    // Defer load until _inFlight is assigned, including synchronous callbacks.
    final request = Future<void>.sync(load);
    final tracked = request.whenComplete(() {
      _inFlight = null;
      _schedule();
    });
    _inFlight = tracked;
    return tracked;
  }

  void _schedule() {
    _timer?.cancel();
    if (!_active || _disposed || _inFlight != null) return;
    _timer = Timer(interval(), () => unawaited(refreshNow()));
  }

  void dispose() {
    _disposed = true;
    pause();
  }
}
