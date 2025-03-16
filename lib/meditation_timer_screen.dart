import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'background_audio_handler.dart';
import 'database.dart';
import 'package:audio_service/audio_service.dart';
import 'main.dart'; // import so we can access globalAudioHandler

class MeditationTimerScreen extends StatefulWidget {
  final int durationInMinutes;
  final int? albumId; // Null => "Not use"
  final bool isEnglish;

  const MeditationTimerScreen({
    Key? key,
    required this.durationInMinutes,
    required this.albumId,
    required this.isEnglish,
  }) : super(key: key);

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen> {
  late int totalDuration; // total in seconds
  late int remainingSeconds;
  DateTime? _startTime;
  Timer? _timer;
  bool isPaused = false;
  bool isRunning = false;

  // We'll reuse the global audio handler, not create a new one.
  AudioHandler get _audioHandler => globalAudioHandler;

  String chosenTrackPath = "";
  int chosenTrackDuration = 0; // in seconds

  @override
  void initState() {
    super.initState();
    totalDuration = widget.durationInMinutes * 60;
    remainingSeconds = totalDuration;

    // If user chose an album, load a random track. Otherwise, no music.
    if (widget.albumId != null) {
      _initTrackAndStart();
    } else {
      _startMeditation();
    }
  }

  /// Fetch a random track from the chosen album, then start the meditation.
  Future<void> _initTrackAndStart() async {
    final tracks = await AppDatabase.instance.getTracksForAlbum(widget.albumId!);
    if (tracks.isEmpty) {
      _startMeditation();
      return;
    }

    final random = Random();
    final trackIndex = random.nextInt(tracks.length);
    final track = tracks[trackIndex];

    setState(() {
      chosenTrackPath = track['filePath'] as String;
      chosenTrackDuration = track['duration'] as int;

      if (!chosenTrackPath.startsWith("assets/")) {
        chosenTrackPath = "assets/" + chosenTrackPath;
      }
    });

    _startMeditation();
  }

  void _startMeditation() async {
    print("[DEBUG] _startMeditation() called");

    // 1) Stop old timer if any
    _timer?.cancel();

    // 2) Stop the previous session in the global audio handler
    await _audioHandler.stop();
    // Brief delay to let it tear down
    await Future.delayed(const Duration(milliseconds: 200));

    // 3) Reset state
    setState(() {
      _startTime = DateTime.now();
      isRunning = true;
      isPaused = false;
      remainingSeconds = totalDuration;
    });

    // 4) If a track is chosen, call startNewSession(...) on the global handler
    if (chosenTrackPath.isNotEmpty) {
      int audioStartTime = totalDuration - chosenTrackDuration;
      if (audioStartTime < 0) {
        audioStartTime = 0;
      }
      // This replaces AudioService.init(...)
      await (globalAudioHandler as MeditationAudioHandler).startNewSession(
        totalDuration: totalDuration,
        audioStartOffset: audioStartTime,
        assetPath: chosenTrackPath,
      );
    }

    // 5) Start the UI timer
    print("[DEBUG] Timer tick");
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!isPaused && _startTime != null) {
        final elapsed = DateTime.now().difference(_startTime!).inSeconds;
        final newRemaining = totalDuration - elapsed;
        if (newRemaining <= 0) {
          t.cancel();
          setState(() {
            remainingSeconds = 0;
            isRunning = false;
          });
          // Stop audio when time is up.
          _audioHandler.stop();
        } else {
          setState(() {
            remainingSeconds = newRemaining;
          });
        }
      }
    });
  }

  void _exitMeditation() async {
    _timer?.cancel();
    await _audioHandler.stop();
    Navigator.pop(context);
  }

  /// Pause the meditation timer and audio.
  void _pauseMeditation() {
    setState(() {
      isPaused = true;
    });
    _timer?.cancel();
    _audioHandler.pause();
  }

  /// Resume the meditation timer and audio.
  void _resumeMeditation() {
    setState(() {
      isPaused = false;
    });
    if (_startTime != null) {
      final pausedElapsed = totalDuration - remainingSeconds;
      _startTime = DateTime.now().subtract(Duration(seconds: pausedElapsed));
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!isPaused && _startTime != null) {
        final elapsed = DateTime.now().difference(_startTime!).inSeconds;
        final newRemaining = totalDuration - elapsed;
        if (newRemaining <= 0) {
          t.cancel();
          setState(() {
            remainingSeconds = 0;
            isRunning = false;
          });
          _audioHandler.stop();
        } else {
          setState(() {
            remainingSeconds = newRemaining;
          });
        }
      }
    });
    _audioHandler.play();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioHandler.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (totalDuration - remainingSeconds) / totalDuration;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Meditation' : 'Thiền'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE0D2),
              Color(0xFFFFF1EC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer circle
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(125),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor:
                            Colors.pinkAccent.shade100.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.pinkAccent.shade100,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(remainingSeconds),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Show music duration if we have a track
                  if (chosenTrackPath.isNotEmpty)
                    Text(
                      '${widget.isEnglish ? "Music Duration" : "Thời lượng nhạc"}: ${_formatTime(chosenTrackDuration)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 30),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (isPaused) {
                            _resumeMeditation();
                          } else {
                            _pauseMeditation();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent.shade100,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                        label: Text(
                          isPaused
                              ? (widget.isEnglish ? 'Resume' : 'Tiếp tục')
                              : (widget.isEnglish ? 'Pause' : 'Tạm dừng'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      if (isPaused)
                        ElevatedButton.icon(
                          onPressed: _exitMeditation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          icon: const Icon(Icons.exit_to_app),
                          label: Text(
                            widget.isEnglish ? 'Exit' : 'Thoát',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
