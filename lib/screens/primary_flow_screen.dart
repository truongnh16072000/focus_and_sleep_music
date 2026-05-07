import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/session_data.dart';
import '../services/audio_service.dart';
import '../models/session.dart';
import '../utils/session_image.dart';
import 'player_screen.dart';

class PrimaryFlowScreen extends StatefulWidget {
  final MentalState mentalState;

  const PrimaryFlowScreen({super.key, required this.mentalState});

  @override
  State<PrimaryFlowScreen> createState() => _PrimaryFlowScreenState();
}

class _PrimaryFlowScreenState extends State<PrimaryFlowScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: SessionData.categories.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final category = SessionData.categories[_tabController.index];
      AudioService.instance.setQueue(category.sessions);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mentalState) {
      case MentalState.focus:
        return 'Focus';
      case MentalState.sleep:
        return 'Sleep';
      case MentalState.relax:
        return 'Relax';
      case MentalState.meditate:
        return 'Meditate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          _title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: SessionData.categories.map((cat) {
            return Tab(text: cat.name);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: SessionData.categories.map((category) {
          return _buildSessionList(category.sessions, theme);
        }).toList(),
      ),
    );
  }

  Widget _buildSessionList(List<Session> sessions, ThemeData theme) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(
          'No sessions available.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session, index, theme);
      },
    );
  }

  Widget _buildSessionCard(Session session, int index, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = normalizeSessionImageUrl(
      session.imageUrl,
      sessionId: session.id,
    );
    return GestureDetector(
      onTap: () {
        AudioService.instance.loadSession(session);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(session: session),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: Container(
                width: 72,
                height: 72,
                color: theme.colorScheme.surfaceContainerHighest,
                child: isOnlineImageUrl(imageUrl)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _buildImagePlaceholder(theme),
                        errorWidget: (context, url, error) =>
                            _buildImagePlaceholder(theme),
                      )
                    : _buildImagePlaceholder(theme),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 13,
                      ),
                    ),
                    if (session.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: session.tags.take(2).map((tag) {
                          return Container(
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
                              tag,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Icon(Icons.music_note, color: theme.colorScheme.primary, size: 28);
  }
}
