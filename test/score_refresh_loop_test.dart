import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/services/score_refresh_loop.dart';

void main() {
  testWidgets('slow requests coalesce, then poll from completion', (tester) async {
    var calls = 0;
    final pending = Completer<void>();
    final loop = ScoreRefreshLoop(load: () { calls++; return calls == 1 ? pending.future : Future<void>.value(); },
      interval: () => const Duration(seconds: 8));
    loop.start();
    loop.refreshNow();
    await tester.pump(const Duration(seconds: 40));
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 7));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 2);
    loop.dispose();
  });

  testWidgets('pause stops network polling, resume fetches immediately', (tester) async {
    var calls = 0;
    final loop = ScoreRefreshLoop(load: () async { calls++; }, interval: () => const Duration(seconds: 8));
    loop.start();
    await tester.pump();
    loop.pause();
    await tester.pump(const Duration(minutes: 2));
    expect(calls, 1);
    loop.start();
    await tester.pump();
    expect(calls, 2);
    loop.dispose();
    await tester.pump(const Duration(minutes: 2));
    expect(calls, 2);
  });

  testWidgets('resuming during a request shares it and schedules the next tick', (tester) async {
    var calls = 0;
    final pending = Completer<void>();
    final loop = ScoreRefreshLoop(load: () { calls++; return calls == 1 ? pending.future : Future<void>.value(); },
      interval: () => const Duration(seconds: 8));
    loop.start();
    loop.pause();
    loop.start();
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(calls, 2);
    loop.dispose();
  });
}
