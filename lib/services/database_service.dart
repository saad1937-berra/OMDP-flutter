import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Modèle pour un film favori
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

/// Modèle pour un avis personnel sur un film
class MovieReview {
  final int? id;
  final String imdbId;
  final double personalRating;
  final String personalReview;
  final DateTime reviewDate;

  MovieReview({
    this.id,
    required this.imdbId,
    required this.personalRating,
    required this.personalReview,
    required this.reviewDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imdb_id': imdbId,
      'personal_rating': personalRating,
      'personal_review': personalReview,
      'review_date': reviewDate.toIso8601String(),
    };
  }

  factory MovieReview.fromMap(Map<String, dynamic> map) {
    return MovieReview(
      id: map['id'],
      imdbId: map['imdb_id'],
      personalRating: map['personal_rating'],
      personalReview: map['personal_review'],
      reviewDate: DateTime.parse(map['review_date']),
    );
  }
}

/// Modèle pour une collection personnalisée
class MovieCollection {
  final int? id;
  final String name;
  final String description;
  final DateTime createdDate;
  final List<String> imdbIds;

  MovieCollection({
    this.id,
    required this.name,
    required this.description,
    required this.createdDate,
    required this.imdbIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_date': createdDate.toIso8601String(),
      'imdb_ids': imdbIds.join(','),
    };
  }

  factory MovieCollection.fromMap(Map<String, dynamic> map) {
    return MovieCollection(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdDate: DateTime.parse(map['created_date']),
      imdbIds: (map['imdb_ids'] as String)
          .split(',')
          .where((id) => id.isNotEmpty)
          .toList(),
    );
  }
}

/// Service de gestion de la base de données SQLite
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'omdb_app.db');

    return openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    /// Table des favoris
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imdb_id TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        year TEXT NOT NULL,
        poster TEXT,
        type TEXT NOT NULL,
        added_date TEXT NOT NULL
      )
    ''');

    /// Table des avis personnels
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imdb_id TEXT UNIQUE NOT NULL,
        personal_rating REAL NOT NULL,
        personal_review TEXT,
        review_date TEXT NOT NULL
      )
    ''');

    /// Table des collections
    await db.execute('''
      CREATE TABLE IF NOT EXISTS collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_date TEXT NOT NULL,
        imdb_ids TEXT NOT NULL
      )
    ''');
  }

  /// ========== FAVORIS ==========
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

  Future<List<FavoriteMovie>> getAllFavorites() async {
    try {
      final db = await database;
      final maps = await db.query('favorites', orderBy: 'added_date DESC');

      if (maps.isEmpty) {
        return [];
      }

      return maps.map((map) => FavoriteMovie.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

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

  /// ========== AVIS PERSONNELS ==========
  Future<int> addOrUpdateReview(MovieReview review) async {
    try {
      final db = await database;
      final id = await db.insert(
        'reviews',
        review.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      rethrow;
    }
  }

  Future<MovieReview?> getReview(String imdbId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'reviews',
        where: 'imdb_id = ?',
        whereArgs: [imdbId],
      );

      if (maps.isEmpty) return null;
      return MovieReview.fromMap(maps.first);
    } catch (e) {
      return null;
    }
  }

  Future<int> removeReview(String imdbId) async {
    try {
      final db = await database;
      return await db.delete(
        'reviews',
        where: 'imdb_id = ?',
        whereArgs: [imdbId],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ========== COLLECTIONS ==========
  Future<int> addCollection(MovieCollection collection) async {
    try {
      final db = await database;
      final id = await db.insert(
        'collections',
        collection.toMap(),
      );
      return id;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MovieCollection>> getAllCollections() async {
    try {
      final db = await database;
      final maps = await db.query('collections', orderBy: 'created_date DESC');

      if (maps.isEmpty) {
        return [];
      }

      return maps.map((map) => MovieCollection.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> removeCollection(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'collections',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updateCollection(MovieCollection collection) async {
    try {
      final db = await database;
      return await db.update(
        'collections',
        collection.toMap(),
        where: 'id = ?',
        whereArgs: [collection.id],
      );
    } catch (e) {
      rethrow;
    }
  }
}
