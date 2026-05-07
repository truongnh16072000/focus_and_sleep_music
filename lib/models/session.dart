import '../utils/session_image.dart';

enum MentalState { focus, sleep, relax, meditate }

class Session {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String audioUrl;
  final String? assetPath;
  final String imageUrl;
  final MentalState state;
  final List<String> tags;
  double defaultStimulation;
  final bool isPersonal;
  final String? localPath;

  Session({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    this.audioUrl = '',
    this.assetPath,
    required String imageUrl,
    required this.state,
    this.tags = const [],
    this.defaultStimulation = 1.0,
    this.isPersonal = false,
    this.localPath,
  }) : imageUrl = normalizeSessionImageUrl(imageUrl, sessionId: id);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'genre': genre,
    'audioUrl': audioUrl,
    'assetPath': assetPath,
    'imageUrl': imageUrl,
    'state': state.index,
    'tags': tags,
    'defaultStimulation': defaultStimulation,
    'isPersonal': isPersonal,
    'localPath': localPath,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    genre: json['genre'] as String? ?? '',
    audioUrl: json['audioUrl'] as String? ?? '',
    assetPath: json['assetPath'] as String?,
    imageUrl: json['imageUrl'] as String? ?? '',
    state: MentalState.values[json['state'] as int? ?? 0],
    tags:
        (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        [],
    defaultStimulation: (json['defaultStimulation'] as num?)?.toDouble() ?? 1.0,
    isPersonal: json['isPersonal'] as bool? ?? false,
    localPath: json['localPath'] as String?,
  );
}

enum TimerMode { infinite, timer, intervals }

class TimerSettings {
  final TimerMode mode;
  final int timerDurationMinutes; // For Timer mode
  final int workMinutes; // For Intervals mode
  final int restMinutes; // For Intervals mode
  final bool activateQuotes; // For Infinite mode
  final String intervalSound; // 'voice' or 'chime'
  final String timerEffect; // 'stop', 'chime', 'voice'

  TimerSettings({
    this.mode = TimerMode.timer,
    this.timerDurationMinutes = 90,
    this.workMinutes = 25,
    this.restMinutes = 5,
    this.activateQuotes = false,
    this.intervalSound = 'voice',
    this.timerEffect = 'stop',
  });

  Map<String, dynamic> toJson() => {
    'mode': mode.index,
    'timerDurationMinutes': timerDurationMinutes,
    'workMinutes': workMinutes,
    'restMinutes': restMinutes,
    'activateQuotes': activateQuotes,
    'intervalSound': intervalSound,
    'timerEffect': timerEffect,
  };

  factory TimerSettings.fromJson(Map<String, dynamic> json) => TimerSettings(
    mode: TimerMode.values[json['mode'] as int? ?? 1],
    timerDurationMinutes: json['timerDurationMinutes'] as int? ?? 90,
    workMinutes: json['workMinutes'] as int? ?? 25,
    restMinutes: json['restMinutes'] as int? ?? 5,
    activateQuotes: json['activateQuotes'] as bool? ?? false,
    intervalSound: json['intervalSound'] as String? ?? 'voice',
    timerEffect: json['timerEffect'] as String? ?? 'stop',
  );

  TimerSettings copyWith({
    TimerMode? mode,
    int? timerDurationMinutes,
    int? workMinutes,
    int? restMinutes,
    bool? activateQuotes,
    String? intervalSound,
    String? timerEffect,
  }) {
    return TimerSettings(
      mode: mode ?? this.mode,
      timerDurationMinutes: timerDurationMinutes ?? this.timerDurationMinutes,
      workMinutes: workMinutes ?? this.workMinutes,
      restMinutes: restMinutes ?? this.restMinutes,
      activateQuotes: activateQuotes ?? this.activateQuotes,
      intervalSound: intervalSound ?? this.intervalSound,
      timerEffect: timerEffect ?? this.timerEffect,
    );
  }
}
