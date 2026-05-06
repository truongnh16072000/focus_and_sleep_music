import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

class Track {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String imageUrl;
  final String audioUrl;
  final String? assetPath;
  final bool isPersonal;
  final String? localPath;

  Track({
    required this.id,
    required this.title,
    this.description = '',
    required this.genre,
    required this.imageUrl,
    this.audioUrl = '',
    this.assetPath,
    this.isPersonal = false,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'genre': genre,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'assetPath': assetPath,
    'isPersonal': isPersonal,
    'localPath': localPath,
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    genre: json['genre'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    audioUrl: json['audioUrl'] as String? ?? '',
    assetPath: json['assetPath'] as String?,
    isPersonal: json['isPersonal'] as bool? ?? false,
    localPath: json['localPath'] as String?,
  );
}

class FocusSessionRecord {
  final String id;
  final DateTime startedAt;
  final int minutes;
  final String sessionId;
  final String title;
  final String genre;

  FocusSessionRecord({
    required this.id,
    required this.startedAt,
    required this.minutes,
    required this.sessionId,
    required this.title,
    required this.genre,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'minutes': minutes,
    'sessionId': sessionId,
    'title': title,
    'genre': genre,
  };

  factory FocusSessionRecord.fromJson(Map<String, dynamic> json) =>
      FocusSessionRecord(
        id: json['id'] as String? ?? '',
        startedAt:
            DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
        minutes: json['minutes'] as int? ?? 0,
        sessionId: json['sessionId'] as String? ?? '',
        title: json['title'] as String? ?? 'Focus session',
        genre: json['genre'] as String? ?? 'Focus',
      );
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  static StorageService get instance => _instance;
  StorageService._internal();

  static const String _savedTracksKey = 'saved_tracks';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _personalSessionsKey = 'personal_sessions';
  static const String _recentSessionsKey = 'recent_sessions';
  static const String _streakCountKey = 'streak_count';
  static const String _lastSessionDateKey = 'last_session_date';
  static const String _totalSessionsKey = 'total_sessions';
  static const String _focusSessionRecordsKey = 'focus_session_records';
  static const String _focusScreenLockEnabledKey = 'focus_screen_lock_enabled';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _safePrefs {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  Future<void> saveTrack(Track track) async {
    final List<String> saved = _safePrefs.getStringList(_savedTracksKey) ?? [];

    if (!saved.any((t) => Track.fromJson(jsonDecode(t)).id == track.id)) {
      saved.add(jsonEncode(track.toJson()));
      await _safePrefs.setStringList(_savedTracksKey, saved);
    }
  }

  Future<List<Track>> getSavedTracks() async {
    final List<String> saved = _safePrefs.getStringList(_savedTracksKey) ?? [];
    return saved.map((t) => Track.fromJson(jsonDecode(t))).toList();
  }

  Future<void> removeTrack(String trackId) async {
    final List<String> saved = _safePrefs.getStringList(_savedTracksKey) ?? [];
    saved.removeWhere((t) => Track.fromJson(jsonDecode(t)).id == trackId);
    await _safePrefs.setStringList(_savedTracksKey, saved);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    await _safePrefs.setBool(_onboardingCompleteKey, true);
  }

  Future<void> savePersonalSession(Session session) async {
    List<String> personal =
        _safePrefs.getStringList(_personalSessionsKey) ?? [];
    personal.removeWhere(
      (s) => Session.fromJson(jsonDecode(s)).id == session.id,
    );
    personal.insert(0, jsonEncode(session.toJson()));
    await _safePrefs.setStringList(_personalSessionsKey, personal);
  }

  Future<List<Session>> getPersonalSessions() async {
    List<String> personal =
        _safePrefs.getStringList(_personalSessionsKey) ?? [];
    return personal.map((s) => Session.fromJson(jsonDecode(s))).toList();
  }

  Future<void> saveRecentSession(Session session) async {
    List<String> recentJson =
        _safePrefs.getStringList(_recentSessionsKey) ?? [];

    recentJson.removeWhere((s) {
      final decoded = jsonDecode(s);
      return decoded['id'] == session.id;
    });

    recentJson.insert(0, jsonEncode(session.toJson()));

    if (recentJson.length > 10) {
      recentJson = recentJson.sublist(0, 10);
    }

    await _safePrefs.setStringList(_recentSessionsKey, recentJson);
    await _updateStreak();
  }

  Future<List<Session>> getRecentSessions() async {
    List<String> recentJson =
        _safePrefs.getStringList(_recentSessionsKey) ?? [];
    return recentJson.map((s) => Session.fromJson(jsonDecode(s))).toList();
  }

  Future<int> getStreakCount() async {
    return _safePrefs.getInt(_streakCountKey) ?? 0;
  }

  Future<int> getTotalSessions() async {
    return _safePrefs.getInt(_totalSessionsKey) ?? 0;
  }

  Future<bool> saveFocusSessionRecord({
    required Duration duration,
    Session? session,
    DateTime? startedAt,
  }) async {
    if (duration.inSeconds < 60) return false;

    List<String> records =
        _safePrefs.getStringList(_focusSessionRecordsKey) ?? [];
    final now = DateTime.now();
    final minutes = (duration.inSeconds / 60).round().clamp(1, 1440).toInt();
    final record = FocusSessionRecord(
      id: 'focus_${now.microsecondsSinceEpoch}',
      startedAt: startedAt ?? now,
      minutes: minutes,
      sessionId: session?.id ?? '',
      title: session?.title ?? 'Focus session',
      genre: session?.genre ?? 'Focus',
    );

    records.insert(0, jsonEncode(record.toJson()));
    if (records.length > 180) {
      records = records.sublist(0, 180);
    }

    await _safePrefs.setStringList(_focusSessionRecordsKey, records);
    return true;
  }

  Future<List<FocusSessionRecord>> getFocusSessionRecords() async {
    final records = _safePrefs.getStringList(_focusSessionRecordsKey) ?? [];
    return records
        .map((record) => FocusSessionRecord.fromJson(jsonDecode(record)))
        .toList();
  }

  bool isFocusScreenLockEnabled() {
    return _safePrefs.getBool(_focusScreenLockEnabledKey) ?? false;
  }

  Future<void> setFocusScreenLockEnabled(bool enabled) async {
    await _safePrefs.setBool(_focusScreenLockEnabledKey, enabled);
  }

  Future<void> _updateStreak() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayStr = _dateKey(todayDate);
    final lastDate = _safePrefs.getString(_lastSessionDateKey);

    int currentStreak = _safePrefs.getInt(_streakCountKey) ?? 0;
    int totalSessions = _safePrefs.getInt(_totalSessionsKey) ?? 0;
    totalSessions++;

    if (lastDate == null) {
      currentStreak = 1;
    } else {
      final lastDateParsed = _parseDateKey(lastDate);
      final difference = lastDateParsed == null
          ? null
          : todayDate.difference(lastDateParsed).inDays;

      if (difference == null) {
        currentStreak = 1;
      } else if (difference == 0) {
        await _safePrefs.setInt(_totalSessionsKey, totalSessions);
        return;
      } else if (difference == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
    }

    await _safePrefs.setString(_lastSessionDateKey, todayStr);
    await _safePrefs.setInt(_streakCountKey, currentStreak);
    await _safePrefs.setInt(_totalSessionsKey, totalSessions);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _parseDateKey(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final parts = value.split('-');
    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }
}
