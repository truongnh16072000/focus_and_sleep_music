import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/storage_service.dart';
import 'main_navigation.dart';
import '../data/session_data.dart';
import '../models/session.dart';
import 'player_screen.dart';
import '../services/audio_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalSteps = 6;

  // Selections
  final List<String> _selectedGoals = [];
  String _selectedWorkType = "";
  double _stimulationLevel = 0.5;
  final List<String> _selectedGenres = [];

  void _nextPage() {
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await StorageService().setOnboardingComplete();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  void _startWithSession(Session session) async {
    await StorageService().setOnboardingComplete();
    // Set stimulation level based on onboarding answer
    session.defaultStimulation = _stimulationLevel;
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
      AudioService.instance.loadSession(session);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlayerScreen(session: session)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigation(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomeStep(),
                  _buildGoalStep(),
                  _buildWorkTypeStep(),
                  _buildStimulationStep(),
                  _buildScienceStep(),
                  _buildActivityStep(),
                ],
              ),
            ),
            if (_currentPage < _totalSteps - 1) _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _previousPage,
                )
              else
                const SizedBox(width: 48),
              Text(
                _getStepTitle(),
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(_totalSteps, (index) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Colors.white
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentPage) {
      case 1: return "GOALS";
      case 2: return "YOUR WORK";
      case 3: return "STIMULATION";
      case 4: return "SCIENCE";
      case 5: return "GET STARTED";
      default: return "";
    }
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            "Let's personalize NeuroFlow for you",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          Text(
            "Quick Personalization",
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 60),
          _buildPersonalizeItem(
            Icons.track_changes_rounded,
            "Your focus goals and work type",
            "We'll match you with the right Activity",
          ),
          _buildPersonalizeItem(
            Icons.waves_rounded,
            "Your stimulation needs",
            "We'll set your Neural Effect Level",
          ),
          _buildPersonalizeItem(
            Icons.music_note_rounded,
            "Your music preferences",
            "We'll select genres you'll enjoy",
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.white.withOpacity(0.3), size: 16),
              const SizedBox(width: 8),
              Text(
                "All of these can be changed anytime.",
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPersonalizeItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildGoalStep() {
    final goals = ["Get motivated", "Stay energized", "Block distractions", "Enhance Concentration"];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            "What's your focus goal?",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select as many as you like",
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 40),
          ...goals.map((goal) => _buildSelectionCard(
                goal,
                _selectedGoals.contains(goal),
                () {
                  setState(() {
                    if (_selectedGoals.contains(goal)) {
                      _selectedGoals.remove(goal);
                    } else {
                      _selectedGoals.add(goal);
                    }
                  });
                },
                info: goal == "Get motivated" 
                  ? "Our music is designed to activate your dopaminergic system the brain's 'reward and motivation' network." 
                  : null,
              )),
        ],
      ),
    );
  }

  Widget _buildWorkTypeStep() {
    final types = ["Deep Work", "Creative", "Study", "Coding"];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            "What type of work?",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll optimize the neural effect",
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 40),
          ...types.map((type) => _buildSelectionCard(
                type,
                _selectedWorkType == type,
                () {
                  setState(() {
                    _selectedWorkType = type;
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget _buildStimulationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            "Stimulation Needs",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "How sensitive are you to background music?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Text(
                  _getStimulationLabel().toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStimulationDesc(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
                const SizedBox(height: 48),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.1),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: _stimulationLevel,
                    onChanged: (v) => setState(() => _stimulationLevel = v),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("CHILL", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold)),
                    Text("INTENSE", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(),
        ],
      ),
    );
  }

  String _getStimulationLabel() {
    if (_stimulationLevel < 0.3) return "Low";
    if (_stimulationLevel < 0.7) return "Medium";
    return "High";
  }

  String _getStimulationDesc() {
    if (_stimulationLevel < 0.3) return "Subtle background patterns for calm concentration.";
    if (_stimulationLevel < 0.7) return "Balanced neural patterns for steady flow state.";
    return "Dynamic and high-energy patterns for peak performance.";
  }

  Widget _buildSelectionCard(String title, bool isSelected, VoidCallback onTap, {String? info}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                    ),
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (isSelected && info != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 20, right: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF64B5F6), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    info,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),
      ],
    );
  }

  Widget _buildScienceStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              children: const [
                TextSpan(text: "Here's the "),
                TextSpan(
                  text: "science",
                  style: TextStyle(color: Color(0xFFF48FB1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "fMRI scans show NeuroFlow increases blood flow to brain regions that maintain focus and energy.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          // Stylized Science Graphic
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const Text(
                  "fMRI studies:",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Blood flow in the brain",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBrainIcon("AVERAGE MUSIC", const Color(0xFF9575CD)),
                    _buildBrainIcon("NEUROFLOW", const Color(0xFFF06292)),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  "Research funded by the National Science Foundation",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(),
        ],
      ),
    );
  }

  Widget _buildBrainIcon(String label, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(label.contains("NEUROFLOW") ? 0.6 : 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            Icon(Icons.psychology, size: 60, color: Colors.white.withOpacity(0.8)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            "Get started",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "What would you like to try first?",
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              children: [
                _buildCategoryCard(
                  "Focus",
                  "assets/images/focus.png",
                  [const Color(0xFF8E24AA), const Color(0xFFD81B60)],
                  SessionData.deepWork[0],
                ),
                _buildCategoryCard(
                  "Relax",
                  "assets/images/relax.png",
                  [const Color(0xFF1E88E5), const Color(0xFF00ACC1)],
                  SessionData.creative[0],
                ),
                _buildCategoryCard(
                  "Sleep",
                  "assets/images/sleep.png",
                  [const Color(0xFF3949AB), const Color(0xFF5E35B1)],
                  SessionData.creative[1],
                ),
                _buildCategoryCard(
                  "Meditate",
                  "assets/images/meditate.png",
                  [const Color(0xFF43A047), const Color(0xFF00897B)],
                  SessionData.creative[2],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String imagePath, List<Color> gradientColors, Session session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withOpacity(0.4),
            gradientColors[1].withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _startWithSession(session),
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              width: 160,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white.withOpacity(0.05),
                    child: const Icon(Icons.image, color: Colors.white24),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0F0F12).withOpacity(0.9),
                      const Color(0xFF0F0F12).withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.6, 0.9],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildBottomButton() {
    bool canContinue = true;
    if (_currentPage == 1 && _selectedGoals.isEmpty) canContinue = false;
    if (_currentPage == 2 && _selectedWorkType.isEmpty) canContinue = false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: canContinue ? _nextPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: Text(
            "Continue",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
