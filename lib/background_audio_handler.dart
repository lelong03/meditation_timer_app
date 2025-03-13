import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// A custom background audio handler for meditation music playback.
class MeditationAudioHandler extends BaseAudioHandler {
  final int totalDuration;     // Total meditation duration in seconds.
  final int audioStartOffset;  // When to start audio playback (seconds from start).
  final String assetPath;      // e.g. "assets/audio/album1/track.mp3"
  final AudioPlayer _player = AudioPlayer();
  DateTime? _startTime;
  Timer? _timer;
  bool _audioStarted = false;

  MeditationAudioHandler({
    required this.totalDuration,
    required this.audioStartOffset,
    required this.assetPath,
  });

  /// Start the meditation audio scheduling.
  Future<void> startMeditation() async {
    _startTime = DateTime.now();

    // If offset == 0, start audio immediately.
    if (audioStartOffset == 0 && !_audioStarted) {
      _audioStarted = true;
      try {
        await _player.setAsset(assetPath);
        _player.play();
      } catch (e) {
        print("Error starting audio immediately: $e");
      }
    }

    // Periodically check if it's time to start or stop audio.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final elapsed = DateTime.now().difference(_startTime!).inSeconds;

      // If we haven't started audio yet and we've reached the offset, start now.
      if (!_audioStarted && elapsed >= audioStartOffset) {
        _audioStarted = true;
        try {
          await _player.setAsset(assetPath);
          _player.play();
        } catch (e) {
          print("Error starting audio: $e");
        }
      }

      // End of meditation: stop everything.
      if (elapsed >= totalDuration) {
        timer.cancel();
        await _player.stop();
      }
    });
  }

  @override
  Future<void> pause() async {
    // Pause the audio if it's playing.
    await _player.pause();
    return super.pause();
  }

  @override
  Future<void> play() async {
    // If we haven't yet loaded the asset, do so now.
    if (!_audioStarted) {
      _audioStarted = true;
      await _player.setAsset(assetPath);
    }
    await _player.play();
    return super.play();
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    await _player.stop();
    return super.stop();
  }
}
