// lib/features/player/player_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart'
    show Video, SubtitleViewConfiguration;
import 'package:path/path.dart' as p;

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
import 'volume_enhancement_dialog.dart';
import 'audio_track_dialog.dart';
import '../settings/settings_sheet.dart';

class PlayerScreen extends StatefulWidget {
  final AppStateModel state;
  final StateStore store;
  final String initialPath;
  final PlaylistService playlist;
  final PlayerController controller;
  final VoidCallback? onBackToLibrary;

  const PlayerScreen({
    super.key,
    required this.state,
    required this.store,
    required this.initialPath,
    required this.playlist,
    required this.controller,
    this.onBackToLibrary,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _videoRepaintKey = GlobalKey();

  late double _speed;
  late double _volume;
  bool _isPlaying = false; // Track playing state locally
  late String _currentFileName;

  String? _osdText;
  late SubtitleSettings _subtitleSettings;
  late VolumeEnhancement _volumeEnhancement;
  late final AnimationController _fadeCtrl;
  Timer? _saveTimer;
  bool _showRemaining = false;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<AppStateModel>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _speed = widget.state.settings.speed;
    _volume = 0.5; // start at 50%
    _subtitleSettings = widget.state.settings.subtitleSettings;
    _volumeEnhancement = widget.state.settings.volumeEnhancement;
    _currentFileName = p.basename(widget.initialPath);

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

    // Listen to state store changes for real-time updates
    _stateSubscription = widget.store.stateStream.listen((newState) {
      if (mounted) {
        setState(() {
          _subtitleSettings = newState.settings.subtitleSettings;
          _volumeEnhancement = newState.settings.volumeEnhancement;
        });
      }
    });
  }

  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if subtitle or volume settings changed
    if (oldWidget.state.settings.subtitleSettings !=
            widget.state.settings.subtitleSettings ||
        oldWidget.state.settings.volumeEnhancement !=
            widget.state.settings.volumeEnhancement) {
      _subtitleSettings = widget.state.settings.subtitleSettings;
      _volumeEnhancement = widget.state.settings.volumeEnhancement;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _playingSubscription?.cancel();
    _stateSubscription?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Setup player state listener
  void _setupPlayerListener() {
    _playingSubscription?.cancel();
    _playingSubscription = widget.controller.player.stream.playing.listen((
      playing,
    ) {
      bool wasPlaying = _isPlaying;
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
      if (playing && !wasPlaying) {
        _flashOsd(_currentFileName);
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
    _currentFileName = p.basename(path); // Update filename

    await widget.controller.openAndResume(
      path: path,
      state: widget.state,
      playlist: widget.playlist,
      speed: _speed,
      volume: _volume,
    );

    // Setup listener after player is initialized
    _setupPlayerListener();

    // Check initial playing state to flash filename if already playing on start
    if (mounted) {
      final currentPlaying = widget.controller.player.state.playing;
      setState(() {
        _isPlaying = currentPlaying;
      });
      if (currentPlaying) {
        _flashOsd(_currentFileName);
      }
    }
  }

  // ── Persist progress
  Future<void> _saveProgress() => widget.controller.saveProgress(
    widget.store,
    fallbackPath: widget.initialPath,
  );

  // ── UI actions
  void _togglePlayPause() => widget.controller.togglePlayPause();

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
        pageBuilder: (_, __, ___) => _FullscreenPage(
          ctrl: widget.controller,
          repaintKey: _videoRepaintKey,
          subtitleSettings: widget.state.settings.subtitleSettings,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _goBackToLibrary() async {
    if (widget.onBackToLibrary != null) {
      // Save current progress before going back
      await _saveProgress();

      // Stop the player
      await widget.controller.player.stop();

      // Call the callback to go back to library
      widget.onBackToLibrary!();
    }
  }

  Future<void> _showVolumeEnhancementDialog() async {
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => VolumeEnhancementDialog(
          currentSettings: _volumeEnhancement,
          onSettingsChanged: (newSettings) async {
            // Update the state in the store
            final updatedState = widget.state.copyWith(
              settings: widget.state.settings.copyWith(
                volumeEnhancement: newSettings,
              ),
            );
            widget.store.updateState(updatedState);
            await widget.store.save();

            // Apply the enhancement immediately
            await widget.controller.applyVolumeEnhancement(newSettings);

            // Update the dialog state
            setDialogState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: defaultKeyMap,
      child: Actions(
        // In the buildActions method call in player_screen.dart, add the onHelp parameter:
        actions: widget.controller.buildActions(
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
                  fileName: _currentFileName,
                  onLogoClick: _goBackToLibrary,
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
                  onOpenSubtitles: () => showSubtitleMenu(
                    context,
                    widget.controller,
                    state: widget.state,
                    store: widget.store,
                  ),
                  onVolumeEnhancement: () => _showVolumeEnhancementDialog(),
                  onOpenAudioTracks: () =>
                      showAudioTrackDialog(context, widget.controller),
                  onOpenSettings: () => showDialog(
                    context: context,
                    builder: (_) => const SettingsSheet(),
                  ),
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
                              controller: widget.controller.video,
                              controls: null,
                              subtitleViewConfiguration:
                                  SubtitleViewConfiguration(
                                    style: TextStyle(
                                      height: _subtitleSettings.height,
                                      fontSize: _subtitleSettings.fontSize,
                                      letterSpacing:
                                          _subtitleSettings.letterSpacing,
                                      wordSpacing:
                                          _subtitleSettings.wordSpacing,
                                      color: _subtitleSettings.textColor,
                                      fontWeight: _subtitleSettings.fontWeight,
                                      backgroundColor:
                                          _subtitleSettings.backgroundColor,
                                    ),
                                    textAlign: _subtitleSettings.textAlign,
                                    padding: _subtitleSettings.padding,
                                  ),
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
                  stream: widget.controller.positionStream,
                  initialData: Duration.zero,
                  builder: (_, snap) {
                    final pos = snap.data ?? Duration.zero;
                    final dur = widget.controller.player.state.duration;
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
                          widget.controller.player.seek(
                            Duration(milliseconds: targetMs),
                          );
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
                      await widget.controller.player.setRate(v);
                    },
                    volume: _volume,
                    onVolume: (v) async {
                      setState(() => _volume = v);
                      await widget.controller.player.setVolume(
                        (v * 100).clamp(0, 100).toDouble(),
                      );
                      _flashOsd('Vol ${(v * 100).round()}%');
                    },
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
  final SubtitleSettings subtitleSettings;

  const _FullscreenPage({
    required this.ctrl,
    required this.repaintKey,
    required this.subtitleSettings,
  });

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
                  child: Video(
                    controller: widget.ctrl.video,
                    controls: null,
                    subtitleViewConfiguration: SubtitleViewConfiguration(
                      style: TextStyle(
                        height: widget.subtitleSettings.height,
                        fontSize: widget.subtitleSettings.fontSize,
                        letterSpacing: widget.subtitleSettings.letterSpacing,
                        wordSpacing: widget.subtitleSettings.wordSpacing,
                        color: widget.subtitleSettings.textColor,
                        fontWeight: widget.subtitleSettings.fontWeight,
                        backgroundColor:
                            widget.subtitleSettings.backgroundColor,
                      ),
                      textAlign: widget.subtitleSettings.textAlign,
                      padding: widget.subtitleSettings.padding,
                    ),
                  ),
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
