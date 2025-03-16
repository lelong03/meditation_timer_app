import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// A custom background audio handler for meditation music playback.
class MeditationAudioHandler extends BaseAudioHandler {
  // The fields you had before
  int totalDuration;     // in seconds
  int audioStartOffset;  // in seconds
  String assetPath;      // e.g. "assets/audio/album1/track.mp3"

  final AudioPlayer _player = AudioPlayer();
  DateTime? _startTime;
  Timer? _timer;
  bool _audioStarted = false;

  MeditationAudioHandler({
    required this.totalDuration,
    required this.audioStartOffset,
    required this.assetPath,
  });

  /// A new method to update fields for each new session, then start scheduling.
  Future<void> startNewSession({
    required int totalDuration,
    required int audioStartOffset,
    required String assetPath,
  }) async {
    // 1) Stop any previous session so we start fresh
    await stop();

    // 2) Update fields
    this.totalDuration = totalDuration;
    this.audioStartOffset = audioStartOffset;
    this.assetPath = assetPath;
    _audioStarted = false;

    // 3) Call the existing logic to schedule playback
    await startMeditation();
  }

  /// Start the meditation audio scheduling (your existing code).
  Future<void> startMeditation() async {
    _startTime = DateTime.now();

    // If offset == 0, start audio immediately.
    if (audioStartOffset == 0 && !_audioStarted && assetPath.isNotEmpty) {
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
    await _player.pause();
    return super.pause();
  }

  @override
  Future<void> play() async {
    if (!_audioStarted && assetPath.isNotEmpty) {
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
