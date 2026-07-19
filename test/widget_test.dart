import 'package:flutter_test/flutter_test.dart';
import 'package:hydrodok/main.dart';

void main() {
  testWidgets('App renders splash screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const HydrodokApp());

    // The splash screen should show the app name
    expect(find.text('Train Radar'), findsOneWidget);
    expect(find.text('Real-time train tracking'), findsOneWidget);
  });
}
