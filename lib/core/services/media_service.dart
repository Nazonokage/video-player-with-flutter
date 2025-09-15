import 'package:media_kit/media_kit.dart';

class MediaService {
  late final Player player;

  Future<void> initialize() async {
    player = Player();
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}




