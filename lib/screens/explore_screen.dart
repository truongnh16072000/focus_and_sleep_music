import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Explore",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildProgressBar(theme),
            const SizedBox(height: 40),
            _buildScienceHeader(theme),
            const SizedBox(height: 32),
            _buildScienceGraphic(theme, isDark),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("CONTINUE"),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index == 0 ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScienceHeader(ThemeData theme) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            children: [
              const TextSpan(text: "Here's the "),
              TextSpan(
                text: "science",
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "fMRI scans show NeuroFlow increases blood flow to brain regions that maintain focus and energy.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ).animate(delay: 200.ms).fadeIn(),
      ],
    );
  }

  Widget _buildScienceGraphic(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "fMRI studies:",
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Blood flow in the brain",
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBrainComparison(
                theme,
                "AVERAGE MUSIC",
                "(SPOTIFY, YOUTUBE, ETC.)",
                Colors.purple.withOpacity(isDark ? 0.3 : 0.4),
              ),
              _buildBrainComparison(
                theme,
                "NEUROFLOW",
                "",
                theme.colorScheme.primary.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Research funded by the National Science Foundation",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().scale();
  }

  Widget _buildBrainComparison(
    ThemeData theme,
    String label,
    String subLabel,
    Color bloomColor,
  ) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: bloomColor, blurRadius: 30, spreadRadius: 3),
            ],
          ),
          child: Icon(
            Icons.psychology,
            size: 60,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: GoogleFonts.inter(
            color: theme.colorScheme.onSurface,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subLabel.isNotEmpty)
          Text(
            subLabel,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 8,
            ),
          ),
      ],
    );
  }
}
