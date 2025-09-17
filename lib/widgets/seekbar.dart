import 'package:flutter/material.dart';

class SeekBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<double> onChanged;

  /// NEW: when true, right label shows remaining time ("-mm:ss"),
  /// otherwise shows total duration.
  final bool showRemaining;

  /// NEW: toggle callback when right time text is tapped.
  final VoidCallback onToggleTimeMode;

  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onChanged,
    required this.showRemaining,
    required this.onToggleTimeMode,
  });

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: .85);
    final accent = Theme.of(context).colorScheme.secondary;

    final value = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    String fmt(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      final h = d.inHours;
      return h > 0 ? '$h:$m:$s' : '$m:$s';
    }

    final rightText = showRemaining
        ? '-${fmt(duration - position)}'
        : fmt(duration);

    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            fmt(position),
            textAlign: TextAlign.center,
            style: TextStyle(color: fg, fontSize: 11),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: .25),
              thumbColor: accent,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 52,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onToggleTimeMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                rightText,
                textAlign: TextAlign.center,
                style: TextStyle(color: fg, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
