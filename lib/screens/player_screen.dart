import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/session.dart';
import '../services/audio_service.dart';
import '../services/timer_service.dart';

class PlayerScreen extends StatefulWidget {
  final Session session;

  const PlayerScreen({super.key, required this.session});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  double _stimulationLevel = 0.5;

  @override
  void initState() {
    super.initState();
    _stimulationLevel = widget.session.defaultStimulation;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Stack(
        children: [
          // Animated Background Wave
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SineWavePainter(
                    phase: _waveController.value * 2 * math.pi,
                    amplitude: 20 + (_stimulationLevel * 40),
                    frequency: 0.02 + (_stimulationLevel * 0.03),
                    color: Colors.white.withOpacity(0.05),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const Spacer(),
                _buildTrackInfo(),
                const SizedBox(height: 40),
                _buildWaveVisualization(),
                const Spacer(),
                _buildControls(),
                const SizedBox(height: 32),
                _buildSettingsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "NeuroFlow",
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            widget.session.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            widget.session.description.toUpperCase(),
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ).animate(delay: 200.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildWaveVisualization() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            painter: CentralWavePainter(
              phase: _waveController.value * 2 * math.pi,
              level: _stimulationLevel,
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          ValueListenableBuilder<Duration>(
            valueListenable: AudioService.instance.position,
            builder: (context, position, _) {
              return ValueListenableBuilder<Duration>(
                valueListenable: AudioService.instance.duration,
                builder: (context, duration, _) {
                  double value = 0;
                  if (duration.inSeconds > 0) {
                    value = position.inSeconds / duration.inSeconds;
                  }
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: value.clamp(0.0, 1.0),
                          onChanged: (v) {
                            final seekPosition = Duration(
                              seconds: (v * duration.inSeconds).toInt(),
                            );
                            AudioService.instance.seek(seekPosition);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.timer_outlined, color: Colors.white54),
                onPressed: () => _showTimerOptions(),
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () => AudioService.instance.skipToPrevious(),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: AudioService.instance.isPlaying,
                builder: (context, isPlaying, _) {
                  return GestureDetector(
                    onTap: () => AudioService.instance.togglePlay(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () => AudioService.instance.skipToNext(),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white54),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NEURAL EFFECT LEVEL",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                _getEffectLabel(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
              onChanged: (v) {
                setState(() => _stimulationLevel = v);
                AudioService.instance.setStimulationLevel(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getEffectLabel() {
    if (_stimulationLevel < 0.3) return "LOW";
    if (_stimulationLevel < 0.7) return "MEDIUM";
    return "HIGH";
  }

  void _showTimerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Session Timer",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildTimerItem(25, "Deep Focus"),
            _buildTimerItem(45, "Flow Session"),
            _buildTimerItem(60, "Epic Work"),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerItem(int minutes, String label) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: Text(
        "$minutes min",
        style: const TextStyle(color: Colors.white54),
      ),
      onTap: () {
        TimerService.instance.startPomodoro(minutes);
        Navigator.pop(context);
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class SineWavePainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final double frequency;
  final Color color;

  SineWavePainter({
    required this.phase,
    required this.amplitude,
    required this.frequency,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      double y = size.height / 2 + amplitude * math.sin(x * frequency + phase);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw a second one slightly offset
    final path2 = Path();
    path2.moveTo(0, size.height / 2 + 50);
    for (double x = 0; x <= size.width; x++) {
      double y =
          size.height / 2 +
          50 +
          (amplitude * 0.8) * math.sin(x * frequency * 1.2 + phase + 1);
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant SineWavePainter oldDelegate) => true;
}

class CentralWavePainter extends CustomPainter {
  final double phase;
  final double level;

  CentralWavePainter({required this.phase, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw multiple concentric animated waves
    int count = 5;
    for (int i = 0; i < count; i++) {
      double t = (i / count);
      double radius = 40 + (t * 80) + (10 * math.sin(phase + (t * 5)));

      paint.color = Colors.white.withOpacity(
        (1.0 - t) * 0.2 * (0.5 + level * 0.5),
      );
      canvas.drawCircle(center, radius, paint);
    }

    // Draw central "neural" lines
    paint.strokeWidth = 1;
    paint.color = Colors.white.withOpacity(0.6 + (level * 0.4));

    final path = Path();
    int points = 60;
    for (int i = 0; i < points; i++) {
      double angle = (i / points) * 2 * math.pi;
      double r = 50 + (15 * level * math.sin(angle * 8 + phase * 2));
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CentralWavePainter oldDelegate) => true;
}
