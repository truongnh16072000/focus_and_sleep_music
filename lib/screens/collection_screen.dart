import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:ui';
import '../data/session_data.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../utils/session_image.dart';
import 'player_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final StorageService _storage = StorageService();
  List<Session> _personalSessions = [];
  List<Session> _recentSessions = [];
  List<Session> _favoriteSessions = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  int _selectedStateIndex = 0;

  static const _tabs = ["All", "Recent", "Favorites", "Personal"];
  static const _states = ["Deep Work", "Creative", "Study", "Coding"];

  @override
  void initState() {
    super.initState();
    _loadTracks();
    AudioService.instance.historyUpdate.addListener(_loadTracks);
  }

  @override
  void dispose() {
    AudioService.instance.historyUpdate.removeListener(_loadTracks);
    super.dispose();
  }

  Future<void> _loadTracks() async {
    final personal = await _storage.getPersonalSessions();
    final recent = await _storage.getRecentSessions();
    final favorites = await StorageService.instance.getSavedTracks();
    final favoriteSessions = _resolveFavoriteSessions(favorites, personal);

    if (!mounted) return;
    setState(() {
      _personalSessions = personal;
      _recentSessions = recent;
      _favoriteSessions = favoriteSessions;
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadMusic() async {
    final session = await showModalBottomSheet<Session>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _UploadTrackSheet(),
    );

    if (session == null) return;

    await _storage.savePersonalSession(session);
    await _loadTracks();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added '${session.title}' to your tracks."),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: _screenDecoration(theme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                      child: Text(
                        "Library",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildTopTabs(theme),
                        if (_selectedTabIndex == 0) ...[
                          Divider(
                            height: 1,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildStateChips(theme),
                        ],
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    sliver: _buildTrackList(theme),
                  ),
                ],
              ),
        floatingActionButton: _selectedTabIndex == 3
            ? FloatingActionButton(
                onPressed: _pickAndUploadMusic,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: const Icon(Icons.add_to_photos_rounded),
              )
            : null,
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
        colors: [Color(0xFF201024), Color(0xFF13131F), Color(0xFF07070C)],
      ),
    );
  }

  Widget _buildTopTabs(ThemeData theme) {
    return SizedBox(
      height: 64,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Center(
                    child: Text(
                      _tabs[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: isSelected ? 1 : 0.62,
                        ),
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isSelected ? 76 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStateChips(ThemeData theme) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _states.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedStateIndex == index;

          return ChoiceChip(
            label: Text(_states[index]),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedStateIndex = index),
            showCheckmark: false,
            labelPadding: const EdgeInsets.symmetric(horizontal: 18),
            shape: const StadiumBorder(),
            side: BorderSide.none,
            selectedColor: theme.colorScheme.onSurface,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.58),
            labelStyle: GoogleFonts.inter(
              color: isSelected
                  ? theme.scaffoldBackgroundColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.68),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(vertical: 13),
          );
        },
      ),
    );
  }

  Widget _buildTrackList(ThemeData theme) {
    final sessions = _visibleSessions();

    if (sessions.isEmpty) {
      String message;
      switch (_selectedTabIndex) {
        case 1:
          message = "No tracks played recently";
          break;
        case 2:
          message = "No favorite tracks yet";
          break;
        case 3:
          message = "No uploaded tracks yet";
          break;
        default:
          message = "No tracks available in this category";
      }
      return SliverToBoxAdapter(child: _buildEmptySection(theme, message));
    }

    return SliverList.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildLibraryTrackTile(theme, sessions[index], index);
      },
    );
  }

  List<Session> _visibleSessions() {
    final selectedGenre = _states[_selectedStateIndex];
    
    // Get base list based on tab
    List<Session> baseList = switch (_selectedTabIndex) {
      0 => _allSessionsForGenre(selectedGenre),
      1 => _recentSessions,
      2 => _favoriteSessions,
      _ => _personalSessions,
    };

    // Genre filtering only applies to the "All" tab (index 0)
    // For other tabs, we show the full list as per user request
    return baseList;
  }

  List<Session> _allSessionsForGenre(String genre) {
    return switch (genre) {
      "Deep Work" => SessionData.deepWork,
      "Creative" => SessionData.creative,
      "Study" => SessionData.study,
      _ => SessionData.coding,
    };
  }

  Widget _buildLibraryTrackTile(ThemeData theme, Session session, int index) {
    final motivation = index.isOdd ? "Motivation" : "Deep Work";

    return GestureDetector(
      onTap: () => _playSession(session),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 330;
          final artWidth = isCompact ? 72.0 : 88.0;
          final rightRailWidth = isCompact ? 68.0 : 94.0;

          return Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface.withValues(alpha: 0.82),
                  const Color(0xFF23152D).withValues(alpha: 0.72),
                ],
              ),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                SizedBox(
                  width: artWidth,
                  height: double.infinity,
                  child: _buildCoverImage(theme, session),
                ),
                SizedBox(width: isCompact ? 12 : 18),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.drag_handle_rounded,
                              color: index < 5
                                  ? const Color(0xFFB837F0)
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.82,
                                    ),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: isCompact ? 14 : 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (index == 3 && !isCompact) ...[
                              const SizedBox(width: 8),
                              _buildNewBadge(theme),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.genre.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.66,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        _buildActionIcons(theme, isCompact: isCompact),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 12),
                SizedBox(
                  width: rightRailWidth,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      10,
                      isCompact ? 10 : 15,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildFocusPill(theme, isCompact: isCompact),
                        const Spacer(),
                        Text(
                          motivation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF5C8F),
                            fontSize: isCompact ? 11 : 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionIcons(ThemeData theme, {required bool isCompact}) {
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.56);
    final iconSize = isCompact ? 18.0 : 22.0;
    final gap = isCompact ? 10.0 : 16.0;

    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Row(
        children: [
          Icon(Icons.favorite_border_rounded, color: iconColor, size: iconSize),
          SizedBox(width: gap),
          Icon(Icons.thumb_down_alt_outlined, color: iconColor, size: iconSize),
          SizedBox(width: gap),
          Icon(
            Icons.download_for_offline_outlined,
            color: iconColor,
            size: iconSize - 1,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusPill(ThemeData theme, {required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 9 : 14,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "FOCUS",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: theme.colorScheme.onSurface,
          fontSize: isCompact ? 9 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildNewBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        "NEW",
        style: GoogleFonts.inter(
          color: theme.scaffoldBackgroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildCoverImage(ThemeData theme, Session session) {
    final imageUrl = normalizeSessionImageUrl(
      session.imageUrl,
      sessionId: session.id,
    );

    if (imageUrl.isEmpty) {
      return _buildImagePlaceholder(theme);
    }

    if (isOnlineImageUrl(imageUrl)) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => _buildImagePlaceholder(theme),
        errorWidget: (_, _, _) => _buildImagePlaceholder(theme),
      );
    }

    return Image.file(
      File(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildImagePlaceholder(theme),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Icon(
        Icons.music_note_rounded,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.46),
      ),
    );
  }

  void _playSession(Session session) {
    AudioService.instance.loadSession(session);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerScreen(session: session)),
    ).then((_) => _loadTracks());
  }

  Widget _buildEmptySection(ThemeData theme, String message) {
    IconData icon;
    String? actionLabel;
    VoidCallback? onAction;

    switch (_selectedTabIndex) {
      case 1: // Recent
        icon = Icons.history_rounded;
        break;
      case 2: // Favorites
        icon = Icons.favorite_border_rounded;
        actionLabel = "Browse all tracks";
        onAction = () => setState(() => _selectedTabIndex = 0);
        break;
      case 3: // Personal
        icon = Icons.cloud_upload_outlined;
        actionLabel = "Upload music";
        onAction = _pickAndUploadMusic;
        break;
      default:
        icon = Icons.library_music_outlined;
        actionLabel = "Discover more";
        onAction = () async {
          final url = Uri.parse('https://pixabay.com/music/search/');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        };
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
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

class _LibraryFilterHeader extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _LibraryFilterHeader({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _LibraryFilterHeader oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class _UploadTrackSheet extends StatefulWidget {
  const _UploadTrackSheet();

  @override
  State<_UploadTrackSheet> createState() => _UploadTrackSheetState();
}

class _UploadTrackSheetState extends State<_UploadTrackSheet> {
  static const _suggestedCategories = [
    "Deep Work",
    "Creative",
    "Study",
    "Coding",
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(text: "Personal");

  PlatformFile? _audioFile;
  PlatformFile? _coverFile;
  bool _isPickingAudio = false;
  bool _isPickingCover = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: _screenDecoration(theme),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Personal Track",
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Pixabay Suggestion Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome_rounded,
                            color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Need some focus music?",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Download free tracks from Pixabay",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final url =
                              Uri.parse('https://pixabay.com/music/search/');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Go",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    theme,
                    label: "Track name",
                    icon: Icons.title_rounded,
                    hint: "e.g. Morning focus mix",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter a track name.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    theme,
                    label: "Category",
                    icon: Icons.sell_outlined,
                    hint: "e.g. Focus, Sleep, Lo-fi",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter a category.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedCategories.map((category) {
                    return ChoiceChip(
                      label: Text(category),
                      selected: _categoryController.text.trim() == category,
                      onSelected: (_) {
                        _categoryController.text = category;
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                _buildPickerTile(
                  theme,
                  title: "MP3 audio",
                  subtitle: _audioFile?.name ?? "Select an MP3 file",
                  icon: Icons.audiotrack_rounded,
                  isSelected: _audioFile != null,
                  isLoading: _isPickingAudio,
                  onTap: _pickAudio,
                ),
                const SizedBox(height: 14),
                _buildCoverPicker(theme),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            if (_canSave)
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: FilledButton(
                          onPressed: _canSave ? _save : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save Track",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      colors: [Color(0xFF201024), Color(0xFF13131F), Color(0xFF07070C)],
    ),
  );
}

  bool get _canSave {
    return !_isSaving &&
        _audioFile?.path != null &&
        _nameController.text.trim().isNotEmpty &&
        _categoryController.text.trim().isNotEmpty;
  }

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      filled: true,
      fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildPickerTile(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ]
              : [
                  theme.colorScheme.surface.withValues(alpha: 0.4),
                  theme.colorScheme.surface.withValues(alpha: 0.1),
                ],
        ),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: isLoading || _isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : icon,
                  size: 20,
                  color: isSelected ? Colors.green : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPicker(ThemeData theme) {
    final coverPath = _coverFile?.path;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: coverPath == null
                    ? const DecorationImage(
                        image: NetworkImage(defaultSessionImageUrl),
                        fit: BoxFit.cover,
                      )
                    : DecorationImage(
                        image: FileImage(File(coverPath)),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            if (coverPath != null)
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: _isSaving
                      ? null
                      : () => setState(() => _coverFile = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _buildPickerTile(
            theme,
            title: "Track Cover",
            subtitle: _coverFile?.name ?? "Add artwork (optional)",
            icon: Icons.add_photo_alternate_rounded,
            isSelected: _coverFile != null,
            isLoading: _isPickingCover,
            onTap: _pickCover,
          ),
        ),
      ],
    );
  }

  Future<void> _pickAudio() async {
    setState(() => _isPickingAudio = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ["mp3"],
        allowMultiple: false,
        withData: false,
      );
      if (!mounted || result == null || result.files.single.path == null) {
        return;
      }

      final file = result.files.single;
      if (!file.name.toLowerCase().endsWith(".mp3")) {
        _showError("Please choose an MP3 file.");
        return;
      }

      setState(() {
        _audioFile = file;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = _titleFromFileName(file.name);
        }
      });
    } catch (error) {
      _showError("Could not select audio file.");
      debugPrint("Error picking audio: $error");
    } finally {
      if (mounted) setState(() => _isPickingAudio = false);
    }
  }

  Future<void> _pickCover() async {
    setState(() => _isPickingCover = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ["jpg", "jpeg", "png", "webp"],
        allowMultiple: false,
        withData: false,
      );
      if (!mounted || result == null || result.files.single.path == null) {
        return;
      }
      setState(() => _coverFile = result.files.single);
    } catch (error) {
      _showError("Could not select image file.");
      debugPrint("Error picking image: $error");
    } finally {
      if (mounted) setState(() => _isPickingCover = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final audioPath = _audioFile?.path;
    if (audioPath == null) {
      _showError("Select an MP3 file.");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final id = "personal_${now.microsecondsSinceEpoch}";
      final title = _nameController.text.trim();
      final audioLocalPath = await _copyToAppLibrary(
        sourcePath: audioPath,
        directoryName: "audio",
        baseName: "${id}_${_sanitizeFileName(title)}",
        fallbackExtension: ".mp3",
      );

      String imageUrl = defaultSessionImageUrl;
      final coverPath = _coverFile?.path;
      if (coverPath != null) {
        imageUrl = await _copyToAppLibrary(
          sourcePath: coverPath,
          directoryName: "covers",
          baseName: "${id}_cover",
          fallbackExtension: ".jpg",
        );
      }

      final session = Session(
        id: id,
        title: title,
        description: "User uploaded track",
        genre: _categoryController.text.trim(),
        audioUrl: "",
        imageUrl: imageUrl,
        state: MentalState.focus,
        isPersonal: true,
        localPath: audioLocalPath,
      );

      if (!mounted) return;
      Navigator.of(context).pop(session);
    } catch (error) {
      _showError("Could not save this track.");
      debugPrint("Error saving personal track: $error");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String> _copyToAppLibrary({
    required String sourcePath,
    required String directoryName,
    required String baseName,
    required String fallbackExtension,
  }) async {
    final source = File(sourcePath);
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(
      "${appDir.path}/personal_tracks/$directoryName",
    );
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final extension = _fileExtension(sourcePath).isEmpty
        ? fallbackExtension
        : _fileExtension(sourcePath);
    final targetPath = "${targetDir.path}/$baseName$extension";
    final copied = await source.copy(targetPath);
    return copied.path;
  }

  String _fileExtension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf(".");
    if (dot == -1 || dot == name.length - 1) return "";
    return name.substring(dot).toLowerCase();
  }

  String _titleFromFileName(String fileName) {
    final dot = fileName.lastIndexOf(".");
    final name = dot == -1 ? fileName : fileName.substring(0, dot);
    return name
        .replaceAll(RegExp(r"[_-]+"), " ")
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9]+"), "_")
        .replaceAll(RegExp(r"_+"), "_")
        .replaceAll(RegExp(r"^_|_$"), "");
    return sanitized.isEmpty ? "track" : sanitized;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
