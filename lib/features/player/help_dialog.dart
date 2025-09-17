import 'package:flutter/material.dart';

/// A simple help/about dialog that lists all keyboard shortcuts.
class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;

    Widget row(String keys, String action) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                keys,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: .85),
                ),
              ),
            ),
            Expanded(
              child: Text(
                action,
                style: TextStyle(color: fg.withValues(alpha: .9)),
              ),
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      title: const Text('Keyboard Shortcuts'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row('Space', 'Play / Pause'),
            row('F', 'Toggle fullscreen'),
            row('Esc', 'Exit fullscreen'),
            row('T', 'Show current time OSD (2s)'),
            const Divider(),
            row('← / →', 'Seek backward / forward 10s'),
            row('Ctrl + ← / →', 'Seek backward / forward 1 min'),
            row('1–9', 'Seek to 10% … 90% of video'),
            const Divider(),
            row('↑ / ↓', 'Volume up / down'),
            row('S', 'Take screenshot (saved in Screenshots folder)'),
            const Divider(),
            row('N', 'Next item in playlist'),
            row('P', 'Previous item in playlist'),
            const Divider(),
            row('Click right time label', 'Toggle total ↔ remaining'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
