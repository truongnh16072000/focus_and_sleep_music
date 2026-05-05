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
    required this.imageUrl,
    required this.state,
    this.tags = const [],
    this.defaultStimulation = 1.0,
    this.isPersonal = false,
    this.localPath,
  });

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
