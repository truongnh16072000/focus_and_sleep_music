import 'dart:io';

import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/audio_service.dart';
import '../utils/session_image.dart';
import 'overview_screen.dart';
import 'analyst_screen.dart';
import 'collection_screen.dart';
import 'account_screen.dart';
import 'player_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<CollectionScreenState> _collectionKey = GlobalKey();

  late final List<Widget> _screens = [
    OverviewScreen(onNavigateToPersonal: _navigateToPersonal),
    CollectionScreen(key: _collectionKey),
    const AnalystScreen(),
    const AccountScreen(),
  ];

  void _navigateToPersonal() {
    setState(() => _currentIndex = 1);
    _collectionKey.currentState?.switchToPersonalTab();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F12),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniPlayer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.play_arrow_outlined, Icons.play_arrow_rounded, 'START'),
                    _buildNavItem(
                      1,
                      Icons.layers_outlined,
                      Icons.layers_rounded,
                      'LIBRARY',
                    ),
                    _buildNavItem(
                      2,
                      Icons.explore_outlined,
                      Icons.explore_rounded,
                      'EXPLORE',
                    ),
                    _buildNavItem(
                      3,
                      Icons.account_circle_outlined,
                      Icons.account_circle_rounded,
                      'PROFILE',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return ValueListenableBuilder<bool>(
      valueListenable: AudioService.instance.hasActiveSession,
      builder: (context, hasActiveSession, _) {
        if (!hasActiveSession) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<Session?>(
          valueListenable: AudioService.instance.currentSession,
          builder: (context, session, _) {
            if (session == null) {
              return const SizedBox.shrink();
            }

            return _MiniMusicBar(
              session: session,
              onOpenPlayer: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(session: session),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected
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
}

class _MiniMusicBar extends StatelessWidget {
  final Session session;
  final VoidCallback onOpenPlayer;

  const _MiniMusicBar({required this.session, required this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4A6B6A).withValues(alpha: 0.9),
              const Color(0xFF2D3E3D).withValues(alpha: 0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpenPlayer,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _SessionArtwork(session: session),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.genre.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildTimerPill(theme),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: AudioService.instance.isBuffering,
                  builder: (context, isBuffering, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: AudioService.instance.isPlaying,
                      builder: (context, isPlaying, _) {
                        return IconButton(
                          onPressed: AudioService.instance.togglePlay,
                          icon: isBuffering
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerPill(ThemeData theme) {
    return ValueListenableBuilder<String>(
      valueListenable: AudioService.instance.focusTimerLabel,
      builder: (context, timerLabel, _) {
        return ValueListenableBuilder<String>(
          valueListenable: AudioService.instance.focusTimerMode,
          builder: (context, timerMode, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: AudioService.instance.focusIsRestPhase,
              builder: (context, isRest, _) {
                final displayLabel =
                    timerLabel.isNotEmpty ? timerLabel : '00:00:00';
                final displayMode =
                    timerMode.isNotEmpty ? timerMode : '∞';

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRest
                        ? const Color(0xFF8B6914).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: isRest
                        ? Border.all(
                            color: const Color(0xFFD4A017).withValues(alpha: 0.4),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayMode,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        displayLabel,
                        style: TextStyle(
                          color: isRest
                              ? const Color(0xFFFFD54F)
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SessionArtwork extends StatelessWidget {
  final Session session;

  const _SessionArtwork({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = normalizeSessionImageUrl(
      session.imageUrl,
      sessionId: session.id,
    );
    final placeholder = Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Icon(
        Icons.music_note_rounded,
        color: theme.colorScheme.primary,
        size: 22,
      ),
    );

    if (isOnlineImageUrl(imageUrl)) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    if (imageUrl.startsWith('/')) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    return placeholder;
  }
}
