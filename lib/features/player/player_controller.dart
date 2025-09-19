import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show ImageByteFormat, Image;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_state.dart';
import '../../core/state_store.dart';
import '../../core/playlist_service.dart';
import '../../core/shortcuts.dart';

class PlayerController {
  final Player player = Player();
  late final VideoController video;
  final _posStream = StreamController<Duration>.broadcast();

  String? currentPath;

  PlayerController() {
    video = VideoController(player);
    player.stream.position.listen(_posStream.add);
  }

  // ── Streams & getters
  Stream<Duration> get positionStream => _posStream.stream;
  Duration get duration => player.state.duration;

  // ── Helpers
  String norm(String s) => s.replaceAll('\\', '/').toLowerCase();
  String fmtTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ── Playback controls
  Future<void> togglePlayPause() async {
    if (player.state.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> seekBy(Duration delta) async {
    final now = player.state.position;
    await player.seek(now + delta);
  }

  // ── Open file & resume position
  Future<void> openAndResume({
    required String path,
    required AppStateModel state,
    required PlaylistService playlist,
    double? speed,
    double? volume, // if null we use 0.5 default (not state)
  }) async {
    currentPath = path;

    // Find recent
    RecentItem? recent;
    for (final r in state.recents) {
      if (norm(r.path) == norm(path)) {
        recent = r;
        break;
      }
    }
    final double? startAtSeconds = (recent != null && recent.lastPositionMs > 0)
        ? recent.lastPositionMs / 1000.0
        : null;

    final effSpeed = speed ?? state.settings.speed;
    final effVolume =
        volume ?? 0.5; // force 50% default unless explicitly provided

    await openPath(
      path,
      startAtSeconds: startAtSeconds,
      speed: effSpeed,
      volume: effVolume,
    );

    final idx = playlist.items.indexWhere((e) => norm(e) == norm(path));
    if (idx >= 0) playlist.setIndex(idx);
  }

  Future<void> openPath(
    String path, {
    double? startAtSeconds,
    double speed = 1.0,
    double volume = .5, // keep 50% as the default here as well
  }) async {
    currentPath = path;

    await player.open(Media(path));
    await player.setRate(speed);
    await player.setVolume((volume * 100).clamp(0, 100).toDouble());

    // Wait for duration to be known before initial seek (if any)
    if (startAtSeconds != null && startAtSeconds > 0.2) {
      final gate = Completer<void>();
      late final StreamSubscription sub;
      sub = player.stream.duration.listen((d) {
        if (d > Duration.zero && !gate.isCompleted) gate.complete();
      });
      if (player.state.duration == Duration.zero) {
        await Future.any([
          gate.future,
          Future.delayed(const Duration(milliseconds: 800)),
        ]);
      }
      await sub.cancel();

      await player.seek(
        Duration(milliseconds: (startAtSeconds * 1000).round()),
      );
    }

    await player.play();
  }

  // ── Persist progress
  Future<void> saveProgress(StateStore store, {String? fallbackPath}) async {
    final path = currentPath ?? fallbackPath;
    if (path == null || path.isEmpty) return;

    await store.upsertRecent(
      path: path,
      positionMs: player.state.position.inMilliseconds,
      durationMs: player.state.duration.inMilliseconds,
    );
  }

  // ── Subtitles
  Stream<List<SubtitleTrack>> get subtitleTracksStream =>
      player.stream.tracks.map((ts) => ts.subtitle);
  List<SubtitleTrack> get subtitleTracks => player.state.tracks.subtitle;

  Future<void> disableSubtitles() async =>
      player.setSubtitleTrack(SubtitleTrack.no());
  Future<void> setSubtitleByIndex(int index) async {
    final tracks = subtitleTracks;
    if (index >= 0 && index < tracks.length) {
      await player.setSubtitleTrack(tracks[index]);
    }
  }

  Future<void> setExternalSrt(String path) async =>
      player.setSubtitleTrack(SubtitleTrack.uri(path));

  // ── Screenshot to Documents/CleanPlayer/Screenshots
  Future<void> takeScreenshot({
    required BuildContext context,
    required GlobalKey repaintKey,
    required void Function(String) onOsd,
  }) async {
    try {
      final render =
          repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (render == null) {
        onOsd('Screenshot failed');
        return;
      }

      final deviceRatio = MediaQuery.of(context).devicePixelRatio;
      final ui.Image img = await render.toImage(pixelRatio: deviceRatio);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        onOsd('Screenshot failed');
        return;
      }
      final bytes = byteData.buffer.asUint8List();

      final baseDir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory(
        p.join(baseDir.path, 'CleanPlayer', 'Screenshots'),
      );
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final base = p.basenameWithoutExtension(currentPath ?? 'screenshot');
      final file = File(p.join(screenshotsDir.path, '${base}_$ts.png'));

      await file.writeAsBytes(bytes, flush: true);
      onOsd('Saved: ${file.path}');
    } catch (_) {
      onOsd('Screenshot failed');
    }
  }

  // ── Unified actions map (used by windowed + fullscreen)
  Map<Type, Action<Intent>> buildActions({
    required VoidCallback onTogglePlayPause,
    required VoidCallback onFullscreen,
    required void Function(String) onOsd,
    required GlobalKey repaintKey,
    required BuildContext context,
    required VoidCallback onHelp, // NEW: Add this parameter
    required VoidCallback onNext,
    required VoidCallback onPrev,
    void Function(double newVolume)? onVolumeChanged,
  }) {
    return {
      TogglePlayIntent: CallbackAction<TogglePlayIntent>(
        onInvoke: (_) {
          onTogglePlayPause();
          return null;
        },
      ),
      HelpIntent: CallbackAction<HelpIntent>(
        // NEW: Add this action
        onInvoke: (_) {
          onHelp();
          return null;
        },
      ),
      FullscreenIntent: CallbackAction<FullscreenIntent>(
        onInvoke: (_) {
          onFullscreen();
          return null;
        },
      ),
      SeekShortIntent: CallbackAction<SeekShortIntent>(
        onInvoke: (i) {
          seekBy(i.delta);
          onOsd('Seek → ${fmtTime(player.state.position + i.delta)}');
          return null;
        },
      ),
      SeekLongIntent: CallbackAction<SeekLongIntent>(
        onInvoke: (i) {
          seekBy(i.delta);
          onOsd('Seek → ${fmtTime(player.state.position + i.delta)}');
          return null;
        },
      ),
      VolumeIntent: CallbackAction<VolumeIntent>(
        onInvoke: (i) {
          final current = (player.state.volume / 100.0).clamp(0.0, 1.0);
          final next = (current + i.delta).clamp(0.0, 1.0);
          player.setVolume((next * 100).toDouble());
          onVolumeChanged?.call(next);
          onOsd('Vol ${(next * 100).round()}%');
          return null;
        },
      ),
      ToggleTimeOsdIntent: CallbackAction<ToggleTimeOsdIntent>(
        onInvoke: (_) {
          onOsd(fmtTime(player.state.position));
          return null;
        },
      ),
      ScreenshotIntent: CallbackAction<ScreenshotIntent>(
        onInvoke: (_) {
          takeScreenshot(
            context: context,
            repaintKey: repaintKey,
            onOsd: onOsd,
          );
          return null;
        },
      ),
      NextItemIntent: CallbackAction<NextItemIntent>(
        onInvoke: (_) {
          onNext();
          return null;
        },
      ),
      PrevItemIntent: CallbackAction<PrevItemIntent>(
        onInvoke: (_) {
          onPrev();
          return null;
        },
      ),
      NumberSeekIntent: CallbackAction<NumberSeekIntent>(
        onInvoke: (i) {
          final dur = player.state.duration;
          if (dur > Duration.zero) {
            final ms = (dur.inMilliseconds * i.fraction).toInt();
            player.seek(Duration(milliseconds: ms));
            onOsd('Seek → ${fmtTime(Duration(milliseconds: ms))}');
          }
          return null;
        },
      ),
    };
  }

  // ── Cleanup
  void dispose() {
    _posStream.close();
    player.dispose();
  }
}
