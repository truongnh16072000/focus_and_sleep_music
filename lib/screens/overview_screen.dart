import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/session_data.dart';
import '../models/session.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../utils/session_image.dart';
import 'player_screen.dart';

class OverviewScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPersonal;

  const OverviewScreen({super.key, this.onNavigateToPersonal});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  static const _mentalStates = [
    _MentalStateCardData(
      title: "Focus",
      imagePath: "assets/images/focus.png",
      categoryIndex: 0,
      glowColor: Color(0xFFFF5D93),
    ),
    _MentalStateCardData(
      title: "Relax",
      imagePath: "assets/images/relax.png",
      categoryIndex: 1,
      glowColor: Color(0xFF70C8FF),
    ),
    _MentalStateCardData(
      title: "Sleep",
      imagePath: "assets/images/sleep.png",
      categoryIndex: 2,
      glowColor: Color(0xFF6E55FF),
    ),
    _MentalStateCardData(
      title: "Meditate",
      imagePath: "assets/images/meditate.png",
      categoryIndex: 3,
      glowColor: Color(0xFF50E1AA),
    ),
  ];

  List<Session> _recentSessions = [];
  List<Session> _favoriteSessions = [];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    AudioService.instance.historyUpdate.addListener(_loadHomeData);
  }

  @override
  void dispose() {
    AudioService.instance.historyUpdate.removeListener(_loadHomeData);
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    final recent = await StorageService.instance.getRecentSessions();
    final favorites = await StorageService.instance.getSavedTracks();
    final personalSessions = await StorageService.instance
        .getPersonalSessions();
    final favoriteSessions = _resolveFavoriteSessions(
      favorites,
      personalSessions,
    );

    if (!mounted) return;

    setState(() {
      _recentSessions = recent;
      _favoriteSessions = favoriteSessions;
    });
  }

  Future<void> _playSession(Session session) async {
    if (!session.isPersonal) {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw const SocketException('offline');
        }
      } on SocketException catch (_) {
        if (!mounted) return;
        _showOfflineDialog();
        return;
      }
    }

    AudioService.instance.loadSession(session);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerScreen(session: session)),
    ).then((_) => _loadHomeData());
  }

  void _showOfflineDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "You're offline",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Please check your internet connection to stream online tracks. Would you like to play your downloaded tracks instead?",
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onNavigateToPersonal != null) {
                  widget.onNavigateToPersonal!();
                }
              },
              child: const Text("Go to Personal Tracks"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategory = SessionData.categories[_selectedCategoryIndex];
    final recommended = selectedCategory.sessions.first;

    return Scaffold(
      body: DecoratedBox(
        decoration: _screenDecoration(theme),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    "Start",
                    style: GoogleFonts.montserrat(
                      color: theme.colorScheme.onSurface,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildSectionLabel(theme, "Choose a mental state"),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                sliver: SliverList.separated(
                  itemCount: _mentalStates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _mentalStates[index];
                    return _buildMentalStateCard(
                      theme,
                      item,
                      isSelected: _selectedCategoryIndex == item.categoryIndex,
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 36, 0, 0),
                sliver: SliverToBoxAdapter(child: _buildJumpBackIn(theme)),
              ),
              if (_favoriteSessions.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 0, 0),
                  sliver: SliverToBoxAdapter(child: _buildFavorites(theme)),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 18),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(theme, "Recommended track"),
                      const SizedBox(height: 18),
                      _buildRecommendedTrack(theme, recommended),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _screenDecoration(ThemeData theme) {
    if (theme.brightness == Brightness.light) {
      return const BoxDecoration(color: Color(0xFFF6F2F7));
    }

    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF211024), Color(0xFF11121E), Color(0xFF0A070E)],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.montserrat(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
        fontSize: 15,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
  }

  Widget _buildMentalStateCard(
    ThemeData theme,
    _MentalStateCardData item, {
    required bool isSelected,
  }) {
    final targetCategory = SessionData.categories[item.categoryIndex];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryIndex = item.categoryIndex);
        _playSession(targetCategory.sessions.first);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              theme.colorScheme.surface.withValues(alpha: 0.48),
              item.glowColor.withValues(alpha: isSelected ? 0.24 : 0.10),
              theme.colorScheme.surface.withValues(alpha: 0.32),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.22 : 0.12),
            width: isSelected ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: item.glowColor.withValues(alpha: isSelected ? 0.22 : 0.10),
              blurRadius: isSelected ? 26 : 16,
              offset: const Offset(14, 0),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                      item.glowColor.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: -44,
              bottom: -44,
              width: 190,
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned(
              right: 112,
              top: 0,
              bottom: 0,
              width: 132,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      item.glowColor.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 28, right: 132),
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: theme.colorScheme.onSurface,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJumpBackIn(ThemeData theme) {
    final fallback = [
      SessionData.categories[0].sessions.first,
      SessionData.categories[1].sessions.first,
    ];
    final sessions = (_recentSessions.isEmpty ? fallback : _recentSessions)
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Text(
            "Jump Back In",
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 22),
        _buildSectionLabel(theme, "Recent sessions"),
        const SizedBox(height: 16),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 24),
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _buildRecentCard(theme, sessions[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCard(ThemeData theme, Session session, int index) {
    final timeLabel = index.isEven ? "90 Minutes" : "Infinity";
    final icon = index.isEven ? Icons.timer_outlined : Icons.all_inclusive;

    return GestureDetector(
      onTap: () => _playSession(session),
      child: Container(
        width: 252,
        padding: const EdgeInsets.fromLTRB(22, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF24162D), Color(0xFF382542), Color(0xFF994E68)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.68,
                        ),
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          timeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.66,
                            ),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6E8E).withValues(alpha: 0.46),
                    blurRadius: 28,
                    spreadRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFFE86B88),
                size: 34,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavorites(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: _buildSectionLabel(theme, "Favorites"),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 152,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 24),
            itemCount: _favoriteSessions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final session = _favoriteSessions[index];
              return GestureDetector(
                onTap: () => _playSession(session),
                child: SizedBox(
                  width: 132,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildSessionImage(session, theme),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.48),
                                    ],
                                  ),
                                ),
                              ),
                              const Positioned(
                                right: 8,
                                bottom: 8,
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedTrack(ThemeData theme, Session session) {
    return GestureDetector(
      onTap: () => _playSession(session),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xFF201A2A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 86,
              height: double.infinity,
              child: _buildSessionImage(session, theme),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.drag_handle_rounded,
                        color: Color(0xFFD4BFCB),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.genre.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.62,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              margin: const EdgeInsets.only(right: 18),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "FOCUS",
                style: GoogleFonts.inter(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionImage(Session session, ThemeData theme) {
    final placeholder = _buildImagePlaceholder(theme);
    final imageUrl = normalizeSessionImageUrl(
      session.imageUrl,
      sessionId: session.id,
    );

    if (imageUrl.isEmpty) return placeholder;

    if (isOnlineImageUrl(imageUrl)) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      );
    }

    return Image.file(
      File(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Icon(
        Icons.music_note_rounded,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
      ),
    );
  }

  List<Session> _resolveFavoriteSessions(
    List<Track> tracks,
    List<Session> personalSessions,
  ) {
    final bundledById = {
      for (final session in SessionData.sessions) session.id: session,
    };
    final personalById = {
      for (final session in personalSessions) session.id: session,
    };

    return tracks.map((track) {
      final bundled = bundledById[track.id];
      if (bundled != null) return bundled;

      final personal = personalById[track.id];
      if (personal != null) return personal;

      return Session(
        id: track.id,
        title: track.title,
        description: track.description,
        genre: track.genre,
        audioUrl: track.audioUrl,
        assetPath: track.assetPath,
        imageUrl: track.imageUrl,
        state: MentalState.focus,
        isPersonal: track.isPersonal,
        localPath: track.localPath,
      );
    }).toList();
  }
}

class _MentalStateCardData {
  final String title;
  final String imagePath;
  final int categoryIndex;
  final Color glowColor;

  const _MentalStateCardData({
    required this.title,
    required this.imagePath,
    required this.categoryIndex,
    required this.glowColor,
  });
}
