import 'package:flutter/material.dart';
import 'database.dart';
import 'meditation_timer_screen.dart';

class MeditationOptionsScreen extends StatefulWidget {
  const MeditationOptionsScreen({Key? key}) : super(key: key);

  @override
  State<MeditationOptionsScreen> createState() => _MeditationOptionsScreenState();
}

class _MeditationOptionsScreenState extends State<MeditationOptionsScreen> {
  final List<int> durations = [1, 15, 30, 45, 60];
  int selectedDuration = 60;

  // Albums loaded from the database.
  List<Map<String, dynamic>> albums = [];
  int? selectedAlbumId; // Null => "Not use", but we won't set this by default.

  bool isEnglish = false;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final dbAlbums = await AppDatabase.instance.getAllAlbums();
    setState(() {
      albums = dbAlbums;
      // If we have at least one album, select the first album by default
      // (so "Not use" is NOT selected by default).
      if (albums.isNotEmpty) {
        selectedAlbumId = albums.first['id'] as int;
      } else {
        // If no albums, user can only choose "Not use" later.
        selectedAlbumId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Same gradient background as the timer screen
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
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: _buildCard(context),
                ),
              ),
              // Language toggle button (top right)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(Icons.language, color: Colors.red.shade700),
                  onPressed: () {
                    setState(() {
                      isEnglish = !isEnglish;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/teacher.jpg'),
          ),
          const SizedBox(height: 16),
          Text(
            isEnglish ? 'Insight Meditation Options' : 'Tùy Chọn Thiền Minh Sát',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Meditation duration label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isEnglish ? 'Meditation Duration:' : 'Thời lượng thiền:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, // BOLD TEXT
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Meditation duration dropdown
          DropdownButton<int>(
            value: selectedDuration,
            isExpanded: true,
            items: durations.map((min) {
              return DropdownMenuItem<int>(
                value: min,
                child: Text('$min ${isEnglish ? "minutes" : "phút"}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedDuration = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          // Album selection label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isEnglish ? 'Choose an Album:' : 'Chọn Album:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, // BOLD TEXT
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Album selection dropdown
          if (albums.isNotEmpty)
            DropdownButton<int?>(
              value: selectedAlbumId,
              isExpanded: true,
              items: [
                // Put the real albums first
                ...albums.map((album) {
                  return DropdownMenuItem<int?>(
                    value: album['id'] as int,
                    child: Text(album['name'] as String),
                  );
                }).toList(),
                // Then the "Not use" option at the end
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(isEnglish ? 'Not use' : 'Không sử dụng'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAlbumId = value;
                });
              },
            )
          else
            Text(
              isEnglish
                  ? 'No albums found. Please insert data into DB.'
                  : 'Không tìm thấy album. Hãy thêm dữ liệu vào DB.',
              style: const TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 24),
          // Start button with icon
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: () {
              // Navigate to the timer screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MeditationTimerScreen(
                    durationInMinutes: selectedDuration,
                    albumId: selectedAlbumId, // Null => no music
                    isEnglish: isEnglish,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(isEnglish ? 'Start' : 'Bắt đầu'),
          ),
        ],
      ),
    );
  }
}
