import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/session.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import 'player_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final StorageService _storage = StorageService();
  List<Track> _savedTracks = [];
  List<Session> _personalSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await _storage.getSavedTracks();
    final personal = await _storage.getPersonalSessions();
    setState(() {
      _savedTracks = tracks;
      _personalSessions = personal;
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      final newSession = Session(
        id: 'personal_${DateTime.now().millisecondsSinceEpoch}',
        title: result.files.single.name,
        description: "User uploaded track",
        genre: "Personal",
        audioUrl: "",
        imageUrl:
            "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=1000&auto=format&fit=crop",
        state: MentalState.focus,
        isPersonal: true,
        localPath: file.path,
      );

      await _storage.savePersonalSession(newSession);
      _loadTracks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Personal music added to library!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          "Library",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos_rounded, size: 20),
            onPressed: _pickAndUploadMusic,
            tooltip: "Upload Personal Music",
          ),
          IconButton(
            icon: const Icon(Icons.download_done_rounded, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedTracks.isEmpty && _personalSessions.isEmpty
          ? _buildEmptyState(theme)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_personalSessions.isNotEmpty) ...[
                    Text(
                      "PERSONAL MUSIC",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _personalSessions.length,
                        itemBuilder: (context, index) {
                          return _buildPersonalCard(
                            _personalSessions[index],
                            theme,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  Text(
                    "SAVED TRACKS",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _savedTracks.length,
                    itemBuilder: (context, index) {
                      return _buildTrackCard(_savedTracks[index], theme);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPersonalCard(Session session, ThemeData theme) {
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
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  image: DecorationImage(
                    image: session.imageUrl.startsWith('assets/')
                        ? AssetImage(session.imageUrl) as ImageProvider
                        : NetworkImage(session.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            "Your library is empty",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Download tracks to listen offline without any distractions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _pickAndUploadMusic,
            child: const Text("UPLOAD MUSIC"),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildTrackCard(Track track, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              session: Session(
                id: track.id,
                title: track.title,
                description: "",
                genre: track.genre,
                audioUrl: track.audioUrl,
                imageUrl: track.imageUrl,
                state: MentalState.focus,
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: theme.colorScheme.surfaceVariant,
                image: DecorationImage(
                  image: track.imageUrl.startsWith('assets/')
                      ? AssetImage(track.imageUrl) as ImageProvider
                      : NetworkImage(track.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                    child: Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            track.genre.toUpperCase(),
            style: GoogleFonts.inter(
              color: theme.colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
