import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/session.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class AnalystScreen extends StatefulWidget {
  const AnalystScreen({super.key});

  @override
  State<AnalystScreen> createState() => _AnalystScreenState();
}

class _AnalystScreenState extends State<AnalystScreen> {
  final StorageService _storage = StorageService.instance;
  List<FocusSessionRecord> _focusRecords = [];
  List<Session> _recentSessions = [];
  int _streakCount = 0;
  int _totalSessions = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    AudioService.instance.historyUpdate.addListener(_loadAnalytics);
  }

  @override
  void dispose() {
    AudioService.instance.historyUpdate.removeListener(_loadAnalytics);
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    await AudioService.instance.persistFocusTime(
      continueIfPlaying: true,
      notifyListeners: false,
    );
    final records = await _storage.getFocusSessionRecords();
    final recent = await _storage.getRecentSessions();
    final streak = await _storage.getStreakCount();
    final total = await _storage.getTotalSessions();

    if (!mounted) return;

    setState(() {
      _focusRecords = records;
      _recentSessions = recent;
      _streakCount = streak;
      _totalSessions = total;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _buildLastSevenDays();
    final totalFocusMinutes = _focusRecords.fold<int>(
      0,
      (sum, record) => sum + record.minutes,
    );
    final weekFocusMinutes = days.fold<int>(0, (sum, day) => sum + day.minutes);
    final bestGenre = _bestGenreLabel();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          "Analyst",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadAnalytics,
            tooltip: "Refresh analytics",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSummary(theme, weekFocusMinutes),
                    const SizedBox(height: 16),
                    _buildStatGrid(
                      theme,
                      totalFocusMinutes: totalFocusMinutes,
                      weekFocusMinutes: weekFocusMinutes,
                      bestGenre: bestGenre,
                    ),
                    const SizedBox(height: 24),
                    _buildWeeklyChart(theme, days),
                    const SizedBox(height: 24),
                    _buildFocusMix(theme),
                    const SizedBox(height: 24),
                    _buildStreakCard(theme),
                    const SizedBox(height: 24),
                    _buildInsightCard(theme, days, bestGenre),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroSummary(ThemeData theme, int weekFocusMinutes) {
    final hasFocusData = _focusRecords.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.query_stats_rounded,
                  color: theme.scaffoldBackgroundColor,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                "THIS WEEK",
                style: GoogleFonts.inter(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.68),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            hasFocusData ? _formatFocusTime(weekFocusMinutes) : "No focus data",
            style: GoogleFonts.montserrat(
              color: theme.scaffoldBackgroundColor,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFocusData
                ? "$_totalSessions sessions started, $_streakCount day streak"
                : "Play a focus session for at least one minute to track time.",
            style: GoogleFonts.inter(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildStatGrid(
    ThemeData theme, {
    required int totalFocusMinutes,
    required int weekFocusMinutes,
    required String bestGenre,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.local_fire_department_outlined,
                label: "Streak",
                value: "$_streakCount days",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.access_time_outlined,
                label: "Focus",
                value: _formatFocusTime(totalFocusMinutes),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.headphones_outlined,
                label: "Sessions",
                value: "$_totalSessions",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                icon: Icons.bubble_chart_outlined,
                label: "Best mode",
                value: bestGenre,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(ThemeData theme, List<_DayFocus> days) {
    final maxMinutes = math.max(
      1,
      days.map((day) => day.minutes).fold(0, math.max),
    );
    final hasData = days.any((day) => day.minutes > 0);
    final isDark = theme.brightness == Brightness.dark;
    final chartBackground = isDark
        ? const Color(0xFF242428)
        : const Color(0xFFF0F0E8);
    final emptyBarColor = isDark
        ? const Color(0xFF3A3A42)
        : const Color(0xFFDCDCD2);
    final emptyTodayColor = isDark
        ? const Color(0xFF66666F)
        : const Color(0xFFB8B8AE);

    return _buildSection(
      theme,
      title: "Focus rhythm",
      trailing: hasData ? "${_formatFocusTime(maxMinutes)} peak" : "7 days",
      child: Container(
        height: 204,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          color: chartBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: days.map((day) {
                      final heightFactor = day.minutes == 0
                          ? 0.08
                          : (day.minutes / maxMinutes).clamp(0.12, 1.0);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                day.minutes == 0 ? "" : "${day.minutes}m",
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.52,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: heightFactor,
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: _barColorForDay(
                                        theme,
                                        day: day,
                                        hasData: hasData,
                                        emptyBarColor: emptyBarColor,
                                        emptyTodayColor: emptyTodayColor,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: days
                      .map(
                        (day) => Expanded(
                          child: Text(
                            day.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: day.isToday
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                              fontSize: 10,
                              fontWeight: day.isToday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            if (!hasData)
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(
                      alpha: isDark ? 0.72 : 0.8,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "No focus time yet",
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.62,
                      ),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _barColorForDay(
    ThemeData theme, {
    required _DayFocus day,
    required bool hasData,
    required Color emptyBarColor,
    required Color emptyTodayColor,
  }) {
    if (!hasData) {
      return day.isToday ? emptyTodayColor : emptyBarColor;
    }

    return day.isToday
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.28);
  }

  Widget _buildFocusMix(ThemeData theme) {
    final slices = _buildGenreSlices();

    return _buildSection(
      theme,
      title: "Focus mix",
      trailing: slices.isEmpty ? "No data" : "${slices.length} modes",
      child: slices.isEmpty
          ? _buildEmptyAnalyticsNote(theme)
          : Row(
              children: [
                SizedBox(
                  width: 116,
                  height: 116,
                  child: CustomPaint(painter: _DonutPainter(slices)),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    children: slices
                        .map((slice) => _buildLegendItem(theme, slice))
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, _GenreSlice slice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: slice.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              slice.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            "${slice.value}",
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(ThemeData theme) {
    final activeDays = _streakCount.clamp(0, 7);

    return _buildSection(
      theme,
      title: "Streak health",
      trailing: "$_streakCount days",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(7, (index) {
              final isActive = index >= 7 - activeDays;
              return Expanded(
                child: Container(
                  height: 38,
                  margin: EdgeInsets.only(right: index == 6 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.check_rounded : Icons.circle_outlined,
                    size: 16,
                    color: isActive
                        ? theme.scaffoldBackgroundColor
                        : theme.colorScheme.onSurface.withValues(alpha: 0.22),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _streakCount == 0
                ? "Play a session today to begin your streak."
                : "Your streak grows when you start at least one focus session each day.",
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    ThemeData theme,
    List<_DayFocus> days,
    String bestGenre,
  ) {
    final bestDay = days.reduce(
      (current, next) => next.minutes > current.minutes ? next : current,
    );
    final insight = _focusRecords.isEmpty
        ? "Play a focus track for at least one minute to unlock accurate time charts."
        : "Your strongest focus day was ${bestDay.label}. $bestGenre is currently your most used mode.";

    return _buildSection(
      theme,
      title: "Next action",
      trailing: "Insight",
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              insight,
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required String trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: theme.colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                trailing.toUpperCase(),
                style: GoogleFonts.inter(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildEmptyAnalyticsNote(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        "No focus sessions recorded yet.",
        style: GoogleFonts.inter(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          fontSize: 13,
        ),
      ),
    );
  }

  List<_DayFocus> _buildLastSevenDays() {
    final today = DateUtils.dateOnly(DateTime.now());
    final minutesByDay = <DateTime, int>{};
    for (final record in _focusRecords) {
      final day = DateUtils.dateOnly(record.startedAt);
      minutesByDay[day] = (minutesByDay[day] ?? 0) + record.minutes;
    }

    return List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      return _DayFocus(
        label: _weekdayLabel(day.weekday),
        minutes: minutesByDay[day] ?? 0,
        isToday: day == today,
      );
    });
  }

  List<_GenreSlice> _buildGenreSlices() {
    final totals = <String, int>{};
    if (_focusRecords.isNotEmpty) {
      for (final record in _focusRecords) {
        totals[record.genre] = (totals[record.genre] ?? 0) + record.minutes;
      }
    } else {
      for (final session in _recentSessions) {
        totals[session.genre] = (totals[session.genre] ?? 0) + 1;
      }
    }

    final colors = [
      const Color(0xFF8DD7CF),
      const Color(0xFFF4C95D),
      const Color(0xFFE58C8A),
      const Color(0xFF9DA7F5),
      const Color(0xFFB7D968),
    ];

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return List.generate(math.min(entries.length, colors.length), (index) {
      final entry = entries[index];
      return _GenreSlice(
        label: entry.key,
        value: entry.value,
        color: colors[index],
      );
    });
  }

  String _bestGenreLabel() {
    final slices = _buildGenreSlices();
    if (slices.isEmpty) return "None";
    return slices.first.label;
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  String _formatFocusTime(int minutes) {
    if (minutes <= 0) return "0m";
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return "${remaining}m";
    if (remaining == 0) return "${hours}h";
    return "${hours}h ${remaining}m";
  }
}

class _DayFocus {
  final String label;
  final int minutes;
  final bool isToday;

  const _DayFocus({
    required this.label,
    required this.minutes,
    required this.isToday,
  });
}

class _GenreSlice {
  final String label;
  final int value;
  final Color color;

  const _GenreSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_GenreSlice> slices;

  _DonutPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.value / total) * math.pi * 2;
      paint.color = slice.color;
      canvas.drawArc(rect.deflate(10), startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}
