import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'player_controller.dart';

/// Bottom sheet: list audio tracks with language detection
Future<bool> showAudioTrackDialog(
  BuildContext context,
  PlayerController ctrl,
) async {
  final applied = await showModalBottomSheet<bool>(
    context: context,
    builder: (sheetCtx) {
      return StreamBuilder<List<AudioTrack>>(
        stream: ctrl.audioTracksStream,
        initialData: ctrl.audioTracks,
        builder: (_, snap) {
          final tracks = snap.data ?? const <AudioTrack>[];
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Audio Track',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                if (tracks.isEmpty)
                  const Text(
                    'No audio tracks available',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final language = track.language?.isNotEmpty == true 
                          ? track.language! 
                          : 'Unknown';
                      final title = track.title?.isNotEmpty == true 
                          ? track.title! 
                          : 'Audio Track ${index + 1}';
                      
                      return ListTile(
                        leading: Icon(
                          Icons.audiotrack,
                          color: Colors.white70,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Language: $language',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: track.channels != null 
                            ? Text(
                                '${track.channels}ch',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        onTap: () async {
                          await ctrl.setAudioByIndex(index);
                          if (!sheetCtx.mounted) return;
                          Navigator.pop(sheetCtx, true);
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetCtx, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
  return applied ?? false;
}
