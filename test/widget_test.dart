import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorex/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('ScoreX home screen shows branding and honest API status', (tester) async {
    await tester.pumpWidget(const ScoreXApp());
    await tester.pumpAndSettle();

    expect(find.text('ScoreX'), findsOneWidget);
    expect(find.text('Cricket matches'), findsOneWidget);
    expect(find.text('Live cricket data is not connected yet'), findsOneWidget);
  });

  testWidgets('settings page can be opened from the home screen', (tester) async {
    await tester.pumpWidget(const ScoreXApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    expect(find.text('Match notifications'), findsOneWidget);
  });

  testWidgets('match centre preview has overview and cricket detail tabs', (tester) async {
    await tester.pumpWidget(const ScoreXApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Preview match centre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview match centre'));
    await tester.pumpAndSettle();

    expect(find.text('Match Centre'), findsOneWidget);
    expect(find.text('Match overview'), findsOneWidget);
    expect(find.text('Waiting for live API connection'), findsOneWidget);

    await tester.tap(find.text('Commentary'));
    await tester.pumpAndSettle();
    expect(find.text('Ball-by-ball commentary'), findsOneWidget);
  });
}

  testWidgets('feature cards open API-ready screens without fake data', (tester) async {
    await tester.pumpWidget(const ScoreXApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Live score').first);
    await tester.pumpAndSettle();

    expect(find.text('Live score'), findsOneWidget);
    expect(find.text('Waiting for live API connection'), findsOneWidget);
    expect(find.text('No demo scores are displayed.'), findsNothing);
  });
