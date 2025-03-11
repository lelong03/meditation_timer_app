import 'package:flutter/material.dart';
import 'database.dart';
import 'meditation_options_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the database and seed sample data once.
  await AppDatabase.instance.initDB();
  await AppDatabase.instance.seedDataOnce();
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
        fontFamily: 'Montserrat', // Custom font – ensure you've set it up in pubspec.yaml
      ),
      home: const MeditationOptionsScreen(),
    );
  }
}
