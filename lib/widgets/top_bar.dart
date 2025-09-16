import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onOpenPlaylist;
  final VoidCallback onOpenSubtitles;
  final VoidCallback onOpenHelp;

  const TopBar({
    super.key,
    required this.onOpenPlaylist,
    required this.onOpenSubtitles,
    required this.onOpenHelp,
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
          const Text(
            'CleanPlayer',
            style: TextStyle(
              color: Color(0xFF00D4FF),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: .3,
            ),
          ),
          const Spacer(),
          _MenuBtn('Playlist', onTap: onOpenPlaylist),
          sep,
          _MenuBtn('Subtitles', onTap: onOpenSubtitles),
          sep,
          _MenuBtn('Help', onTap: onOpenHelp),
          const SizedBox(width: 16),
          // window “traffic lights” (cosmetic)
          Row(
            children: const [
              _Dot(color: Color(0xFFFFBD44)),
              SizedBox(width: 6),
              _Dot(color: Color(0xFF00CA4E)),
              SizedBox(width: 6),
              _Dot(color: Color(0xFFFF605C)),
            ],
          ),
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

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
