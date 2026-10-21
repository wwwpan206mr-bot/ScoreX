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
    expect(find.text('Live score'), findsOneWidget);
    expect(find.text('Scorecard'), findsOneWidget);
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
}
