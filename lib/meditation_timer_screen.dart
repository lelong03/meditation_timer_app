import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'database.dart';

class MeditationTimerScreen extends StatefulWidget {
  final int durationInMinutes;
  final int? albumId; // May be null if user chooses "Not use"
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
  late int remainingSeconds;
  Timer? timer;
  bool isRunning = false;
  bool isPaused = false;

  // Audio playback
  AudioPlayer audioPlayer = AudioPlayer();
  bool audioStarted = false;
  Timer? musicTimer;
  String chosenTrackPath = "";
  int chosenTrackDuration = 0;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.durationInMinutes * 60;
    // If an album is chosen, load a random track; otherwise, start without music.
    if (widget.albumId != null) {
      _initTrackAndStart();
    } else {
      _startMeditation();
    }
  }

  Future<void> _initTrackAndStart() async {
    final tracks = await AppDatabase.instance.getTracksForAlbum(widget.albumId!);
    if (tracks.isEmpty) {
      _startMeditation();
      return;
    }
    final random = Random();
    final trackIndex = random.nextInt(tracks.length);
    final track = tracks[trackIndex];
    chosenTrackPath = track['filePath'] as String;
    chosenTrackDuration = track['duration'] as int;
    _startMeditation();
  }

  void _startMeditation() {
    setState(() {
      isRunning = true;
      isPaused = false;
    });
    // Schedule audio playback if a track is selected.
    if (chosenTrackPath.isNotEmpty) {
      if (chosenTrackDuration >= remainingSeconds) {
        _startAudio();
      } else {
        final delay = remainingSeconds - chosenTrackDuration;
        musicTimer = Timer(Duration(seconds: delay), () {
          _startAudio();
        });
      }
    }
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isPaused) {
        if (remainingSeconds > 0) {
          setState(() {
            remainingSeconds--;
          });
        } else {
          t.cancel();
          audioPlayer.stop();
          setState(() {
            isRunning = false;
          });
        }
      }
    });
  }

  void _startAudio() async {
    if (!audioStarted && chosenTrackPath.isNotEmpty) {
      audioStarted = true;
      await audioPlayer.play(AssetSource(chosenTrackPath));
    }
  }

  void _pauseMeditation() {
    setState(() {
      isPaused = true;
    });
    timer?.cancel();
    musicTimer?.cancel();
    audioPlayer.pause();
  }

  void _resumeMeditation() {
    setState(() {
      isPaused = false;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isPaused) {
        if (remainingSeconds > 0) {
          setState(() {
            remainingSeconds--;
          });
        } else {
          t.cancel();
          audioPlayer.stop();
          setState(() {
            isRunning = false;
          });
        }
      }
    });
    audioPlayer.resume();
  }

  void _exitMeditation() {
    timer?.cancel();
    musicTimer?.cancel();
    audioPlayer.stop();
    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0;
    if (widget.durationInMinutes > 0) {
      final totalSeconds = widget.durationInMinutes * 60;
      progress = (totalSeconds - remainingSeconds) / totalSeconds;
    }
    return Scaffold(
      // Consistent gradient background.
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
                  // Circular progress indicator with timer text.
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
                            backgroundColor: Colors.pinkAccent.shade100.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent.shade100),
                          ),
                        ),
                        Text(
                          _formatTime(remainingSeconds),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (chosenTrackPath.isNotEmpty)
                    Text(
                      '${widget.isEnglish ? "Music Duration" : "Thời lượng nhạc"}: ${_formatTime(chosenTrackDuration)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 30),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          icon: const Icon(Icons.exit_to_app),
                          label: Text(widget.isEnglish ? 'Exit' : 'Thoát'),
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
