import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onOpenPlaylist;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenSubtitles;
  final VoidCallback onVolumeEnhancement;
  final VoidCallback onOpenAudioTracks;
  final VoidCallback onOpenSettings;
  final VoidCallback? onLogoClick;
  final String? fileName;

  const TopBar({
    super.key,
    required this.onOpenPlaylist,
    required this.onOpenHelp,
    required this.onOpenSubtitles,
    required this.onVolumeEnhancement,
    required this.onOpenAudioTracks,
    required this.onOpenSettings,
    this.onLogoClick,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final sep = SizedBox(width: 20);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.80),
        border: const Border(
          bottom: BorderSide(color: Color.fromARGB(26, 255, 255, 255)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLogoClick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: onLogoClick != null
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: const Text(
                'CleanPlayer',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: .3,
                ),
              ),
            ),
          ),
          if (fileName != null) ...[
            const SizedBox(width: 16),
            Text(
              fileName!.length > 20
                  ? '${fileName!.substring(0, 25)}...'
                  : fileName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          _MenuBtn('Playlist', onTap: onOpenPlaylist),
          sep,
          _MenuBtn('Subtitles', onTap: onOpenSubtitles),
          sep,
          _MenuBtn('Audio Tracks', onTap: onOpenAudioTracks),
          sep,
          _MenuBtn('Audio', onTap: onVolumeEnhancement),
          sep,
          _MenuBtn('Settings', onTap: onOpenSettings),
          sep,
          _MenuBtn('Help', onTap: onOpenHelp),
          const SizedBox(width: 16),

          // window “traffic lights” (cosmetic)
        ],
      ),
    );
  }
}

class _MenuBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuBtn(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: .85),
          ),
        ),
      ),
    );
  }
}
