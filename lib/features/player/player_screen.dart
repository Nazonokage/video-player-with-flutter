import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart' show Video;

import '../../core/app_state.dart';
import '../../core/state_store.dart';
import '../../core/shortcuts.dart';
import '../../core/playlist_service.dart';
import '../../widgets/seekbar.dart';
import '../../widgets/controls_bar.dart';
import '../../widgets/top_bar.dart';

import 'player_controller.dart' show PlayerController, FullscreenVideoPage;
import 'overlay_subtitle.dart' show showSubtitlesMenu;
import 'playlist_modal.dart';
import 'help_dialog.dart';

class PlayerScreen extends StatefulWidget {
  final AppStateModel state;
  final StateStore store;
  final String initialPath;
  final PlaylistService playlist; // ⬅️ playlist comes from Library

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
  late double _speed;
  late double _volume;
  Timer? _saveTimer;

  final FocusNode _focusNode = FocusNode(debugLabel: 'player_screen');
  BuildContext? _actionsCtx;

  String? _osdText;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    ctrl = PlayerController();
    _speed = widget.state.settings.speed;
    _volume = widget.state.settings.volume;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  Future<void> _open(String path) async {
    // resume from recents if available
    double? startAtSeconds;
    for (final r in widget.store.state.recents) {
      if (r.path == path && r.lastPositionMs > 0) {
        startAtSeconds = r.lastPositionMs / 1000.0;
        break;
      }
    }
    await ctrl.openPath(
      path,
      speed: _speed,
      volume: _volume,
      startAtSeconds: startAtSeconds,
    );

    // sync playlist index if path exists in playlist
    final idx = widget.playlist.items.indexOf(path);
    if (idx >= 0) widget.playlist.setIndex(idx);
  }

  Future<void> _saveProgress() async {
    final path = ctrl.currentPath ?? widget.initialPath;
    if (path.isEmpty) return;
    await widget.store.upsertRecent(
      path: path,
      positionMs: ctrl.player.state.position.inMilliseconds,
      durationMs: ctrl.player.state.duration.inMilliseconds,
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveProgress();
    ctrl.dispose();
    _fadeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (ctrl.player.state.playing) {
      ctrl.player.pause();
    } else {
      ctrl.player.play();
    }
  }

  Future<void> _toggleFullscreen() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (_, __, ___) => FullscreenVideoPage(
          ctrl: ctrl,
          onExit: () {},
          onTogglePlayPause: _togglePlayPause,
        ),
      ),
    );
    if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
  }

  void _flashOsd(String text) {
    setState(() => _osdText = text);
    _fadeCtrl.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _fadeCtrl.reverse();
      _osdText = null;
    });
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _onKey(KeyEvent event) {
    final intent = mapRawKeyToIntent(event);
    if (intent != null && _actionsCtx != null) {
      Actions.invoke(_actionsCtx!, intent);
    }
  }

  Future<void> _playByIndex(int index) async {
    widget.playlist.setIndex(index);
    final path = widget.playlist.currentPath;
    if (path == null) return;
    await _open(path);
    setState(() {});
  }

  Future<void> _playNext() async {
    final next = widget.playlist.next();
    if (next == null) return;
    await _open(next);
    setState(() {});
  }

  Future<void> _playPrev() async {
    final prev = widget.playlist.previous();
    if (prev == null) return;
    await _open(prev);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Shortcuts(
        shortcuts: defaultKeyMap,
        child: Actions(
          actions: {
            TogglePlayIntent: CallbackAction<TogglePlayIntent>(
              onInvoke: (_) {
                _togglePlayPause();
                return null;
              },
            ),
            FullscreenIntent: CallbackAction<FullscreenIntent>(
              onInvoke: (_) {
                _toggleFullscreen();
                return null;
              },
            ),
            SeekShortIntent: CallbackAction<SeekShortIntent>(
              onInvoke: (i) {
                ctrl.seekBy(i.delta);
                final pos = ctrl.player.state.position + i.delta;
                _flashOsd('Seek → ${_fmt(pos)}');
                return null;
              },
            ),
            SeekLongIntent: CallbackAction<SeekLongIntent>(
              onInvoke: (i) {
                ctrl.seekBy(i.delta);
                final pos = ctrl.player.state.position + i.delta;
                _flashOsd('Seek → ${_fmt(pos)}');
                return null;
              },
            ),
            VolumeIntent: CallbackAction<VolumeIntent>(
              onInvoke: (i) {
                final current = (ctrl.player.state.volume / 100.0).clamp(
                  0.0,
                  1.0,
                );
                final next = (current + i.delta).clamp(0.0, 1.0);
                ctrl.player.setVolume((next * 100).toDouble());
                _flashOsd('Vol ${(next * 100).round()}%');
                setState(() => _volume = next);
                return null;
              },
            ),
            ToggleTimeOsdIntent: CallbackAction<ToggleTimeOsdIntent>(
              onInvoke: (_) {
                _flashOsd(_fmt(ctrl.player.state.position));
                return null;
              },
            ),
          },
          child: Builder(
            builder: (ctx) {
              _actionsCtx = ctx;

              return Scaffold(
                backgroundColor: const Color(0xFF0a0f1e),
                body: Column(
                  children: [
                    // Custom top bar
                    TopBar(
                      onOpenPlaylist: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => PlaylistModal(
                            items: widget.playlist.items,
                            currentIndex: widget.playlist.currentIndex,
                            onSelect: (i) => _playByIndex(i),
                          ),
                        );
                        if (mounted && !_focusNode.hasFocus) {
                          _focusNode.requestFocus();
                        }
                      },
                      onOpenSubtitles: () async {
                        final applied = await showSubtitlesMenu(context, ctrl);
                        if (applied && mounted && !_focusNode.hasFocus) {
                          _focusNode.requestFocus();
                        }
                      },
                      onOpenHelp: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => const HelpDialog(),
                        );
                        if (mounted && !_focusNode.hasFocus) {
                          _focusNode.requestFocus();
                        }
                      },
                    ),

                    // Video + OSD
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) {
                            if (!_focusNode.hasFocus) {
                              _focusNode.requestFocus();
                            }
                          },
                          onTap: _togglePlayPause,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Video(
                                  controller: ctrl.video,
                                  controls: null,
                                ),
                              ),
                              if (_osdText != null)
                                Positioned(
                                  right: 16,
                                  top: 16,
                                  child: FadeTransition(
                                    opacity: _fadeCtrl,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _osdText!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
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

                    // Seekbar
                    StreamBuilder<Duration>(
                      stream: ctrl.positionStream,
                      initialData: Duration.zero,
                      builder: (_, snap) {
                        final pos = snap.data ?? Duration.zero;
                        final dur = ctrl.player.state.duration;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SeekBar(
                            position: pos,
                            duration: dur,
                            onChanged: (t) {
                              final targetMs = (dur.inMilliseconds * t).toInt();
                              ctrl.player.seek(
                                Duration(milliseconds: targetMs),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    // Controls
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: ControlsBar(
                        onPrev: _playPrev,
                        onPlayPause: _togglePlayPause,
                        onNext: _playNext,
                        isPlaying: ctrl.player.state.playing,
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
                        onToggleSubtitles: () async {
                          final applied = await showSubtitlesMenu(
                            context,
                            ctrl,
                          );
                          if (applied && mounted && !_focusNode.hasFocus) {
                            _focusNode.requestFocus();
                          }
                        },
                        onFullscreen: _toggleFullscreen,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
