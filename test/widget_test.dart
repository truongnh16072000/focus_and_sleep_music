import 'package:flutter_test/flutter_test.dart';
import 'package:focus_and_sleep_music/main.dart';
import 'package:focus_and_sleep_music/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeuroFlowApp(onboardingComplete: true));

    // Verify that the app title is present (Start screen or Onboarding)
    expect(find.text('NeuroFlow'), findsOneWidget);
  });
}
