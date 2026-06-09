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

  /// Recherche des films/séries par titre avec pagination
  ///
  /// [query] : terme de recherche
  /// [page] : numéro de page (OMDb retourne max 10 résultats par page)
  /// Retourne une Future contenant une liste de [Movie]
  Future<List<Movie>> searchMovies({
    required String query,
    int page = 1,
  }) async {
    final String url =
        '${ApiConstants.baseUrl}?apikey=${ApiConstants.apiKey}&s=${Uri.encodeComponent(query)}&page=$page&type=${ApiConstants.defaultType}';

    final response = await http.get(Uri.parse(url)).timeout(
          ApiConstants.apiTimeout,
          onTimeout: () => throw Exception(
            'Timeout lors de la requête API (${ApiConstants.apiTimeout.inSeconds}s)',
          ),
        );

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Vérifier si la réponse est un succès
    if (json['Response'] != 'True') {
      throw Exception(json['Error'] ?? 'Aucun résultat trouvé');
    }

    final List<dynamic> results = json['Search'] as List<dynamic>? ?? [];

    return results
        .map((movie) => Movie.fromJson(movie as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les informations détaillées d'un film par son ID IMDB
  ///
  /// Retourne une Future contenant un [MovieDetails]
  Future<MovieDetails> getMovieDetails(String imdbId) async {
    final String url =
        '${ApiConstants.baseUrl}?apikey=${ApiConstants.apiKey}&i=$imdbId&plot=full';

    final response = await http.get(Uri.parse(url)).timeout(
          ApiConstants.apiTimeout,
          onTimeout: () => throw Exception(
            'Timeout lors de la requête API (${ApiConstants.apiTimeout.inSeconds}s)',
          ),
        );

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['Response'] != 'True') {
      throw Exception(json['Error'] ?? 'Impossible de charger les détails');
    }

    return MovieDetails.fromJson(json);
  }
}
