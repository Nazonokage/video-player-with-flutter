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
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = Colors.white.withAlpha(20);
    final fgWeak = Colors.white.withAlpha(200);
    final fg = Colors.white;
    final accent = theme.colorScheme.secondary;

    Widget sIcon(
      IconData icon, {
      VoidCallback? onTap,
      String? tip,
      double size = 16,
    }) {
      return Tooltip(
        message: tip ?? '',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 150),
            tween: Tween<double>(begin: 1.0, end: 1.0),
            builder: (context, double scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: onTap,
              child: MouseRegion(
                onEnter: (event) {},
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: size, color: fg),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final playPill = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 100),
        tween: Tween<double>(begin: 1.0, end: 1.0),
        builder: (context, double scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: GestureDetector(
          onTap: onPlayPause,
          child: Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withAlpha(100),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                key: ValueKey<bool>(isPlaying),
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
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
          tip: 'Decrease volume',
          size: 18,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            volPct,
            style: TextStyle(
              color: fgWeak,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        sIcon(
          Icons.add_rounded,
          onTap: () => onVolume((volume + 0.05).clamp(0.0, 1.0)),
          tip: 'Increase volume',
          size: 18,
        ),
      ],
    );

    final speeds = const [0.75, 1.0, 1.25, 1.5, 2.0];
    final speedBox = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
            value: speed,
            onChanged: (v) => v == null ? null : onSpeed(v),
            isDense: true,
            dropdownColor: const Color(0xFF121829),
            icon: Icon(Icons.expand_more_rounded, size: 16, color: fgWeak),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            items: [
              for (final s in speeds)
                DropdownMenuItem(
                  value: s,
                  child: Text('${s}x', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ),
      ),
    );

    final rightCluster = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(message: 'Playback speed', child: speedBox),
        const SizedBox(width: 8),
        Container(
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              sIcon(
                Icons.fit_screen_rounded,
                onTap: onFullscreen,
                tip: 'Fullscreen',
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              sIcon(
                Icons.skip_previous_rounded,
                onTap: onPrev,
                tip: 'Previous',
              ),
              const SizedBox(width: 4),
              playPill,
              const SizedBox(width: 4),
              sIcon(Icons.skip_next_rounded, onTap: onNext, tip: 'Next'),
            ],
          ),
          Expanded(child: Center(child: vol)),
          rightCluster,
        ],
      ),
    );
  }
}
