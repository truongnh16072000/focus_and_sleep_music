import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/session.dart';
import '../services/audio_service.dart';
import '../services/focus_session_lock_service.dart';
import '../services/storage_service.dart';

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
  bool _isFavorited = false;
  late final VoidCallback _playbackListener;
  bool _didShowManualGuidedAccessHint = false;
  final Stopwatch _visibleFocusStopwatch = Stopwatch();
  Timer? _visibleFocusTimer;
  Duration _visibleFocusElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _stimulationLevel = widget.session.defaultStimulation;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _playbackListener = _handlePlaybackChanged;
    AudioService.instance.isPlaying.addListener(_playbackListener);
    _handlePlaybackChanged();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final favorites = await StorageService.instance.getSavedTracks();
    if (mounted) {
      setState(() {
        _isFavorited = favorites.any((t) => t.id == widget.session.id);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorited) {
      await StorageService.instance.removeTrack(widget.session.id);
    } else {
      await StorageService.instance.saveTrack(
        Track(
          id: widget.session.id,
          title: widget.session.title,
          description: widget.session.description,
          genre: widget.session.genre,
          imageUrl: widget.session.imageUrl,
          audioUrl: widget.session.audioUrl,
          assetPath: widget.session.assetPath,
          isPersonal: widget.session.isPersonal,
          localPath: widget.session.localPath,
        ),
      );
    }
    setState(() => _isFavorited = !_isFavorited);

    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorited ? "Added to favorites" : "Removed from favorites",
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    AudioService.instance.isPlaying.removeListener(_playbackListener);
    _visibleFocusTimer?.cancel();
    unawaited(FocusSessionLockService.instance.deactivateForFocusPlayback());
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.onSurface,
              size: 32,
            ),
            onPressed: () async {
              await AudioService.instance.stop();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          Text(
            "NeuroFlow",
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited
                  ? Colors.redAccent
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            widget.session.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            widget.session.description.toUpperCase(),
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 18),
          _buildFocusCounter(theme).animate(delay: 260.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildFocusCounter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 8),
          Text(
            _formatFocusCounter(_visibleFocusElapsed),
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveVisualization() {
    final theme = Theme.of(context);
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
              color: theme.colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    final theme = Theme.of(context);
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
                          activeTrackColor: theme.colorScheme.onSurface,
                          inactiveTrackColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
                          thumbColor: theme.colorScheme.onSurface,
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
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
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
                icon: Icon(
                  Icons.skip_previous,
                  color: theme.colorScheme.onSurface,
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
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: theme.scaffoldBackgroundColor,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.skip_next,
                  color: theme.colorScheme.onSurface,
                  size: 36,
                ),
                onPressed: () => AudioService.instance.skipToNext(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                _getEffectLabel(),
                style: GoogleFonts.inter(
                  color: theme.colorScheme.onSurface,
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
              activeTrackColor: theme.colorScheme.onSurface,
              inactiveTrackColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.1,
              ),
              thumbColor: theme.colorScheme.onSurface,
              overlayColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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

  void _handlePlaybackChanged() {
    unawaited(_syncFocusLockWithPlayback());
    _syncVisibleFocusTimer();
  }

  void _syncVisibleFocusTimer() {
    if (AudioService.instance.isPlaying.value) {
      if (!_visibleFocusStopwatch.isRunning) {
        _visibleFocusStopwatch.start();
      }
      _visibleFocusTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _visibleFocusElapsed = _visibleFocusStopwatch.elapsed;
        });
      });
      setState(() {
        _visibleFocusElapsed = _visibleFocusStopwatch.elapsed;
      });
      return;
    }

    if (_visibleFocusStopwatch.isRunning) {
      _visibleFocusStopwatch.stop();
      setState(() {
        _visibleFocusElapsed = _visibleFocusStopwatch.elapsed;
      });
    }
    _visibleFocusTimer?.cancel();
    _visibleFocusTimer = null;
  }

  Future<void> _syncFocusLockWithPlayback() async {
    final shouldLock = AudioService.instance.isPlaying.value;
    final applied = shouldLock
        ? await FocusSessionLockService.instance.activateForFocusPlayback()
        : await FocusSessionLockService.instance
              .deactivateForFocusPlayback()
              .then((_) => true);

    if (!mounted ||
        !FocusSessionLockService.instance.isEnabled.value ||
        !shouldLock ||
        applied ||
        FocusSessionLockService.instance.isActive.value ||
        _didShowManualGuidedAccessHint) {
      return;
    }

    _didShowManualGuidedAccessHint = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "iOS only lets apps start Single App mode on supervised devices. Triple-click the side button to start Guided Access manually.",
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatFocusCounter(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(d.inHours);
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$seconds";
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
  final Color color;

  CentralWavePainter({
    required this.phase,
    required this.level,
    required this.color,
  });

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

      paint.color = color.withValues(
        alpha: (1.0 - t) * 0.2 * (0.5 + level * 0.5),
      );
      canvas.drawCircle(center, radius, paint);
    }

    // Draw central "neural" lines
    paint.strokeWidth = 1;
    paint.color = color.withValues(alpha: 0.6 + (level * 0.4));

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
