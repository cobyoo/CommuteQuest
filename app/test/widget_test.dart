import 'package:flutter_test/flutter_test.dart';
import 'package:commute_quest/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CommuteQuestApp());
    expect(find.text('CommuteQuest'), findsOneWidget);
  });
}
