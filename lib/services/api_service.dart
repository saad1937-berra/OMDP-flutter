import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_constants.dart';
import '../models/movie.dart';
import '../models/movie_details.dart';

/// Service pour gérer les appels à l'API OMDb
class ApiService {
  static final ApiService _instance = ApiService._internal();

  /// Instance singleton du service
  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  /// Recherche des films/séries par titre
  ///
  /// Retourne une Future contenant une liste de [Movie]
  /// Lève une exception si la requête échoue
  Future<List<Movie>> searchMovies({
    required String query,
    int page = 1,
  }) async {
    try {
      final String url =
          '${ApiConstants.baseUrl}?apikey=${ApiConstants.apiKey}&s=$query&page=$page&type=${ApiConstants.defaultType}';

      final response = await http.get(Uri.parse(url)).timeout(
            ApiConstants.apiTimeout,
            onTimeout: () => throw Exception(
              'Timeout lors de la requête API (${ApiConstants.apiTimeout.inSeconds}s)',
            ),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        // Vérifier si la réponse est un succès
        if (json['Response'] == 'True') {
          final List<dynamic> results = json['Search'] as List<dynamic>;
          final movies = results
              .map((movie) => Movie.fromJson(movie as Map<String, dynamic>))
              .toList();

          return movies;
        } else {
          // Pas de résultats trouvés
          throw Exception(json['Error'] ?? 'Aucun résultat trouvé');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les informations détaillées d'un film par son ID IMDB
  ///
  /// Retourne une Future contenant un [MovieDetails]
  Future<MovieDetails> getMovieDetails(String imdbId) async {
    try {
      final String url =
          '${ApiConstants.baseUrl}?apikey=${ApiConstants.apiKey}&i=$imdbId&plot=full';
      final response = await http.get(Uri.parse(url)).timeout(
            ApiConstants.apiTimeout,
            onTimeout: () => throw Exception(
              'Timeout lors de la requête API (${ApiConstants.apiTimeout.inSeconds}s)',
            ),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['Response'] == 'True') {
          final movieDetails = MovieDetails.fromJson(json);
          return movieDetails;
        } else {
          throw Exception(json['Error'] ?? 'Impossible de charger les détails');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
