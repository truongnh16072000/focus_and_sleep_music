import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/session.dart';
import 'storage_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  static AudioService get instance => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<double> stimulationLevel = ValueNotifier(1.0);
  final ValueNotifier<Session?> currentSession = ValueNotifier(null);
  final ValueNotifier<int> historyUpdate = ValueNotifier(0);
  final ValueNotifier<List<Session>> queue = ValueNotifier([]);
  final ValueNotifier<int> queueIndex = ValueNotifier(-1);

  bool _isInitialized = false;
  Session? _pendingSession;
  final Stopwatch _focusStopwatch = Stopwatch();
  Duration _accumulatedFocusTime = Duration.zero;
  Session? _trackedFocusSession;
  DateTime? _focusStartedAt;

  Future<void> init() async {
    if (_isInitialized) return;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.playingStream.listen((playing) {
      isPlaying.value = playing;
      _handlePlaybackTracking(playing);
    });

    _player.positionStream.listen((p) {
      position.value = p;
    });

    _player.durationStream.listen((d) {
      duration.value = d ?? Duration.zero;
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onSessionComplete();
      }
    });

    await _player.setLoopMode(LoopMode.one);
    _isInitialized = true;
  }

  void setQueue(List<Session> sessions, {int startIndex = 0}) {
    queue.value = List.from(sessions);
    queueIndex.value = startIndex;
    if (startIndex >= 0 && startIndex < sessions.length) {
      currentSession.value = sessions[startIndex];
    }
  }

  Future<void> loadSession(Session session) async {
    try {
      await persistFocusTime();
      currentSession.value = session;
      _pendingSession = session;

      if (session.isPersonal && session.localPath != null) {
        await _player.setFilePath(session.localPath!);
      } else if (session.assetPath != null && session.assetPath!.isNotEmpty) {
        await _player.setAsset(session.assetPath!);
      } else if (session.audioUrl.isNotEmpty) {
        await _player.setUrl(session.audioUrl);
      } else {
        debugPrint("Error: No audio source for session ${session.id}");
        return;
      }

      await _player.setVolume(stimulationLevel.value);
      await _player.play();
      _startFocusTrackingFor(session);

      // Save to recent history as soon as it starts playing
      await StorageService.instance.saveRecentSession(session);
      historyUpdate.value++;
    } catch (e) {
      debugPrint("Error loading session: $e");
    }
  }

  Future<void> playTrack(String url) async {
    try {
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await persistFocusTime();
    isPlaying.value = false;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    final currentQueue = queue.value;
    if (currentQueue.isEmpty) return;

    int nextIndex = (queueIndex.value + 1) % currentQueue.length;
    queueIndex.value = nextIndex;
    await loadSession(currentQueue[nextIndex]);
  }

  Future<void> skipToPrevious() async {
    final currentQueue = queue.value;
    if (currentQueue.isEmpty) return;

    int prevIndex =
        (queueIndex.value - 1 + currentQueue.length) % currentQueue.length;
    queueIndex.value = prevIndex;
    await loadSession(currentQueue[prevIndex]);
  }

  Future<void> setStimulationLevel(double level) async {
    stimulationLevel.value = level;
    await _player.setVolume(level.clamp(0.0, 1.0));
  }

  void _onSessionComplete() {
    // If loop mode is one, this won't be called.
    // If we had a queue and wanted to loop through it, we would handle it here.
    if (queue.value.isNotEmpty && _player.loopMode == LoopMode.off) {
      skipToNext();
    }
  }

  Future<bool> persistFocusTime({
    bool continueIfPlaying = false,
    bool notifyListeners = true,
  }) async {
    _captureCurrentFocusSegment();

    final session =
        _trackedFocusSession ?? currentSession.value ?? _pendingSession;
    final startedAt = _focusStartedAt;
    if (session == null || startedAt == null) {
      return false;
    }

    final didSave = await StorageService.instance.saveFocusSessionRecord(
      duration: _accumulatedFocusTime,
      session: session,
      startedAt: startedAt,
    );

    if (!didSave) {
      if (continueIfPlaying && _player.playing) {
        _focusStopwatch.start();
      }
      return false;
    }

    _resetFocusTracking();

    if (continueIfPlaying && _player.playing && currentSession.value != null) {
      _startFocusTrackingFor(currentSession.value!);
    }

    if (notifyListeners) {
      historyUpdate.value++;
    }
    return true;
  }

  void _handlePlaybackTracking(bool playing) {
    if (playing) {
      final session = currentSession.value ?? _pendingSession;
      if (session != null) {
        _startFocusTrackingFor(session);
      }
      return;
    }

    _captureCurrentFocusSegment();
  }

  void _startFocusTrackingFor(Session session) {
    if (_trackedFocusSession?.id != session.id) {
      _resetFocusTracking();
      _trackedFocusSession = session;
      _focusStartedAt = DateTime.now();
    }

    if (!_focusStopwatch.isRunning) {
      _focusStopwatch.start();
    }
  }

  void _captureCurrentFocusSegment() {
    if (!_focusStopwatch.isRunning) return;

    _accumulatedFocusTime += _focusStopwatch.elapsed;
    _focusStopwatch
      ..stop()
      ..reset();
  }

  void _resetFocusTracking() {
    _focusStopwatch
      ..stop()
      ..reset();
    _accumulatedFocusTime = Duration.zero;
    _trackedFocusSession = null;
    _focusStartedAt = null;
  }

  Future<void> dispose() async {
    await persistFocusTime();
    await _player.dispose();
    isPlaying.dispose();
    position.dispose();
    duration.dispose();
    stimulationLevel.dispose();
    currentSession.dispose();
    historyUpdate.dispose();
    queue.dispose();
    queueIndex.dispose();
  }
}
