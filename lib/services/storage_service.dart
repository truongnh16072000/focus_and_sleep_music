import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

class Track {
  final String id;
  final String title;
  final String genre;
  final String imageUrl;
  final String audioUrl;

  Track({
    required this.id,
    required this.title,
    required this.genre,
    required this.imageUrl,
    this.audioUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'genre': genre,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    genre: json['genre'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    audioUrl: json['audioUrl'] as String? ?? '',
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

  Future<void> _updateStreak() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastDate = _safePrefs.getString(_lastSessionDateKey);

    int currentStreak = _safePrefs.getInt(_streakCountKey) ?? 0;
    int totalSessions = _safePrefs.getInt(_totalSessionsKey) ?? 0;

    if (lastDate == null) {
      currentStreak = 1;
    } else {
      final lastDateParsed = DateTime.parse(lastDate);
      final difference = today.difference(lastDateParsed).inDays;

      if (difference == 0) {
        // Same day, streak continues
      } else if (difference == 1) {
        // Consecutive day, increment streak
        currentStreak++;
      } else {
        // Gap in streak, reset
        currentStreak = 1;
      }
    }

    await _safePrefs.setString(_lastSessionDateKey, todayStr);
    await _safePrefs.setInt(_streakCountKey, currentStreak);
    await _safePrefs.setInt(_totalSessionsKey, totalSessions + 1);
  }
}
