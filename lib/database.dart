import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'meditation.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE albums(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tracks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        albumId INTEGER NOT NULL,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        duration INTEGER NOT NULL,
        FOREIGN KEY(albumId) REFERENCES albums(id)
      )
    ''');
  }

  Future<int> insertAlbum(String name) async {
    final db = await database;
    return db.insert('albums', {'name': name});
  }

  Future<int> insertTrack({
    required int albumId,
    required String title,
    required String filePath,
    required int duration,
  }) async {
    final db = await database;
    return db.insert('tracks', {
      'albumId': albumId,
      'title': title,
      'filePath': filePath,
      'duration': duration,
    });
  }

  Future<List<Map<String, dynamic>>> getAllAlbums() async {
    final db = await database;
    return db.query('albums');
  }

  Future<List<Map<String, dynamic>>> getTracksForAlbum(int albumId) async {
    final db = await database;
    return db.query('tracks', where: 'albumId = ?', whereArgs: [albumId]);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('tracks');
    await db.delete('albums');
  }

  Future<void> seedDataOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final seeded = prefs.getBool('dataSeeded') ?? false;
    if (!seeded) {
      await clearDatabase();
      await createSampleAlbumsAndTracks();
      await prefs.setBool('dataSeeded', true);
    }
  }

  Future<void> dumpTracks() async {
    final db = await database;
    final result = await db.query('tracks');
    print("Tracks in DB: $result");
  }

  Future<void> createSampleAlbumsAndTracks() async {
    // Sample album and track – update paths and durations as needed.
    int albumId1 = await insertAlbum("Tâm Quán Niệm Xứ (Cô Thu)");
    await insertTrack(
      albumId: albumId1,
      title: "Tâm Quán Niệm Xứ #1",
      filePath: "audio/album1/21-02_17m39.mp3",
      duration: 1059
    );
    await insertTrack(
      albumId: albumId1,
      title: "Tâm Quán Niệm Xứ #2",
      filePath: "audio/album1/21-02_18m20.mp3",
      duration: 1100
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #3",
        filePath: "audio/album1/21-02_19m47.mp3",
        duration: 1188
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #4",
        filePath: "audio/album1/22-02_5m12.mp3",
        duration: 312
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #5",
        filePath: "audio/album1/22-02_09m00.mp3",
        duration: 540
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #6",
        filePath: "audio/album1/22-02_11m08.mp3",
        duration: 668
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #7",
        filePath: "audio/album1/22-02_11m57.mp3",
        duration: 717
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #8",
        filePath: "audio/album1/22-02_13m02.mp3",
        duration: 782
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #9",
        filePath: "audio/album1/22-02_16m13.mp3",
        duration: 973
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #10",
        filePath: "audio/album1/22-02_16m57.mp3",
        duration: 1017
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #11",
        filePath: "audio/album1/22-02_17m49.mp3",
        duration: 1069
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #12",
        filePath: "audio/album1/22-02_21m22.mp3",
        duration: 1282
    );
    await insertTrack(
        albumId: albumId1,
        title: "Tâm Quán Niệm Xứ #13",
        filePath: "audio/album1/22-02_26m08.mp3",
        duration: 1568
    );
  }
}
