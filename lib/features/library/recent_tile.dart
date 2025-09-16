import 'package:flutter/material.dart';
import '../../core/path_utils.dart';
import '../../core/app_state.dart';

class RecentTile extends StatelessWidget {
  final RecentItem item;
  final VoidCallback onResume;
  final VoidCallback onClear;

  const RecentTile({
    super.key,
    required this.item,
    required this.onResume,
    required this.onClear,
  });

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final name = filenameOf(item.path);
    final progress = item.progress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // file name + position
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(item.lastPositionMs)} / ${_fmt(item.durationMs)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    color: const Color(0xFF00d4ff),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(onPressed: onResume, child: const Text('Resume')),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Remove from Recents',
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded),
          ),
        ],
      ),
    );
  }
}
