import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<Session> _personalSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final personal = await _storage.getPersonalSessions();
    if (!mounted) return;
    setState(() {
      _personalSessions = personal;
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, "YOUR TRACKS"),
                  const SizedBox(height: 16),
                  if (_personalSessions.isEmpty)
                    _buildEmptySection(theme, "No uploaded tracks yet")
                  else
                    SizedBox(
                      height: 180,
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptySection(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 32,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              final url = Uri.parse('https://pixabay.com/music/search/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text("Discover music on Pixabay"),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: theme.colorScheme.primary.withValues(alpha: 0.8),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  image: DecorationImage(
                    image: session.imageUrl.startsWith('assets/')
                        ? AssetImage(session.imageUrl) as ImageProvider
                        : FileImage(File(session.imageUrl)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: session.imageUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          size: 40,
                        ),
                      )
                    : null,
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
            Text(
              session.genre,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
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
    "Sleep",
    "Meditation",
  ];
  static const _defaultCover = "assets/images/focus.png";

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
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
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
                const SizedBox(height: 20),
                Text(
                  "Upload Track",
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Add a local MP3 to your personal library.",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
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
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canSave ? _save : null,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Save Track"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
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
    return InkWell(
      onTap: isLoading || _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : icon,
              color: isSelected ? Colors.green : theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
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
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPicker(ThemeData theme) {
    final coverPath = _coverFile?.path;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            image: coverPath == null
                ? const DecorationImage(
                    image: AssetImage(_defaultCover),
                    fit: BoxFit.cover,
                  )
                : DecorationImage(
                    image: FileImage(File(coverPath)),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              _buildPickerTile(
                theme,
                title: "Label image",
                subtitle: _coverFile?.name ?? "Optional cover image",
                icon: Icons.image_outlined,
                isSelected: _coverFile != null,
                isLoading: _isPickingCover,
                onTap: _pickCover,
              ),
              if (_coverFile != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _coverFile = null),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text("Remove image"),
                  ),
                ),
              ],
            ],
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

      String imageUrl = _defaultCover;
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
