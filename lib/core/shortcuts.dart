// lib/core/shortcuts.dart
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

// Extra / new intents
class ScreenshotIntent extends Intent {
  const ScreenshotIntent();
}

class NextItemIntent extends Intent {
  const NextItemIntent();
}

class PrevItemIntent extends Intent {
  const PrevItemIntent();
}

class NumberSeekIntent extends Intent {
  final double fraction; // 0.1..0.9
  const NumberSeekIntent(this.fraction);
}

// NEW: Help intent for F1 key
class HelpIntent extends Intent {
  const HelpIntent();
}

final Map<LogicalKeySet, Intent> defaultKeyMap = {
  // Space = play/pause
  LogicalKeySet(LogicalKeyboardKey.space): const TogglePlayIntent(),
  // F = fullscreen
  LogicalKeySet(LogicalKeyboardKey.keyF): const FullscreenIntent(),
  // T = toggle time OSD
  LogicalKeySet(LogicalKeyboardKey.keyT): const ToggleTimeOsdIntent(),
  // Arrow left/right = ±10s
  LogicalKeySet(LogicalKeyboardKey.arrowLeft): const SeekShortIntent(
    Duration(seconds: -10),
  ),
  LogicalKeySet(LogicalKeyboardKey.arrowRight): const SeekShortIntent(
    Duration(seconds: 10),
  ),
  // Ctrl + Arrow left/right = ±60s
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):
      const SeekLongIntent(Duration(minutes: -1)),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):
      const SeekLongIntent(Duration(minutes: 1)),
  // Arrow up/down = volume
  LogicalKeySet(LogicalKeyboardKey.arrowUp): const VolumeIntent(0.05),
  LogicalKeySet(LogicalKeyboardKey.arrowDown): const VolumeIntent(-0.05),

  // New: S / N / P / digits 1-9
  LogicalKeySet(LogicalKeyboardKey.keyS): const ScreenshotIntent(),
  LogicalKeySet(LogicalKeyboardKey.keyN): const NextItemIntent(),
  LogicalKeySet(LogicalKeyboardKey.keyP): const PrevItemIntent(),

  // NEW: F1 for help
  LogicalKeySet(LogicalKeyboardKey.f1): const HelpIntent(),

  LogicalKeySet(LogicalKeyboardKey.digit1): const NumberSeekIntent(0.10),
  LogicalKeySet(LogicalKeyboardKey.digit2): const NumberSeekIntent(0.20),
  LogicalKeySet(LogicalKeyboardKey.digit3): const NumberSeekIntent(0.30),
  LogicalKeySet(LogicalKeyboardKey.digit4): const NumberSeekIntent(0.40),
  LogicalKeySet(LogicalKeyboardKey.digit5): const NumberSeekIntent(0.50),
  LogicalKeySet(LogicalKeyboardKey.digit6): const NumberSeekIntent(0.60),
  LogicalKeySet(LogicalKeyboardKey.digit7): const NumberSeekIntent(0.70),
  LogicalKeySet(LogicalKeyboardKey.digit8): const NumberSeekIntent(0.80),
  LogicalKeySet(LogicalKeyboardKey.digit9): const NumberSeekIntent(0.90),
};

/// Map a keyboard event (KeyDownEvent) to an Intent from [defaultKeyMap].
Intent? mapRawKeyToIntent(KeyEvent event) {
  if (event is! KeyDownEvent) return null;

  final pressed = <LogicalKeyboardKey>{};
  if (HardwareKeyboard.instance.isControlPressed) {
    pressed.add(LogicalKeyboardKey.control);
  }
  if (HardwareKeyboard.instance.isAltPressed) {
    pressed.add(LogicalKeyboardKey.alt);
  }
  if (HardwareKeyboard.instance.isMetaPressed) {
    pressed.add(LogicalKeyboardKey.meta);
  }
  if (HardwareKeyboard.instance.isShiftPressed) {
    pressed.add(LogicalKeyboardKey.shift);
  }
  pressed.add(event.logicalKey);

  for (final entry in defaultKeyMap.entries) {
    final combo = entry.key.keys.toSet();
    if (pressed.length == combo.length && pressed.containsAll(combo)) {
      return entry.value;
    }
  }
  return null;
}
