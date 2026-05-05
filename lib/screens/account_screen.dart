import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'monetization_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          "Profile",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Profile Header
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primary,
              child: Text(
                "D",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Dan Performer",
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Premium Member",
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),

            // Upgrade Card
            _buildUpgradeCard(context),

            const SizedBox(height: 32),

            // Settings Groups
            _buildSettingsGroup(context, "Account", [
              _buildSettingTile(context, Icons.person_outline, "Personal Info"),
              _buildSettingTile(
                context,
                Icons.notifications_none_rounded,
                "Notifications",
              ),
              _buildSettingTile(context, Icons.history, "Listening History"),
            ]),

            const SizedBox(height: 24),

            _buildSettingsGroup(context, "App Settings", [
              _buildThemeToggleTile(context),
              _buildSettingTile(
                context,
                Icons.psychology_outlined,
                "ADHD Mode Preferences",
              ),
              _buildSettingTile(
                context,
                Icons.download_outlined,
                "Offline Storage",
              ),
            ]),

            const SizedBox(height: 24),

            _buildSettingsGroup(context, "Support & Legal", [
              _buildSettingTile(context, Icons.help_outline, "Help Center"),
              _buildSettingTile(
                context,
                Icons.description_outlined,
                "Terms of Service",
              ),
              _buildSettingTile(
                context,
                Icons.privacy_tip_outlined,
                "Privacy Policy",
              ),
            ]),

            const SizedBox(height: 40),

            TextButton(
              onPressed: () {},
              child: Text(
                "Log Out",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF4B3832)],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text(
            "NeuroFlow Pro",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your subscription is active until Oct 2026.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonetizationScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text("MANAGE SUBSCRIPTION"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isDark = ThemeService.instance.isDarkMode;
    final borderOpacity = isDark ? 0.1 : 0.04;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(borderOpacity),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
      onTap: () {},
    );
  }

  Widget _buildThemeToggleTile(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: AppTheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        "Dark Mode",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Switch(
        value: isDark,
        onChanged: (_) => ThemeService.instance.toggleDarkMode(),
        activeThumbColor: AppTheme.primary,
      ),
      onTap: () => ThemeService.instance.toggleDarkMode(),
    );
  }
}
