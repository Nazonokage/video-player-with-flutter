// lib/features/player/player_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart' show Video;

import '../../core/app_state.dart';
import '../../core/state_store.dart';
import '../../core/shortcuts.dart';
import '../../core/playlist_service.dart';

import '../../widgets/top_bar.dart';
import '../../widgets/seekbar.dart';
import '../../widgets/controls_bar.dart';

import 'player_controller.dart';
import 'overlay_subtitle.dart';
import 'playlist_modal.dart';
import 'help_dialog.dart';

class PlayerScreen extends StatefulWidget {
  final AppStateModel state;
  final StateStore store;
  final String initialPath;
  final PlaylistService playlist;

  const PlayerScreen({
    super.key,
    required this.state,
    required this.store,
    required this.initialPath,
    required this.playlist,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final PlayerController ctrl;
  final GlobalKey _videoRepaintKey = GlobalKey();

  late double _speed;
  late double _volume;
  bool _isPlaying = false; // Track playing state locally

  String? _osdText;
  late final AnimationController _fadeCtrl;
  Timer? _saveTimer;
  bool _showRemaining = false;
  StreamSubscription<bool>? _playingSubscription;

  @override
  void initState() {
    super.initState();
    ctrl = PlayerController();
    _speed = widget.state.settings.speed;
    _volume = 0.5; // start at 50%

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _open(widget.initialPath);
    _saveTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _saveProgress(),
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _playingSubscription?.cancel();
    ctrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Setup player state listener
  void _setupPlayerListener() {
    _playingSubscription?.cancel();
    _playingSubscription = ctrl.player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });
  }

  // ── OSD
  void _flashOsd(String text) {
    setState(() => _osdText = text);
    _fadeCtrl.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _fadeCtrl.reverse();
      _osdText = null;
    });
  }

  // ── Open + resume
  Future<void> _open(String path) async {
    await ctrl.openAndResume(
      path: path,
      state: widget.state,
      playlist: widget.playlist,
      speed: _speed,
      volume: _volume,
    );

    // Setup listener after player is initialized
    _setupPlayerListener();

    if (mounted) setState(() {});
  }

  // ── Persist progress
  Future<void> _saveProgress() =>
      ctrl.saveProgress(widget.store, fallbackPath: widget.initialPath);

  // ── UI actions
  void _togglePlayPause() => ctrl.togglePlayPause();

  Future<void> _playNext() async {
    final next = widget.playlist.next();
    if (next == null) return;
    await _open(next);
  }

  Future<void> _playPrev() async {
    final prev = widget.playlist.previous();
    if (prev == null) return;
    await _open(prev);
  }

  Future<void> _toggleFullscreen() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (_, __, ___) =>
            _FullscreenPage(ctrl: ctrl, repaintKey: _videoRepaintKey),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: defaultKeyMap,
      child: Actions(
        // In the buildActions method call in player_screen.dart, add the onHelp parameter:
        actions: ctrl.buildActions(
          onTogglePlayPause: _togglePlayPause,
          onFullscreen: _toggleFullscreen,
          onOsd: _flashOsd,
          repaintKey: _videoRepaintKey,
          context: context,
          onNext: _playNext,
          onPrev: _playPrev,
          onVolumeChanged: (v) => setState(() => _volume = v),
          onHelp: () => showDialog(
            // NEW: Add this parameter
            context: context,
            builder: (_) => const HelpDialog(),
          ),
        ),
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            final intent = mapRawKeyToIntent(event);
            if (intent != null) {
              Actions.invoke(node.context!, intent);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0a0f1e),
            body: Column(
              children: [
                TopBar(
                  onOpenPlaylist: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => PlaylistModal(
                        items: widget.playlist.items,
                        currentIndex: widget.playlist.currentIndex,
                        onSelect: (i) async {
                          widget.playlist.setIndex(i);
                          final selected = widget.playlist.currentPath;
                          if (selected != null) await _open(selected);
                          setState(() {});
                        },
                        onAddFiles: (paths) async {
                          await widget.playlist.addFiles(paths);
                          setState(() {});
                        },
                        onRemoveAt: (i) async {
                          await widget.playlist.removeAt(i);
                          setState(() {});
                        },
                        onClearAll: () async {
                          await widget.playlist.clear();
                          setState(() {});
                        },
                      ),
                    );
                  },
                  onOpenSubtitles: () => showSubtitleMenu(context, ctrl),
                  onOpenHelp: () => showDialog(
                    context: context,
                    builder: (_) => const HelpDialog(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            key: _videoRepaintKey,
                            child: Video(
                              controller: ctrl.video,
                              controls: null,
                            ),
                          ),
                        ),
                        if (_osdText != null)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: FadeTransition(
                              opacity: _fadeCtrl,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _osdText!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    decoration: TextDecoration.none,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Seekbar
                StreamBuilder<Duration>(
                  stream: ctrl.positionStream,
                  initialData: Duration.zero,
                  builder: (_, snap) {
                    final pos = snap.data ?? Duration.zero;
                    final dur = ctrl.player.state.duration;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: SeekBar(
                        position: pos,
                        duration: dur,
                        showRemaining: _showRemaining,
                        onToggleTimeMode: () =>
                            setState(() => _showRemaining = !_showRemaining),
                        onChanged: (t) {
                          final targetMs = (dur.inMilliseconds * t).toInt();
                          ctrl.player.seek(Duration(milliseconds: targetMs));
                        },
                      ),
                    );
                  },
                ),
                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: ControlsBar(
                    onPrev: _playPrev,
                    onPlayPause: _togglePlayPause,
                    onNext: _playNext,
                    isPlaying: _isPlaying, // Use the local state variable
                    speed: _speed,
                    onSpeed: (v) async {
                      setState(() => _speed = v);
                      await ctrl.player.setRate(v);
                    },
                    volume: _volume,
                    onVolume: (v) async {
                      setState(() => _volume = v);
                      await ctrl.player.setVolume(
                        (v * 100).clamp(0, 100).toDouble(),
                      );
                      _flashOsd('Vol ${(v * 100).round()}%');
                    },
                    onToggleSubtitles: () => showSubtitleMenu(context, ctrl),
                    onFullscreen: _toggleFullscreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fullscreen page: carries the same Actions/Shortcuts and OSD.
class _FullscreenPage extends StatefulWidget {
  final PlayerController ctrl;
  final GlobalKey repaintKey;

  const _FullscreenPage({required this.ctrl, required this.repaintKey});

  @override
  State<_FullscreenPage> createState() => _FullscreenPageState();
}

class _FullscreenPageState extends State<_FullscreenPage>
    with SingleTickerProviderStateMixin {
  String? _osd;
  late final AnimationController _fadeCtrl;
  StreamSubscription<bool>? _playingSubscription;

  void _flash(String text) {
    setState(() => _osd = text);
    _fadeCtrl.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _fadeCtrl.reverse();
      _osd = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    // Setup player state listener (removed unused _isPlaying assignment)
    _playingSubscription = widget.ctrl.player.stream.playing.listen((playing) {
      // We don't need to track playing state here since we're not using ControlsBar
      // in the fullscreen view, but we keep the subscription to avoid warnings
    });
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: defaultKeyMap,
      child: Actions(
        actions: widget.ctrl.buildActions(
          onTogglePlayPause: () => widget.ctrl.togglePlayPause(),
          onFullscreen: () => Navigator.of(context).maybePop(),
          onOsd: _flash,
          repaintKey: widget.repaintKey,
          context: context,
          onNext: () {},
          onPrev: () {},
          onVolumeChanged: (_) {},
          onHelp: () {},
        ),
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            final intent = mapRawKeyToIntent(event);
            if (intent != null) {
              Actions.invoke(node.context!, intent);
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).maybePop();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: () => widget.ctrl.togglePlayPause(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Video(controller: widget.ctrl.video, controls: null),
                ),
                if (_osd != null)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: FadeTransition(
                      opacity: _fadeCtrl,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _osd!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            decoration: TextDecoration.none,
                            fontFeatures: [FontFeature.tabularFigures()],
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
