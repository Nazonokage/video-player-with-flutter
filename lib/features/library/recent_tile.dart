import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/app_state.dart';

class RecentTile extends StatelessWidget {
  final RecentItem item;
  final VoidCallback? onTap;

  /// If provided, the tile becomes swipe-to-dismiss (→ calls onDismissed).
  final VoidCallback? onDismissed;

  const RecentTile({
    super.key,
    required this.item,
    this.onTap,
    this.onDismissed,
  });

  String _fmtTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final name = p.basename(item.path);
    final pos = Duration(milliseconds: item.lastPositionMs);
    final dur = Duration(milliseconds: item.durationMs);

    final tile = Material(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        title: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          'Resume at ${_fmtTime(pos)} • Total ${_fmtTime(dur)}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white),
      ),
    );

    // If onDismissed is not provided, render a plain tile (no swipe).
    if (onDismissed == null) {
      return Padding(padding: const EdgeInsets.only(bottom: 8), child: tile);
    }

    // Swipe-to-dismiss (slide left background).
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(item.path),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed!.call(),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: tile,
      ),
    );
  }
}
