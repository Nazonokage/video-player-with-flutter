import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerWidget extends StatelessWidget {
  final VideoController controller;
  const VideoPlayerWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      controls: (state) => const SizedBox.shrink(),
    );
  }
}




