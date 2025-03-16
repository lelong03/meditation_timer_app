import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'database.dart';
import 'meditation_options_screen.dart';
import 'background_audio_handler.dart';

// 1) Create a global variable to store the single audio handler.
late final AudioHandler globalAudioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the DB
  await AppDatabase.instance.initDB();
  await AppDatabase.instance.seedDataOnce();
  print("Seeding complete. Now dumping tracks:");
  await AppDatabase.instance.dumpTracks();

  // 2) Initialize the global audio handler exactly once
  globalAudioHandler = await AudioService.init(
    builder: () => MeditationAudioHandler(
      totalDuration: 0,     // placeholder
      audioStartOffset: 0,  // placeholder
      assetPath: "",        // placeholder
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.my_meditation_app.channel.audio',
      androidNotificationChannelName: 'Meditation Audio',
      androidNotificationOngoing: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Meditation App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const MeditationOptionsScreen(),
    );
  }
}
