import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/session.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../utils/session_image.dart';

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
  bool get _showBackgroundImage => AudioService.instance.showBackgroundImage.value;
  late final VoidCallback _playbackListener;
  Duration get _visibleFocusElapsed => AudioService.instance.visibleFocusElapsed.value;
  set _visibleFocusElapsed(Duration val) => AudioService.instance.visibleFocusElapsed.value = val;

  TimerSettings get _timerSettings => AudioService.instance.timerSettings.value;
  set _timerSettings(TimerSettings val) => AudioService.instance.timerSettings.value = val;

  bool get _isWorkTime => AudioService.instance.isWorkTime.value;
  set _isWorkTime(bool val) => AudioService.instance.isWorkTime.value = val;

  Stopwatch get _intervalStopwatch => AudioService.instance.intervalStopwatch;
  Stopwatch get _visibleFocusStopwatch => AudioService.instance.visibleFocusStopwatch;

  int get _completedIntervals => AudioService.instance.completedIntervals.value;
  set _completedIntervals(int val) => AudioService.instance.completedIntervals.value = val;
  Timer? _quoteRotationTimer;
  final List<String> _quotes = [
    "Focus is the art of knowing what to ignore.",
    "Deep work is the superpower of the 21st century.",
    "Your attention is your most valuable asset.",
    "Efficiency is doing things right; effectiveness is doing the right things.",
    "The way to get started is to quit talking and begin doing.",
    "The secret of getting ahead is getting started.",
    "Don't watch the clock, do what it does. Keep going.",
    "It's not about having time, it's about making time.",
  ];
  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = (_quotes..shuffle()).first;
    _stimulationLevel = widget.session.defaultStimulation;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _playbackListener = _handlePlaybackChanged;
    AudioService.instance.isPlaying.addListener(_playbackListener);
    AudioService.instance.visibleFocusElapsed.addListener(_onTimerTick);
    AudioService.instance.onTimerEnd = _handleTimerEnd;
    AudioService.instance.onIntervalTransition = () {
      if (mounted) _handleIntervalTransition(AudioService.instance.isWorkTime.value);
    };
    _handlePlaybackChanged();
    _checkFavoriteStatus();
  }

  void _onTimerTick() {
    if (mounted) setState(() {});
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
    AudioService.instance.visibleFocusElapsed.removeListener(_onTimerTick);
    if (AudioService.instance.onTimerEnd == _handleTimerEnd) {
      AudioService.instance.onTimerEnd = null;
    }
    if (AudioService.instance.onIntervalTransition != null) {
      AudioService.instance.onIntervalTransition = null;
    }
    _quoteRotationTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionImageUrl = normalizeSessionImageUrl(
      widget.session.imageUrl,
      sessionId: widget.session.id,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Background Artwork Layer
          Positioned.fill(
            child: _showBackgroundImage && sessionImageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: isOnlineImageUrl(sessionImageUrl)
                        ? sessionImageUrl
                        : defaultSessionImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.black),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.black),
                  )
                : Container(color: Colors.black),
          ),

          // 2. Dark Overlay & Blur for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.7),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.4, 0.85],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 3. Animated Background Wave (Subtle)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SineWavePainter(
                    phase: _waveController.value * 2 * math.pi,
                    amplitude: 20 + (_stimulationLevel * 40),
                    frequency: 0.02 + (_stimulationLevel * 0.03),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                );
              },
            ),
          ),

          // 4. Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const Spacer(flex: 2),
                _buildTimerSection(theme),
                const Spacer(flex: 3),
                _buildBottomSection(theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Mix selector
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
          ),

          // Right: Status Icons
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.headphones,
                      size: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "1",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  AudioService.instance.toggleBackgroundImage();
                  setState(() {});
                },
                child: Icon(
                  _showBackgroundImage
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(ThemeData theme) {
    String displayTime = "00:00:00";
    String label = "ELAPSED";

    if (_timerSettings.mode == TimerMode.infinite) {
      if (_timerSettings.activateQuotes) {
        label = "FOCUS";
      } else {
        label = "ELAPSED";
        displayTime = _formatFocusCounter(_visibleFocusElapsed);
      }
    } else if (_timerSettings.mode == TimerMode.timer) {
      label = "TIME LEFT";
      final total = Duration(minutes: _timerSettings.timerDurationMinutes);
      final left = total - _visibleFocusElapsed;
      displayTime = _formatFocusCounter(left.isNegative ? Duration.zero : left);
    } else if (_timerSettings.mode == TimerMode.intervals) {
      label = _isWorkTime ? "WORK" : "REST";
      final total = _isWorkTime
          ? Duration(minutes: _timerSettings.workMinutes)
          : Duration(minutes: _timerSettings.restMinutes);
      final elapsed = _intervalStopwatch.elapsed;
      final left = total - elapsed;
      displayTime = _formatFocusCounter(left.isNegative ? Duration.zero : left);
    }

    return Column(
      children: [
        // Interval counter badge
        if (_timerSettings.mode == TimerMode.intervals &&
            _completedIntervals > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Interval $_completedIntervals completed",
              style: GoogleFonts.inter(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          label,
          style: GoogleFonts.inter(
            color: _timerSettings.mode == TimerMode.intervals && !_isWorkTime
                ? theme.colorScheme.tertiary.withValues(alpha: 0.8)
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        if (_timerSettings.mode == TimerMode.infinite &&
            _timerSettings.activateQuotes)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Text(
                _currentQuote,
                key: ValueKey(_currentQuote),
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: theme.colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          Text(
            displayTime,
            style: GoogleFonts.montserrat(
              color: _timerSettings.mode == TimerMode.intervals && !_isWorkTime
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.onSurface,
              fontSize: 54,
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
            ),
          ),
        // Show elapsed time underneath for infinite+quotes mode
        if (_timerSettings.mode == TimerMode.infinite &&
            _timerSettings.activateQuotes) ...[
          const SizedBox(height: 12),
          Text(
            _formatFocusCounter(_visibleFocusElapsed),
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showTimerSettingsSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _timerSettings.mode == TimerMode.infinite
                      ? Icons.all_inclusive
                      : _timerSettings.mode == TimerMode.intervals
                      ? Icons.update
                      : Icons.access_time,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  _timerSettings.mode == TimerMode.infinite
                      ? "Infinite Play"
                      : _timerSettings.mode == TimerMode.intervals
                      ? "${_timerSettings.workMinutes}m / ${_timerSettings.restMinutes}m Intervals"
                      : "${_timerSettings.timerDurationMinutes} Min Timer",
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    final imageUrl = normalizeSessionImageUrl(
      widget.session.imageUrl,
      sessionId: widget.session.id,
    );
    final isOfficial = imageUrl.contains('htlabsapp.io.vn');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOfficial) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "SCIENTIFICALLY PROVEN",
                            style: GoogleFonts.inter(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      widget.session.title,
                      style: GoogleFonts.montserrat(
                        color: theme.colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...widget.session.tags.map(
                          (tag) => _buildTagCapsule(theme, tag.toUpperCase()),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorited
                          ? Colors.redAccent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildPlaybackControls(theme),
        ],
      ),
    );
  }

  Widget _buildTagCapsule(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.skip_previous_rounded,
                color: theme.colorScheme.onSurface,
                size: 36,
              ),
              onPressed: () => AudioService.instance.skipToPrevious(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: AudioService.instance.isBuffering,
              builder: (context, isBuffering, _) {
                return ValueListenableBuilder<bool>(
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: isBuffering
                              ? SizedBox(
                                  key: const ValueKey('loading'),
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    color: theme.scaffoldBackgroundColor,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  key: ValueKey(isPlaying ? 'pause' : 'play'),
                                  color: theme.scaffoldBackgroundColor,
                                  size: 36,
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.skip_next_rounded,
                color: theme.colorScheme.onSurface,
                size: 36,
              ),
              onPressed: () => AudioService.instance.skipToNext(),
            ),
          ],
        ),
        const SizedBox(height: 24)
      ],
    );
  }

  void _handlePlaybackChanged() {
    if (AudioService.instance.isPlaying.value) {
      _startQuoteRotationIfNeeded();
    } else {
      _quoteRotationTimer?.cancel();
      _quoteRotationTimer = null;
    }
    if (mounted) setState(() {});
  }

  void _startQuoteRotationIfNeeded() {
    if (_timerSettings.mode != TimerMode.infinite ||
        !_timerSettings.activateQuotes) {
      _quoteRotationTimer?.cancel();
      _quoteRotationTimer = null;
      return;
    }
    _quoteRotationTimer ??=
        Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        String newQuote;
        do {
          newQuote = (_quotes..shuffle()).first;
        } while (newQuote == _currentQuote && _quotes.length > 1);
        _currentQuote = newQuote;
      });
    });
  }


  void _handleTimerEnd() {
    final effect = _timerSettings.timerEffect;
    // Save focus time before resetting
    AudioService.instance.persistFocusTime();

    String title = "Focus Session Ended";
    String message =
        "You focused for ${_timerSettings.timerDurationMinutes} minutes. Great work!";
    IconData icon = Icons.timer_off_outlined;

    if (effect == 'chime') {
      title = "Time's Up! 🔔";
      message =
          "Your ${_timerSettings.timerDurationMinutes}-minute session is complete.";
      icon = Icons.notifications_active_outlined;
    } else if (effect == 'voice') {
      title = "Session Complete 🎉";
      message = "Great job! You've finished your focus session.";
      icon = Icons.record_voice_over_outlined;
    }

    if (mounted) {
      _showEndSessionDialog(title, message, icon);
    }
  }

  void _handleIntervalTransition(bool isToWork) {
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isToWork ? Icons.work_outline : Icons.coffee_outlined,
                color: isToWork
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onTertiaryContainer,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToWork ? "Time to Focus! 💪" : "Take a Break ☕",
                      style: TextStyle(
                        color: isToWork
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isToWork
                          ? "${_timerSettings.workMinutes} min work session starting"
                          : "${_timerSettings.restMinutes} min break • Music paused",
                      style: TextStyle(
                        color: (isToWork
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onTertiaryContainer)
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: isToWork
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.tertiaryContainer,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showEndSessionDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(icon, size: 48, color: theme.colorScheme.primary),
          title: Text(
            title,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("DISMISS"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                AudioService.instance.resetTimer();
                AudioService.instance.togglePlay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface,
                foregroundColor: theme.scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("START AGAIN"),
            ),
          ],
        );
      },
    );
  }


  String _formatFocusCounter(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> _showTimerSettingsSheet() async {
    TimerSettings tempSettings = _timerSettings;
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        Text(
                          "Timer Settings",
                          style: GoogleFonts.montserrat(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Mode Selector Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildModeTab(
                            theme,
                            "INFINITE",
                            Icons.all_inclusive,
                            tempSettings.mode == TimerMode.infinite,
                            () => setSheetState(
                              () => tempSettings = tempSettings.copyWith(
                                mode: TimerMode.infinite,
                              ),
                            ),
                          ),
                          _buildModeTab(
                            theme,
                            "TIMER",
                            Icons.access_time,
                            tempSettings.mode == TimerMode.timer,
                            () => setSheetState(
                              () => tempSettings = tempSettings.copyWith(
                                mode: TimerMode.timer,
                              ),
                            ),
                          ),
                          _buildModeTab(
                            theme,
                            "INTERVALS",
                            Icons.update,
                            tempSettings.mode == TimerMode.intervals,
                            () => setSheetState(
                              () => tempSettings = tempSettings.copyWith(
                                mode: TimerMode.intervals,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Content based on mode
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          if (tempSettings.mode == TimerMode.infinite)
                            _buildInfiniteModeSettings(
                              theme,
                              tempSettings,
                              (updated) => setSheetState(
                                () => tempSettings = updated,
                              ),
                            ),
                          if (tempSettings.mode == TimerMode.timer)
                            _buildTimerModeSettings(
                              theme,
                              tempSettings,
                              (updated) => setSheetState(
                                () => tempSettings = updated,
                              ),
                            ),
                          if (tempSettings.mode == TimerMode.intervals)
                            _buildIntervalsModeSettings(
                              theme,
                              tempSettings,
                              (updated) => setSheetState(
                                () => tempSettings = updated,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom Actions
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await StorageService.instance.saveTimerSettings(
                              tempSettings,
                            );
                            setState(() {
                              _timerSettings = tempSettings;
                              _visibleFocusStopwatch.reset();
                              _visibleFocusElapsed = Duration.zero;
                              _intervalStopwatch.reset();
                              _completedIntervals = 0;
                              _isWorkTime = true;
                              _currentQuote = (_quotes..shuffle()).first;
                              _quoteRotationTimer?.cancel();
                              _quoteRotationTimer = null;
                            });
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.onSurface,
                            foregroundColor: theme.scaffoldBackgroundColor,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            "APPLY",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "CANCEL",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeTab(
    ThemeData theme,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? theme.scaffoldBackgroundColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: isActive
                ? Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfiniteModeSettings(
    ThemeData theme,
    TimerSettings settings,
    ValueChanged<TimerSettings> onUpdate,
  ) {
    return Column(
      children: [
        Text(
          "Infinite Play",
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Listen to tracks freely without any time restrictions.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Activate Quotes",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Quotes replace the timer display.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.activateQuotes,
              onChanged: (val) => onUpdate(
                settings.copyWith(activateQuotes: val),
              ),
              activeThumbColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerModeSettings(
    ThemeData theme,
    TimerSettings settings,
    ValueChanged<TimerSettings> onUpdate,
  ) {
    final durations = [15, 30, 45, 60, 90, 120];
    final isCustom = !durations.contains(settings.timerDurationMinutes);
    return Column(
      children: [
        Text(
          "Set Timer",
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Select when you'd like the music to stop playing.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 32),
        // Preset duration chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: durations.map((d) {
            final isActive = settings.timerDurationMinutes == d && !isCustom;
            return GestureDetector(
              onTap: () => onUpdate(
                settings.copyWith(timerDurationMinutes: d),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Text(
                  "$d min",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Custom slider
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Custom Duration",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${settings.timerDurationMinutes} min",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: theme.colorScheme.onSurface,
                  inactiveTrackColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  thumbColor: theme.colorScheme.onSurface,
                  overlayColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  min: 5,
                  max: 180,
                  divisions: 35,
                  value: settings.timerDurationMinutes.toDouble().clamp(5, 180),
                  onChanged: (val) => onUpdate(
                    settings.copyWith(timerDurationMinutes: val.round()),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "5 min",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  Text(
                    "3 hours",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Select Timer Effect",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildEffectOption(
          theme,
          "Stop Music",
          Icons.stop_circle_outlined,
          settings.timerEffect == 'stop',
          () => onUpdate(settings.copyWith(timerEffect: 'stop')),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEffectOption(
                theme,
                "Chime",
                Icons.notifications_active_outlined,
                settings.timerEffect == 'chime',
                () => onUpdate(settings.copyWith(timerEffect: 'chime')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEffectOption(
                theme,
                "Voice",
                Icons.record_voice_over_outlined,
                settings.timerEffect == 'voice',
                () => onUpdate(settings.copyWith(timerEffect: 'voice')),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildIntervalsModeSettings(
    ThemeData theme,
    TimerSettings settings,
    ValueChanged<TimerSettings> onUpdate,
  ) {
    return Column(
      children: [
        Text(
          "Set Interval",
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Select your desired work and rest lengths.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: _buildInteractiveTimePicker(
                theme,
                "Work Time",
                settings.workMinutes,
                (val) => onUpdate(
                  settings.copyWith(workMinutes: val),
                ),
                minVal: 5,
                maxVal: 120,
                step: 5,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildInteractiveTimePicker(
                theme,
                "Rest Time",
                settings.restMinutes,
                (val) => onUpdate(
                  settings.copyWith(restMinutes: val),
                ),
                minVal: 1,
                maxVal: 30,
                step: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Select Interval Sound",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSoundOption(
                theme,
                "Voice",
                Icons.play_circle_filled,
                settings.intervalSound == 'voice',
                () => onUpdate(settings.copyWith(intervalSound: 'voice')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSoundOption(
                theme,
                "Chime",
                Icons.play_circle_filled,
                settings.intervalSound == 'chime',
                () => onUpdate(settings.copyWith(intervalSound: 'chime')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractiveTimePicker(
    ThemeData theme,
    String label,
    int currentMinutes,
    ValueChanged<int> onChanged, {
    int minVal = 1,
    int maxVal = 120,
    int step = 5,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // Up arrow
        GestureDetector(
          onTap: () {
            if (currentMinutes + step <= maxVal) {
              onChanged(currentMinutes + step);
            }
          },
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 32,
            color: currentMinutes + step <= maxVal
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 4),
        // Current value
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            "$currentMinutes min",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Down arrow
        GestureDetector(
          onTap: () {
            if (currentMinutes - step >= minVal) {
              onChanged(currentMinutes - step);
            }
          },
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 32,
            color: currentMinutes - step >= minVal
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildSoundOption(
    ThemeData theme,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.transparent
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isActive
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectOption(
    ThemeData theme,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.transparent
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
          ],
        ),
      ),
    );
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
