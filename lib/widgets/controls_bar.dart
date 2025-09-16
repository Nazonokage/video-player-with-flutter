import 'package:flutter/material.dart';

class ControlsBar extends StatelessWidget {
  final VoidCallback onPrev;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  final bool isPlaying;

  final double speed;
  final ValueChanged<double> onSpeed;

  final double volume; // 0.0 - 1.0
  final ValueChanged<double> onVolume;

  final VoidCallback onToggleSubtitles;
  final VoidCallback onFullscreen;

  const ControlsBar({
    super.key,
    required this.onPrev,
    required this.onPlayPause,
    required this.onNext,
    required this.isPlaying,
    required this.speed,
    required this.onSpeed,
    required this.volume,
    required this.onVolume,
    required this.onToggleSubtitles,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.secondary;

    Widget iconBtn(IconData icon, {VoidCallback? onTap, EdgeInsets? pad}) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: pad ?? const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
    }

    // Playback controls: ⏮ big play/pause ⏭
    final playback = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconBtn(Icons.skip_previous_rounded, onTap: onPrev),
        const SizedBox(width: 8),
        InkWell(
          onTap: onPlayPause,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        iconBtn(Icons.skip_next_rounded, onTap: onNext),
      ],
    );

    // Volume controls:  -   80%   +
    final volPercent = '${(volume * 100).round()}%';
    final vol = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onVolume((volume - 0.05).clamp(0.0, 1.0)),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(6.0),
            child: Icon(Icons.remove_rounded, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          volPercent,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => onVolume((volume + 0.05).clamp(0.0, 1.0)),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(6.0),
            child: Icon(Icons.add_rounded, size: 22),
          ),
        ),
      ],
    );

    // Speed | CC | Fullscreen
    final speeds = const [0.5, 1.0, 1.5, 2.0];
    final extras = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<double>(
            value: speed,
            onChanged: (v) {
              if (v != null) onSpeed(v);
            },
            dropdownColor: const Color(0xFF1a1a2e),
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: Colors.white),
            items: [
              for (final s in speeds)
                DropdownMenuItem(value: s, child: Text('${s}x')),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onToggleSubtitles,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.closed_caption,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: onFullscreen,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.fit_screen_rounded,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [playback, vol, extras],
      ),
    );
  }
}
