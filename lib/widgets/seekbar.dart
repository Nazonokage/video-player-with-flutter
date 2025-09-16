import 'package:flutter/material.dart';

class SeekBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<double> onChanged; // 0..1

  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double max = duration.inMilliseconds.toDouble() <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final double value = position.inMilliseconds
        .clamp(0, max.toInt())
        .toDouble();

    String fmt(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      final s = d.inSeconds % 60;
      return [
        if (h > 0) h.toString().padLeft(2, '0'),
        m.toString().padLeft(2, '0'),
        s.toString().padLeft(2, '0'),
      ].join(':');
    }

    return Column(
      children: [
        Slider(
          value: value,
          min: 0.0,
          max: max,
          onChanged: (v) => onChanged(v / max),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt(Duration(milliseconds: value.toInt()))),
              Text(fmt(duration)),
            ],
          ),
        ),
      ],
    );
  }
}
