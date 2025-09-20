import 'dart:convert';
import 'package:flutter/material.dart';

class VolumeEnhancement {
  final bool enabled;
  final double boost; // 0.0 to 2.0 (1.0 = normal)
  final double bass; // -1.0 to 1.0
  final double treble; // -1.0 to 1.0
  final bool normalize; // Volume normalization
  final double dynamicRange; // 0.0 to 1.0 (compression)

  const VolumeEnhancement({
    this.enabled = false,
    this.boost = 1.0,
    this.bass = 0.0,
    this.treble = 0.0,
    this.normalize = false,
    this.dynamicRange = 1.0,
  });

  VolumeEnhancement copyWith({
    bool? enabled,
    double? boost,
    double? bass,
    double? treble,
    bool? normalize,
    double? dynamicRange,
  }) =>
      VolumeEnhancement(
        enabled: enabled ?? this.enabled,
        boost: boost ?? this.boost,
        bass: bass ?? this.bass,
        treble: treble ?? this.treble,
        normalize: normalize ?? this.normalize,
        dynamicRange: dynamicRange ?? this.dynamicRange,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'boost': boost,
    'bass': bass,
    'treble': treble,
    'normalize': normalize,
    'dynamicRange': dynamicRange,
  };

  factory VolumeEnhancement.fromJson(Map<String, dynamic> j) => VolumeEnhancement(
    enabled: j['enabled'] ?? false,
    boost: (j['boost'] ?? 1.0).toDouble(),
    bass: (j['bass'] ?? 0.0).toDouble(),
    treble: (j['treble'] ?? 0.0).toDouble(),
    normalize: j['normalize'] ?? false,
    dynamicRange: (j['dynamicRange'] ?? 1.0).toDouble(),
  );
}

class SubtitleSettings {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final EdgeInsets padding;
  final double height;
  final double letterSpacing;
  final double wordSpacing;

  const SubtitleSettings({
    this.fontSize = 24.0,
    this.textColor = const Color(0xffffffff),
    this.backgroundColor = const Color(0xaa000000),
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.all(24.0),
    this.height = 1.4,
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
  });

  SubtitleSettings copyWith({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    EdgeInsets? padding,
    double? height,
    double? letterSpacing,
    double? wordSpacing,
  }) =>
      SubtitleSettings(
        fontSize: fontSize ?? this.fontSize,
        textColor: textColor ?? this.textColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        fontWeight: fontWeight ?? this.fontWeight,
        textAlign: textAlign ?? this.textAlign,
        padding: padding ?? this.padding,
        height: height ?? this.height,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        wordSpacing: wordSpacing ?? this.wordSpacing,
      );

  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'textColor': textColor.toARGB32(),
    'backgroundColor': backgroundColor.toARGB32(),
    'fontWeight': fontWeight.index,
    'textAlign': textAlign.index,
    'paddingLeft': padding.left,
    'paddingTop': padding.top,
    'paddingRight': padding.right,
    'paddingBottom': padding.bottom,
    'height': height,
    'letterSpacing': letterSpacing,
    'wordSpacing': wordSpacing,
  };

  factory SubtitleSettings.fromJson(Map<String, dynamic> j) => SubtitleSettings(
    fontSize: (j['fontSize'] ?? 24.0).toDouble(),
    textColor: Color(j['textColor'] ?? const Color(0xffffffff).toARGB32()),
    backgroundColor: Color(j['backgroundColor'] ?? const Color(0xaa000000).toARGB32()),
    fontWeight: FontWeight.values[j['fontWeight'] ?? FontWeight.normal.index],
    textAlign: TextAlign.values[j['textAlign'] ?? TextAlign.center.index],
    padding: EdgeInsets.fromLTRB(
      (j['paddingLeft'] ?? 24.0).toDouble(),
      (j['paddingTop'] ?? 24.0).toDouble(),
      (j['paddingRight'] ?? 24.0).toDouble(),
      (j['paddingBottom'] ?? 24.0).toDouble(),
    ),
    height: (j['height'] ?? 1.4).toDouble(),
    letterSpacing: (j['letterSpacing'] ?? 0.0).toDouble(),
    wordSpacing: (j['wordSpacing'] ?? 0.0).toDouble(),
  );
}

class AppSettings {
  final double volume; // 0..1
  final double speed; // 0.5..2.0
  final VolumeEnhancement volumeEnhancement;
  final SubtitleSettings subtitleSettings;

  const AppSettings({
    this.volume = 0.5, 
    this.speed = 1.0,
    this.volumeEnhancement = const VolumeEnhancement(),
    this.subtitleSettings = const SubtitleSettings(),
  });

  AppSettings copyWith({
    double? volume, 
    double? speed,
    VolumeEnhancement? volumeEnhancement,
    SubtitleSettings? subtitleSettings,
  }) =>
      AppSettings(
        volume: volume ?? this.volume, 
        speed: speed ?? this.speed,
        volumeEnhancement: volumeEnhancement ?? this.volumeEnhancement,
        subtitleSettings: subtitleSettings ?? this.subtitleSettings,
      );

  Map<String, dynamic> toJson() => {
    'volume': volume, 
    'speed': speed,
    'volumeEnhancement': volumeEnhancement.toJson(),
    'subtitleSettings': subtitleSettings.toJson(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    volume: (j['volume'] ?? 0.8).toDouble(),
    speed: (j['speed'] ?? 1.0).toDouble(),
    volumeEnhancement: j['volumeEnhancement'] != null 
        ? VolumeEnhancement.fromJson(j['volumeEnhancement'])
        : const VolumeEnhancement(),
    subtitleSettings: j['subtitleSettings'] != null 
        ? SubtitleSettings.fromJson(j['subtitleSettings'])
        : const SubtitleSettings(),
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
