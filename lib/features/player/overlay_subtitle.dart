import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'player_controller.dart';

/// Subtitle choice model
enum SubtitleChoiceType { auto, off, embedded, externalSrt }

class SubtitleChoice {
  final SubtitleChoiceType type;
  final int? index;
  const SubtitleChoice._(this.type, [this.index]);
  const SubtitleChoice.auto() : this._(SubtitleChoiceType.auto);
  const SubtitleChoice.off() : this._(SubtitleChoiceType.off);
  const SubtitleChoice.externalSrt() : this._(SubtitleChoiceType.externalSrt);
  const SubtitleChoice.embedded(int index)
    : this._(SubtitleChoiceType.embedded, index);
}

/// Opens a drop-up menu to select subtitle options.
/// Returns true if a choice was applied.
Future<bool> showSubtitlesMenu(
  BuildContext context,
  PlayerController ctrl,
) async {
  final choice = await showModalBottomSheet<SubtitleChoice>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      return StreamBuilder<Tracks>(
        stream: ctrl.tracksStream,
        initialData: ctrl.tracks,
        builder: (ctx, snap) {
          final tracks = snap.data?.subtitle ?? const <SubtitleTrack>[];
          return SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(title: Text('Subtitles'), dense: true),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Auto'),
                  subtitle: const Text('Select default track'),
                  onTap: () => Navigator.pop(ctx, const SubtitleChoice.auto()),
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Off'),
                  onTap: () => Navigator.pop(ctx, const SubtitleChoice.off()),
                ),
                if (tracks.isNotEmpty) const Divider(),
                for (var i = 0; i < tracks.length; i++)
                  ListTile(
                    leading: const Icon(Icons.subtitles_outlined),
                    title: Text(
                      tracks[i].title?.isNotEmpty == true
                          ? tracks[i].title!
                          : 'Track ${i + 1}',
                    ),
                    subtitle: Text(
                      (tracks[i].language ?? 'Unknown').toUpperCase(),
                    ),
                    onTap: () => Navigator.pop(ctx, SubtitleChoice.embedded(i)),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('Load external .srt…'),
                  onTap: () =>
                      Navigator.pop(ctx, const SubtitleChoice.externalSrt()),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );

  if (choice == null) return false;

  switch (choice.type) {
    case SubtitleChoiceType.auto:
      await ctrl.player.setSubtitleTrack(SubtitleTrack.auto());
      break;
    case SubtitleChoiceType.off:
      await ctrl.disableSubtitles();
      break;
    case SubtitleChoiceType.embedded:
      await ctrl.setSubtitleByIndex(choice.index!);
      break;
    case SubtitleChoiceType.externalSrt:
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt'],
      );
      final path = picked?.files.single.path;
      if (path == null) return false;
      final text = await File(path).readAsString();
      await ctrl.setExternalSrt(
        text,
        title: path.split(Platform.pathSeparator).last,
      );
      break;
  }
  return true;
}
