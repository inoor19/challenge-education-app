import 'package:audioplayers/audioplayers.dart';

class FeedbackEffectsService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playCorrect({required bool muted}) async {
    if (muted) return;
    await _play('sounds/correct.wav');
  }

  Future<void> playWrong({required bool muted}) async {
    if (muted) return;
    await _play('sounds/wrong.wav');
  }

  Future<void> playTimerTick({required bool muted}) async {
    if (muted) return;
    await _play('sounds/timer_tick.wav');
  }

  Future<void> _play(String assetPath) async {
    await _player.stop();
    await _player.play(AssetSource(assetPath));
  }

  Future<void> dispose() => _player.dispose();
}
