import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Modèle pour un film favori en base de données
class FavoriteMovie {
  final int? id;
  final String imdbId;
  final String title;
  final String year;
  final String poster;
  final String type;
  final DateTime addedDate;

  FavoriteMovie({
    this.id,
    required this.imdbId,
    required this.title,
    required this.year,
    required this.poster,
    required this.type,
    required this.addedDate,
  });

  /// Convertit en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imdb_id': imdbId,
      'title': title,
      'year': year,
      'poster': poster,
      'type': type,
      'added_date': addedDate.toIso8601String(),
    };
  }

  /// Crée une instance à partir d'une Map
  factory FavoriteMovie.fromMap(Map<String, dynamic> map) {
    return FavoriteMovie(
      id: map['id'],
      imdbId: map['imdb_id'],
      title: map['title'],
      year: map['year'],
      poster: map['poster'],
      type: map['type'],
      addedDate: DateTime.parse(map['added_date']),
    );
  }
}

/// Service de gestion de la base de données SQLite
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  /// Instance singleton
  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Récupère la base de données
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'omdb_favorites.db');

    return openDatabase(path, version: 1, onCreate: _createTables);
  }

  /// Crée les tables
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imdb_id TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        year TEXT NOT NULL,
        poster TEXT,
        type TEXT NOT NULL,
        added_date TEXT NOT NULL
      )
    ''');
  }

  /// Ajoute un film aux favoris
  Future<int> addFavorite(FavoriteMovie movie) async {
    try {
      final db = await database;
      final id = await db.insert(
        'favorites',
        movie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime un film des favoris
  Future<int> removeFavorite(String imdbId) async {
    try {
      final db = await database;
      final count = await db.delete(
        'favorites',
        where: 'imdb_id = ?',
        whereArgs: [imdbId],
      );
      return count;
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère tous les films favoris
  Future<List<FavoriteMovie>> getAllFavorites() async {
    try {
      final db = await database;
      final maps = await db.query('favorites', orderBy: 'added_date DESC');

      if (maps.isEmpty) {
        return [];
      }

      final favorites = maps.map((map) => FavoriteMovie.fromMap(map)).toList();
      return favorites;
    } catch (e) {
      rethrow;
    }
  }

  /// Vérifie si un film est dans les favoris
  Future<bool> isFavorite(String imdbId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'favorites',
        where: 'imdb_id = ?',
        whereArgs: [imdbId],
      );
      return maps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Récupère un film favori par son ID IMDB
  Future<FavoriteMovie?> getFavoriteById(String imdbId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'favorites',
        where: 'imdb_id = ?',
        whereArgs: [imdbId],
      );

      if (maps.isEmpty) return null;
      return FavoriteMovie.fromMap(maps.first);
    } catch (e) {
      return null;
    }
  }
}
