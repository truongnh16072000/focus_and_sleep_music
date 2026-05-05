import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'screens/main_navigation.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.instance.init();
  await AudioService.instance.init();
  await ThemeService.instance.init();
  final bool onboardingComplete = await StorageService().isOnboardingComplete();

  runApp(NeuroFlowApp(onboardingComplete: onboardingComplete));
}

class NeuroFlowApp extends StatefulWidget {
  final bool onboardingComplete;

  const NeuroFlowApp({super.key, required this.onboardingComplete});

  @override
  State<NeuroFlowApp> createState() => _NeuroFlowAppState();
}

class _NeuroFlowAppState extends State<NeuroFlowApp>
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeService.instance.removeListener(_onThemeChanged);
    AudioService.instance.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      AudioService.instance.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: const ValueKey('NeuroFlowAppMain'),
      title: 'NeuroFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeModeForApp(ThemeService.instance.themeMode),
      home: widget.onboardingComplete
          ? const MainNavigation()
          : const OnboardingScreen(),
    );
  }

  ThemeMode _themeModeForApp(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
