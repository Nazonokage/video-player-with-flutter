import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
// FontFeature is available via dart:ui but also re-exported by Flutter; no extra import needed.
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../widgets/player/video_player_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showPlaylist = false;
  final FocusNode _focusNode = FocusNode();
  bool _showVolumeOsd = false;
  Timer? _osdTimer;
  int _osdVolume = 0;

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    if (hh > 0) {
      final hhStr = hh.toString().padLeft(2, '0');
      return '$hhStr:$mm:$ss';
    }
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _openFullscreen(BuildContext context) {
    final media = context.read<MediaProvider>();
    if (media.videoController == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (ctx, a1, a2) => _FullscreenVideoPage(controller: media.videoController!),
        transitionsBuilder: (ctx, a1, a2, child) => FadeTransition(opacity: a1, child: child),
      ),
    );
  }

  void _showVolume(int vol) {
    setState(() {
      _osdVolume = vol;
      _showVolumeOsd = true;
    });
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _showVolumeOsd = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (event) {
              if (event is! KeyDownEvent) return;
              final isCtrl = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                  HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);
              final media = context.read<MediaProvider>();
              if (event.logicalKey == LogicalKeyboardKey.keyT) {
                final pos = media.player.state.position;
                final text = _fmt(pos);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Current time: $text'), duration: const Duration(seconds: 1)),
                );
              } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
                _openFullscreen(context);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                media.seekBy(Duration(seconds: isCtrl ? -60 : -10));
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                media.seekBy(Duration(seconds: isCtrl ? 60 : 10));
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                media.changeVolumeBy(5);
                _showVolume(media.volumePercent.toInt());
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                media.changeVolumeBy(-5);
                _showVolume(media.volumePercent.toInt());
              }
            },
            child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xF20A0F1E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 36, offset: Offset(0, 12)),
                  ],
                ),
                child: Column(
                  children: [
                    _TopBar(
                      onOpenFile: () async {
              final media = context.read<MediaProvider>();
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: const [
                  'mp4','avi','mkv','mov','wmv','flv','mp3','flac','wav','aac','ogg'
                ],
              );
              final path = result?.files.single.path;
              if (path == null) return;
              await media.openMediaUri(path);
            },
                      onTogglePlaylist: () => setState(() => _showPlaylist = true),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Consumer<MediaProvider>(
                          builder: (context, media, _) {
                            if (!media.isInitialized || media.videoController == null) {
                              return Text(
                                'Open a media file to play.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFA0A0B0)),
                              );
                            }
                            return AspectRatio(
                              aspectRatio: 16 / 9,
                              child: VideoPlayerWidget(controller: media.videoController!),
                            );
                          },
                        ),
                      ),
                    ),
                    const _ControlsArea(),
                  ],
                ),
              ),
              if (_showPlaylist) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showPlaylist = false),
                    child: Container(
                      color: const Color(0xB30A0F1E),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xF20A0F1E),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 20)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Playlist', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 18, fontWeight: FontWeight.w500)),
                              ),
                              InkWell(
                                onTap: () => setState(() => _showPlaylist = false),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close, color: Color(0xFFA0A0B0)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0x33000000),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ListView(
                              shrinkWrap: true,
                              children: const [
                                _PlaylistItem(title: 'Ambient Dreams - Soundscape'),
                                _PlaylistItem(title: 'Chill Vibes - LoFi Beats'),
                                _PlaylistItem(title: 'Focus Time - Deep Work'),
                                _PlaylistItem(title: 'Relaxation - Ambient Piano'),
                                _PlaylistItem(title: 'Energy Boost - Upbeat Mix'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search media...',
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0x33000000),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
              ,
              if (_showVolumeOsd)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$_osdVolume%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

class _TopBar extends StatelessWidget {
  final VoidCallback onTogglePlaylist;
  final Future<void> Function() onOpenFile;
  const _TopBar({required this.onTogglePlaylist, required this.onOpenFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        children: [
          const Text('CleanPlayer', style: TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.w600)),
          const Spacer(),
          Row(
            children: [
              _MenuItem(label: 'File', onTap: onOpenFile),
              const SizedBox(width: 20),
              const _MenuItem(label: 'Playback'),
              const SizedBox(width: 20),
              _MenuItem(label: 'Playlist', onTap: onTogglePlaylist),
              const SizedBox(width: 20),
              const _MenuItem(label: 'Help'),
            ],
          ),
          const SizedBox(width: 16),
          const _WindowControls(),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _MenuItem({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 0.85,
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _WindowControls extends StatelessWidget {
  const _WindowControls();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color, {String? label}) => Container(
      width: 14, height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(label ?? '', style: const TextStyle(fontSize: 9, color: Colors.transparent)),
    );
    return Row(children: [
      dot(const Color(0xFFFFBD44), label: '-'), const SizedBox(width: 10),
      dot(const Color(0xFF00CA4E), label: '⬜'), const SizedBox(width: 10),
      dot(const Color(0xFFFF605C), label: '✕'),
    ]);
  }
}

class _ControlsArea extends StatelessWidget {
  const _ControlsArea();

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    if (hh > 0) {
      final hhStr = hh.toString().padLeft(2, '0');
      return '$hhStr:$mm:$ss';
    }
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final media = context.watch<MediaProvider>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Seek bar + times
          StreamBuilder<Duration>(
            stream: media.positionStream,
            initialData: Duration.zero,
            builder: (context, posSnap) {
              return StreamBuilder<Duration>(
                stream: media.durationStream,
                initialData: Duration.zero,
                builder: (context, durSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final dur = durSnap.data ?? Duration.zero;
                  final fraction = dur.inMilliseconds == 0
                      ? 0.0
                      : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: fraction,
                              onChanged: (v) => media.seekToFraction(v),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(pos), style: const TextStyle(color: Color(0xFFA0A0B0), fontFeatures: [FontFeature.tabularFigures()])),
                          Text(_fmt(dur), style: const TextStyle(color: Color(0xFFA0A0B0), fontFeatures: [FontFeature.tabularFigures()])),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                _IconBtn(icon: Icons.skip_previous, onTap: () => media.seekBy(const Duration(seconds: -10))),
                const SizedBox(width: 8),
                StreamBuilder<bool>(
                  stream: media.playingStream,
                  initialData: media.player.state.playing,
                  builder: (context, snap) {
                    final playing = snap.data ?? false;
                    return _PrimaryCircleBtn(
                      icon: playing ? Icons.pause : Icons.play_arrow,
                      onTap: media.togglePlayPause,
                    );
                  },
                ),
                const SizedBox(width: 8),
                _IconBtn(icon: Icons.skip_next, onTap: () => media.seekBy(const Duration(seconds: 10))),
              ]),
              Row(children: [
                _IconBtn(icon: Icons.remove, onTap: () => media.changeVolumeBy(-5)),
                const SizedBox(width: 6),
                Text('${media.volumePercent.toInt()}%'),
                const SizedBox(width: 6),
                _IconBtn(icon: Icons.add, onTap: () => media.changeVolumeBy(5)),
              ]),
              Row(children: [
                DropdownButton<double>(
                  value: media.rate.clamp(0.25, 4.0),
                  underline: const SizedBox.shrink(),
                  items: const [0.5, 1.0, 1.5, 2.0]
                      .map((e) => DropdownMenuItem(value: e, child: Text('${e}x')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) media.setRate(v);
                  },
                ),
                const SizedBox(width: 8),
                _IconBtn(icon: Icons.closed_caption),
                const SizedBox(width: 8),
                _IconBtn(
                  icon: Icons.fullscreen,
                  onTap: () {
                    final media = context.read<MediaProvider>();
                    if (media.videoController == null) return;
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (ctx, a1, a2) => Scaffold(
                          backgroundColor: Colors.black,
                          body: Stack(
                            children: [
                              Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayerWidget(controller: media.videoController!),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                left: 16,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        transitionsBuilder: (ctx, a1, a2, child) => FadeTransition(opacity: a1, child: child),
            ),
          );
        },
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

class _PrimaryCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PrimaryCircleBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF00D4FF),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF0A0F1E)),
      ),
    );
  }
}

class _PlaylistItem extends StatelessWidget {
  final String title;
  const _PlaylistItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(title),
      ),
    );
  }
}



class _FullscreenVideoPage extends StatefulWidget {
  final VideoController controller;
  const _FullscreenVideoPage({required this.controller});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  final FocusNode _fsFocus = FocusNode();

  @override
  void dispose() {
    _fsFocus.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    if (hh > 0) {
      final hhStr = hh.toString().padLeft(2, '0');
      return '$hhStr:$mm:$ss';
    }
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final media = context.read<MediaProvider>();
    return KeyboardListener(
      focusNode: _fsFocus,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final isCtrl = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          media.seekBy(Duration(seconds: isCtrl ? -60 : -10));
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          media.seekBy(Duration(seconds: isCtrl ? 60 : 10));
        } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: VideoPlayerWidget(controller: widget.controller),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Timeline at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<Duration>(
                  stream: media.positionStream,
                  initialData: Duration.zero,
                  builder: (context, posSnap) {
                    return StreamBuilder<Duration>(
                      stream: media.durationStream,
                      initialData: Duration.zero,
                      builder: (context, durSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = durSnap.data ?? Duration.zero;
                        final fraction = dur.inMilliseconds == 0
                            ? 0.0
                            : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Slider(
                              value: fraction,
                              onChanged: (v) => media.seekToFraction(v),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(pos), style: const TextStyle(color: Colors.white70)),
                                Text(_fmt(dur), style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
