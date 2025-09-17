// lib/widgets/controls_bar.dart
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
    final border = Colors.white.withValues(alpha: .08);
    final fgWeak = Colors.white.withValues(alpha: .78);
    final fg = Colors.white.withValues(alpha: .92);
    final accent = theme.colorScheme.secondary;

    Widget sIcon(IconData icon, {VoidCallback? onTap, String? tip}) {
      final btn = InkResponse(
        onTap: onTap,
        radius: 14,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon, size: 14, color: fg),
        ),
      );
      return tip == null ? btn : Tooltip(message: tip, child: btn);
    }

    final playPill = InkWell(
      onTap: onPlayPause,
      customBorder: const CircleBorder(),
      child: Ink(
        height: 26,
        width: 26,
        decoration: ShapeDecoration(color: accent, shape: const CircleBorder()),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 16,
          color: Colors.black,
        ),
      ),
    );

    final volPct = '${(volume * 100).round()}%';
    final vol = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        sIcon(
          Icons.remove_rounded,
          onTap: () => onVolume((volume - 0.05).clamp(0.0, 1.0)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            volPct,
            style: TextStyle(
              color: fgWeak,
              fontSize: 10.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        sIcon(
          Icons.add_rounded,
          onTap: () => onVolume((volume + 0.05).clamp(0.0, 1.0)),
        ),
      ],
    );

    final speeds = const [0.75, 1.0, 1.25, 1.5, 2.0];
    final speedBox = Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<double>(
        value: speed,
        onChanged: (v) => v == null ? null : onSpeed(v),
        isDense: true,
        dropdownColor: const Color(0xFF121829),
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.expand_more_rounded, size: 12, color: fgWeak),
        style: TextStyle(color: fg, fontSize: 10.5),
        items: [
          for (final s in speeds)
            DropdownMenuItem(value: s, child: Text('${s}x')),
        ],
      ),
    );

    final rightCluster = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        speedBox,
        const SizedBox(width: 6),
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              sIcon(Icons.closed_caption_rounded, onTap: onToggleSubtitles),
              Container(width: 1, height: 14, color: border),
              sIcon(Icons.fit_screen_rounded, onTap: onFullscreen),
            ],
          ),
        ),
      ],
    );

    return Container(
      height: 36, // 🔻 ultra-slim
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .025),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Row(
            children: [
              sIcon(Icons.skip_previous_rounded, onTap: onPrev),
              const SizedBox(width: 2),
              playPill,
              const SizedBox(width: 2),
              sIcon(Icons.skip_next_rounded, onTap: onNext),
            ],
          ),
          Expanded(child: Center(child: vol)),
          rightCluster,
        ],
      ),
    );
  }
}
