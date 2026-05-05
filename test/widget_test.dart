import 'package:flutter_test/flutter_test.dart';
import 'package:focus_and_sleep_music/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeuroFlowApp(onboardingComplete: true));

    // Verify that the app title is present (Start screen or Onboarding)
    expect(find.text('NeuroFlow'), findsOneWidget);
  });
}
