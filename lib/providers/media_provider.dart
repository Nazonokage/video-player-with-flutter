import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaProvider extends ChangeNotifier {
  late final Player _player;
  VideoController? _videoController;
  bool _initialized = false;

  Player get player => _player;
  VideoController? get videoController => _videoController;
  bool get isInitialized => _initialized;

  MediaProvider() {
    _player = Player();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _videoController = VideoController(_player);
    _initialized = true;
    notifyListeners();
  }

  Future<void> openMediaUri(String uri) async {
    await initialize();
    await _player.open(Media(uri));
    notifyListeners();
  }

  // Streams for UI bindings
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;
  Stream<bool> get playingStream => _player.stream.playing;

  // Controls
  Future<void> togglePlayPause() async {
    if (_player.state.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekToFraction(double fraction) async {
    final total = _player.state.duration;
    if (total.inMilliseconds <= 0) return;
    final doubleMs = total.inMilliseconds * fraction;
    final int targetMs = (doubleMs.clamp(0, total.inMilliseconds)).toInt();
    await _player.seek(Duration(milliseconds: targetMs));
  }

  Future<void> seekBy(Duration offset) async {
    final pos = _player.state.position;
    final total = _player.state.duration;
    final next = pos + offset;
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > total ? total : next);
    await _player.seek(clamped);
  }

  Future<void> setVolumePercent(int volume) async {
    final v = volume.clamp(0, 100).toDouble();
    await _player.setVolume(v);
    notifyListeners();
  }

  Future<void> changeVolumeBy(int delta) async {
    final current = _player.state.volume;
    final next = (current + delta).clamp(0, 100).toDouble();
    await _player.setVolume(next);
    notifyListeners();
  }

  Future<void> setRate(double rate) async {
    await _player.setRate(rate);
    notifyListeners();
  }

  double get volumePercent => _player.state.volume;
  double get rate => _player.state.rate;

  Future<void> disposeAsync() async {
    await _player.dispose();
  }
}




