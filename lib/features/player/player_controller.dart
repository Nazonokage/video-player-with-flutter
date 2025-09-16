import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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

  Stream<Duration> get positionStream => _posStream.stream;
  Duration get duration => player.state.duration;

  Future<void> openPath(
    String path, {
    double? startAtSeconds,
    double speed = 1.0,
    double volume = .8,
  }) async {
    currentPath = path;
    await player.open(Media(path));
    await player.setRate(speed);
    await player.setVolume((volume * 100).clamp(0, 100).toDouble());
    if ((startAtSeconds ?? 0) > 1) {
      await player.seek(
        Duration(milliseconds: (startAtSeconds! * 1000).round()),
      );
    }
    await player.play();
  }

  double positionSeconds() {
    final pos = player.state.position;
    return pos.inMilliseconds / 1000.0;
  }

  Future<void> seekBy(Duration delta) async {
    final now = player.state.position;
    await player.seek(now + delta);
  }

  // ---------- Subtitles helpers ----------
  Tracks get tracks => player.state.tracks;
  Stream<Tracks> get tracksStream => player.stream.tracks;
  List<SubtitleTrack> get embeddedSubtitleTracks =>
      player.state.tracks.subtitle;

  Future<void> setSubtitleByIndex(int index) async {
    final subs = embeddedSubtitleTracks;
    if (index >= 0 && index < subs.length) {
      await player.setSubtitleTrack(subs[index]);
    }
  }

  Future<void> disableSubtitles() async {
    await player.setSubtitleTrack(SubtitleTrack.no());
  }

  Future<void> setExternalSrt(String srtText, {String? title}) async {
    await player.setSubtitleTrack(SubtitleTrack.data(srtText, title: title));
  }

  void dispose() {
    _posStream.close();
    player.dispose();
  }
}

class FullscreenVideoPage extends StatefulWidget {
  final PlayerController ctrl;
  final VoidCallback onExit;
  final VoidCallback onTogglePlayPause;

  const FullscreenVideoPage({
    super.key,
    required this.ctrl,
    required this.onExit,
    required this.onTogglePlayPause,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode(debugLabel: 'fullscreen');
  final GlobalKey _actionsKey = GlobalKey(); // capture Actions context
  BuildContext? _actionsCtx;

  String? _osdText;
  Timer? _osdTimer;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  void _flashOsd(String text) {
    setState(() => _osdText = text);
    _fadeController.forward(from: 0.0);
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _fadeController.reverse();
      _osdText = null;
    });
  }

  void _exitFullscreen() {
    Navigator.of(context).pop();
    widget.onExit();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _osdTimer?.cancel();
    _fadeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    final intent = mapRawKeyToIntent(event);
    if (intent != null && _actionsCtx != null) {
      Actions.invoke(_actionsCtx!, intent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) => widget.onExit(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Shortcuts(
            shortcuts: defaultKeyMap,
            child: Actions(
              key: _actionsKey,
              actions: {
                FullscreenIntent: CallbackAction<FullscreenIntent>(
                  onInvoke: (_) {
                    _exitFullscreen();
                    return null;
                  },
                ),
                TogglePlayIntent: CallbackAction<TogglePlayIntent>(
                  onInvoke: (_) {
                    widget.onTogglePlayPause();
                    return null;
                  },
                ),
                SeekShortIntent: CallbackAction<SeekShortIntent>(
                  onInvoke: (i) {
                    widget.ctrl.seekBy(i.delta);
                    final pos = widget.ctrl.player.state.position + i.delta;
                    _flashOsd('Seek → ${_fmt(pos)}');
                    return null;
                  },
                ),
                SeekLongIntent: CallbackAction<SeekLongIntent>(
                  onInvoke: (i) {
                    widget.ctrl.seekBy(i.delta);
                    final pos = widget.ctrl.player.state.position + i.delta;
                    _flashOsd('Seek → ${_fmt(pos)}');
                    return null;
                  },
                ),
                VolumeIntent: CallbackAction<VolumeIntent>(
                  onInvoke: (i) {
                    final current = (widget.ctrl.player.state.volume / 100.0)
                        .clamp(0.0, 1.0);
                    final next = (current + i.delta).clamp(0.0, 1.0);
                    widget.ctrl.player.setVolume((next * 100).toDouble());
                    _flashOsd('Vol ${(next * 100).round()}%');
                    return null;
                  },
                ),
                ToggleTimeOsdIntent: CallbackAction<ToggleTimeOsdIntent>(
                  onInvoke: (_) {
                    final pos = widget.ctrl.player.state.position;
                    _flashOsd(_fmt(pos));
                    return null;
                  },
                ),
              },
              child: Builder(
                builder: (ctx) {
                  _actionsCtx = ctx; // capture a descendant of Actions
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      if (!_focusNode.hasFocus) _focusNode.requestFocus();
                    },
                    onTap: widget.onTogglePlayPause,
                    child: Stack(
                      children: [
                        Center(
                          child: Video(
                            controller: widget.ctrl.video,
                            controls: null,
                          ),
                        ),
                        if (_osdText != null)
                          Positioned(
                            right: 16,
                            top: 16,
                            child: FadeTransition(
                              opacity: _fadeController,
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
