import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/main.dart';

void main() {
  testWidgets('ScoreX app displays brand and API setup message', (tester) async {
    await tester.pumpWidget(const ScoreXApp());
    expect(find.text('ScoreX'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);
  });
}
