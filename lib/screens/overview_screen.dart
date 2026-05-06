import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'player_screen.dart';
import '../data/session_data.dart';
import '../services/audio_service.dart';
import '../models/session.dart';
import '../services/storage_service.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
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
    final recent = await StorageService().getRecentSessions();
    final favorites = await StorageService.instance.getSavedTracks();
    final personalSessions = await StorageService.instance
        .getPersonalSessions();
    final favoriteSessions = _resolveFavoriteSessions(
      favorites,
      personalSessions,
    );

    if (mounted) {
      setState(() {
        _recentSessions = recent;
        _favoriteSessions = favoriteSessions;
      });
    }
  }

  void _playSession(Session session) {
    AudioService.instance.loadSession(session);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerScreen(session: session)),
    ).then((_) => _loadHomeData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = SessionData.categories;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                if (_recentSessions.isNotEmpty) ...[
                  _buildSectionTitle(theme, "Jump back in"),
                  const SizedBox(height: 12),
                  _buildRecentSessionsTray(theme),
                  const SizedBox(height: 32),
                ],
                _buildSectionTitle(theme, "Activities"),
                const SizedBox(height: 16),
                _buildActivitiesGrid(theme),
                const SizedBox(height: 40),
                if (_favoriteSessions.isNotEmpty) ...[
                  _buildSectionTitle(theme, "Favorites"),
                  const SizedBox(height: 12),
                  _buildFavoritesTray(theme),
                  const SizedBox(height: 40),
                ],
                _buildCategoryTabs(theme),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final session =
                      categories[_selectedCategoryIndex].sessions[index];
                  return _buildTrackTile(session, theme, isDark);
                },
                childCount: categories[_selectedCategoryIndex].sessions.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeData theme) {
    final categories = SessionData.categories;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                categories[index].name,
                style: GoogleFonts.montserrat(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Text(
        "NeuroFlow",
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Icons.account_circle_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildRecentSessionsTray(ThemeData theme) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _recentSessions.length,
        itemBuilder: (context, index) {
          final session = _recentSessions[index];
          return GestureDetector(
            onTap: () => _playSession(session),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        session.title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        session.genre,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesTray(ThemeData theme) {
    return SizedBox(
      height: 176,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _favoriteSessions.length,
        itemBuilder: (context, index) {
          final session = _favoriteSessions[index];
          return GestureDetector(
            onTap: () => _playSession(session),
            child: Container(
              width: 136,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
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
                                  Colors.black.withValues(alpha: 0.42),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.86),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.genre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitiesGrid(ThemeData theme) {
    final categories = SessionData.categories;
    if (categories.length < 2) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  categories[0].sessions[0],
                  120,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  categories[1].sessions[0],
                  120,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (categories.length >= 4)
            Row(
              children: [
                Expanded(
                  child: _buildActivityCard(
                    categories[2].sessions[0],
                    120,
                    theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActivityCard(
                    categories[3].sessions[0],
                    120,
                    theme,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Session session, double height, ThemeData theme) {
    return GestureDetector(
      onTap: () => _playSession(session),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: session.imageUrl.startsWith('assets/')
                ? AssetImage(session.imageUrl) as ImageProvider
                : NetworkImage(session.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: height > 100 ? 16 : 12,
              right: 48,
              child: Text(
                session.title,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: height > 100 ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(Session session, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _playSession(session),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: session.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      session.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 56,
                          height: 56,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    )
                  : Image.network(
                      session.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 56,
                          height: 56,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.title,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.genre.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.description,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.play_circle_outline,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionImage(Session session, ThemeData theme) {
    final placeholder = Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note, color: theme.colorScheme.primary),
    );

    if (session.imageUrl.startsWith('assets/')) {
      return Image.asset(
        session.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return Image.network(
      session.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
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
