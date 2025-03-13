import 'package:flutter/material.dart';
import 'database.dart';
import 'meditation_options_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the database and seed data once (using SharedPreferences to check)
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
      ),
      home: const MeditationOptionsScreen(),
    );
  }
}
