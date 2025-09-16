class RecentItem {
  final String path;
  final double lastPosition; // seconds
  final double? duration;
  final DateTime updatedAt;
  RecentItem({
    required this.path,
    required this.lastPosition,
    this.duration,
    required this.updatedAt,
  });
  RecentItem copyWith({double? lastPosition, double? duration}) => RecentItem(
    path: path,
    lastPosition: lastPosition ?? this.lastPosition,
    duration: duration ?? this.duration,
    updatedAt: DateTime.now(),
  );
  factory RecentItem.fromJson(Map<String, dynamic> j) => RecentItem(
    path: j['path'],
    lastPosition: (j['lastPosition'] ?? 0).toDouble(),
    duration: (j['duration'] as num?)?.toDouble(),
    updatedAt: DateTime.parse(j['updatedAt']),
  );
  Map<String, dynamic> toJson() => {
    "path": path,
    "lastPosition": lastPosition,
    "duration": duration,
    "updatedAt": updatedAt.toIso8601String(),
  };
}

class AppSettings {
  double volume;
  double speed;
  String theme;
  String? lastFolder;
  AppSettings({
    this.volume = .8,
    this.speed = 1.0,
    this.theme = "dark",
    this.lastFolder,
  });
  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    volume: (j['volume'] ?? .8).toDouble(),
    speed: (j['speed'] ?? 1.0).toDouble(),
    theme: j['theme'] ?? 'dark',
    lastFolder: j['lastFolder'],
  );
  Map<String, dynamic> toJson() => {
    "volume": volume,
    "speed": speed,
    "theme": theme,
    "lastFolder": lastFolder,
  };
}

class AppStateModel {
  AppSettings settings;
  List<RecentItem> recents;
  List<String> playlist;
  AppStateModel({
    required this.settings,
    required this.recents,
    required this.playlist,
  });
  factory AppStateModel.empty() =>
      AppStateModel(settings: AppSettings(), recents: [], playlist: []);
  factory AppStateModel.fromJson(Map<String, dynamic> j) => AppStateModel(
    settings: AppSettings.fromJson(j['settings'] ?? {}),
    recents: ((j['recents'] ?? []) as List)
        .map((e) => RecentItem.fromJson(e))
        .toList(),
    playlist: ((j['playlist'] ?? []) as List).map((e) => e.toString()).toList(),
  );
  Map<String, dynamic> toJson() => {
    "settings": settings.toJson(),
    "recents": recents.map((e) => e.toJson()).toList(),
    "playlist": playlist,
  };
}
