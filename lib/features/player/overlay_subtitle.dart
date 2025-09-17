import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';

import 'player_controller.dart';

/// Bottom sheet: list internal subs, disable, or load external .srt
Future<bool> showSubtitleMenu(
  BuildContext context,
  PlayerController ctrl,
) async {
  final applied = await showModalBottomSheet<bool>(
    context: context,
    builder: (sheetCtx) {
      return StreamBuilder<List<SubtitleTrack>>(
        stream: ctrl.subtitleTracksStream,
        initialData: ctrl.subtitleTracks,
        builder: (_, snap) {
          final tracks = snap.data ?? const <SubtitleTrack>[];
          return ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Disable subtitles'),
                onTap: () async {
                  await ctrl.disableSubtitles();
                  if (!sheetCtx.mounted) return;
                  Navigator.pop(sheetCtx, true);
                },
              ),
              for (int i = 0; i < tracks.length; i++)
                ListTile(
                  title: Text(tracks[i].title ?? 'Subtitle ${i + 1}'),
                  onTap: () async {
                    await ctrl.setSubtitleByIndex(i);
                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx, true);
                  },
                ),
              ListTile(
                title: const Text('Load external .srt'),
                onTap: () async {
                  final res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['srt'],
                  );
                  if (res != null && res.files.single.path != null) {
                    await ctrl.setExternalSrt(res.files.single.path!);
                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx, true);
                  } else {
                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx, false);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
  return applied ?? false;
}
