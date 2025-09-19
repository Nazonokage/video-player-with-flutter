import 'dart:convert';

class AppSettings {
  final double volume; // 0..1
  final double speed; // 0.5..2.0

  const AppSettings({this.volume = 0.5, this.speed = 1.0});

  AppSettings copyWith({double? volume, double? speed}) =>
      AppSettings(volume: volume ?? this.volume, speed: speed ?? this.speed);

  Map<String, dynamic> toJson() => {'volume': volume, 'speed': speed};

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    volume: (j['volume'] ?? 0.8).toDouble(),
    speed: (j['speed'] ?? 1.0).toDouble(),
  );
}

class RecentItem {
  final String path;
  final int lastPositionMs;
  final int durationMs;
  final DateTime lastOpenedAt;

  const RecentItem({
    required this.path,
    required this.lastPositionMs,
    required this.durationMs,
    required this.lastOpenedAt,
  });

  double get progress =>
      durationMs > 0 ? (lastPositionMs / durationMs).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
    'path': path,
    'lastPositionMs': lastPositionMs,
    'durationMs': durationMs,
    'lastOpenedAt': lastOpenedAt.toIso8601String(),
  };

  factory RecentItem.fromJson(Map<String, dynamic> j) => RecentItem(
    path: j['path'] as String,
    lastPositionMs: (j['lastPositionMs'] ?? 0) as int,
    durationMs: (j['durationMs'] ?? 0) as int,
    lastOpenedAt:
        DateTime.tryParse(j['lastOpenedAt'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class AppStateModel {
  final AppSettings settings;
  final List<RecentItem> recents;

  const AppStateModel({required this.settings, required this.recents});

  AppStateModel copyWith({AppSettings? settings, List<RecentItem>? recents}) =>
      AppStateModel(
        settings: settings ?? this.settings,
        recents: recents ?? this.recents,
      );

  Map<String, dynamic> toJson() => {
    'settings': settings.toJson(),
    'recents': recents.map((e) => e.toJson()).toList(),
  };

  factory AppStateModel.fromJson(Map<String, dynamic> j) => AppStateModel(
    settings: AppSettings.fromJson(j['settings'] ?? const {}),
    recents: (j['recents'] as List<dynamic>? ?? [])
        .map((e) => RecentItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// Upserts a recent; moves it to top; keeps only N (default 100)
  AppStateModel upsertRecent({
    required String path,
    required int positionMs,
    required int durationMs,
    int keep = 100,
  }) {
    final now = DateTime.now();
    final list = List<RecentItem>.from(recents);
    final idx = list.indexWhere((e) => e.path == path);
    final item = RecentItem(
      path: path,
      lastPositionMs: positionMs,
      durationMs: durationMs,
      lastOpenedAt: now,
    );
    if (idx >= 0) {
      list.removeAt(idx);
    }
    list.insert(0, item);
    if (list.length > keep) list.removeRange(keep, list.length);
    return copyWith(recents: list);
  }

  AppStateModel clearRecents() => copyWith(recents: []);
}

/// Convenience (optional)
String encodeState(AppStateModel state) => jsonEncode(state.toJson());
AppStateModel decodeState(String text) =>
    AppStateModel.fromJson(jsonDecode(text));
