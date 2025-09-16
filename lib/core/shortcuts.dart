import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class SeekShortIntent extends Intent {
  final Duration delta;
  const SeekShortIntent(this.delta);
}

class SeekLongIntent extends Intent {
  final Duration delta;
  const SeekLongIntent(this.delta);
}

class TogglePlayIntent extends Intent {
  const TogglePlayIntent();
}

class FullscreenIntent extends Intent {
  const FullscreenIntent();
}

class VolumeIntent extends Intent {
  final double delta; // +/- 0.05
  const VolumeIntent(this.delta);
}

class ToggleTimeOsdIntent extends Intent {
  const ToggleTimeOsdIntent();
}

/// Default key map used by Shortcuts (kept for declarative handling).
final Map<LogicalKeySet, Intent> defaultKeyMap = {
  LogicalKeySet(LogicalKeyboardKey.space): const TogglePlayIntent(),
  LogicalKeySet(LogicalKeyboardKey.keyF): const FullscreenIntent(),
  LogicalKeySet(LogicalKeyboardKey.escape): const FullscreenIntent(),
  LogicalKeySet(LogicalKeyboardKey.keyT): const ToggleTimeOsdIntent(),
  LogicalKeySet(LogicalKeyboardKey.arrowLeft): const SeekShortIntent(
    Duration(seconds: -10),
  ),
  LogicalKeySet(LogicalKeyboardKey.arrowRight): const SeekShortIntent(
    Duration(seconds: 10),
  ),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):
      const SeekLongIntent(Duration(minutes: -1)),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):
      const SeekLongIntent(Duration(minutes: 1)),
  LogicalKeySet(LogicalKeyboardKey.arrowUp): const VolumeIntent(0.05),
  LogicalKeySet(LogicalKeyboardKey.arrowDown): const VolumeIntent(-0.05),
};

/// Single source of truth for RAW key → Intent mapping (used by KeyboardListener).
/// This avoids duplicating the logic in every screen and handles Ctrl combos.
Intent? mapRawKeyToIntent(KeyEvent event) {
  if (event is! KeyDownEvent) return null;

  final k = event.logicalKey;
  final pressed = HardwareKeyboard.instance.logicalKeysPressed;
  final ctrlDown =
      pressed.contains(LogicalKeyboardKey.controlLeft) ||
      pressed.contains(LogicalKeyboardKey.controlRight);

  if (k == LogicalKeyboardKey.space) {
    return const TogglePlayIntent();
  }
  if (k == LogicalKeyboardKey.keyF || k == LogicalKeyboardKey.escape) {
    return const FullscreenIntent();
  }
  if (k == LogicalKeyboardKey.keyT) {
    return const ToggleTimeOsdIntent();
  }
  if (ctrlDown && k == LogicalKeyboardKey.arrowLeft) {
    return const SeekLongIntent(Duration(minutes: -1));
  }
  if (ctrlDown && k == LogicalKeyboardKey.arrowRight) {
    return const SeekLongIntent(Duration(minutes: 1));
  }
  if (k == LogicalKeyboardKey.arrowLeft) {
    return const SeekShortIntent(Duration(seconds: -10));
  }
  if (k == LogicalKeyboardKey.arrowRight) {
    return const SeekShortIntent(Duration(seconds: 10));
  }
  if (k == LogicalKeyboardKey.arrowUp) {
    return const VolumeIntent(0.05);
  }
  if (k == LogicalKeyboardKey.arrowDown) {
    return const VolumeIntent(-0.05);
  }
  return null;
}
